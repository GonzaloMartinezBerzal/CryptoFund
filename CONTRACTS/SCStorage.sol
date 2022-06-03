// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.8.0;

import "./Interfaces/IProxy.sol";
import "./libraries/OracleLibrary.sol";

contract SCStorage is ISCStorage
{
	address immutable deployer;
	
	uint public NAV;
    uint8 public initDone;
    uint8 public nStable;
	
    address public proxy;

	address[] public coinArray;
	mapping (address => uint) public coins; //Coin = 1, StableCoin = 2
	mapping (address => address) public coinOracleAddr; //UniswapV3PoolAddress
    mapping (address => address) public quoteIn; //Address token en el que medimos el precio de la moneda no estable
	
    
    constructor()
    {
        deployer = msg.sender;
    }
    
	modifier OnlyDeployer()
    {
        require(msg.sender == deployer, "Sender is not Deployer");
        _;
    }

    modifier NonInit()
    {
        require(initDone == 0, "Contract non-init");
        _;
    }

    function initContract(address proxyAddr) external OnlyDeployer NonInit
    {
        proxy = proxyAddr;
        initDone = 1;
    }

    function updateNAV(uint comission) external virtual override returns (uint newNAV)
    {
        require(msg.sender == IProxy(proxy).exchangeContract(), "Sender is not SCExchange");
        newNAV = calculateNAV() - comission;
        NAV = newNAV;
    }
    
    function transferFunds(address to, uint totalToTransfer) external virtual override returns (bool)
    {
        address proxyAddr = proxy;
        require(msg.sender == IProxy(proxyAddr).exchangeContract() || msg.sender == IProxy(proxyAddr).commissionContract(), "Sender is not SCExchange or SCCommission");
        uint n = coinArray.length;
        
        for(uint i = 0; i < n; i++)
        {
            address coinAddr = coinArray[i];
            if(coins[coinAddr] == 2)
            {
                uint8 decimals = IERC20(coinAddr).decimals();
                if(decimals < 18) IERC20(coinAddr).transfer(to, totalToTransfer/nStable/10**(18-uint(decimals)));
                else if(decimals == 18) IERC20(coinAddr).transfer(to, totalToTransfer/nStable);
            }
        }
        return true;
    }
    
    function oracleNAV() external view returns (uint, uint)
    {
        //Sin optimizaciones de gas. Pensada para leer desde fuera solamente
        //Sin comision calculada, solo acumulado. La comision debe calcularse off-chain con la formula y el timestamp de la ultima vez que se actualizo
        uint lastUpdated = ISCCommission(IProxy(proxy).commissionContract()).lastUpdated();
        uint acum = ISCCommission(IProxy(proxy).commissionContract()).accumCommission();
        return (calculateNAV() - acum, lastUpdated);
    }
    
    function calculateNAV() internal view returns (uint newNAV)
    {
        //Calcula el NAV en USD. No tiene en cuenta la comision que falte por cobrar relativa al tiempo ni la comision acumulada.
        uint n = coinArray.length;
        for(uint i = 0; i < n; i++)
        {
            address coin = coinArray[i];
            uint balance = IERC20(coin).balanceOf(address(this));
            uint decimals = uint(IERC20(coin).decimals());
            uint stable = coins[coin];
            
            if(stable == 1)
            {
                uint quote;
                unchecked{
                    (int24 arithmeticMeanTick,) = OracleLibrary.consult(coinOracleAddr[coin], 1);
                    quote = OracleLibrary.getQuoteAtTick(arithmeticMeanTick, uint128(balance), coin, quoteIn[coin]);
                    uint quotedInDecimals = uint(IERC20(quoteIn[coin]).decimals());
                    if(quotedInDecimals < 18) quote*10**(18-quotedInDecimals);
                }
                newNAV += quote;
            }
            else if(stable == 2)
            {
                if (decimals < 18) newNAV += balance*10**(18-decimals);
                else newNAV += balance;
            }
        }
    }
    
    function addCoin(address coinAddr, bool stable) external OnlyDeployer
    {
        if(!stable)coins[coinAddr] = 1;
        else
        {
            coins[coinAddr] = 2;
            nStable++;
        }
        coinArray.push(coinAddr);
        IERC20(coinAddr).approve(IProxy(proxy).opsContract(), type(uint256).max);
    }
    
    function delCoin(address coinAddr) external
    {
        require(msg.sender == deployer || msg.sender == IProxy(proxy).exchangeContract(), "Sender is not Deployer or SCExchange");
        if(coins[coinAddr] == 2) nStable--;
        coins[coinAddr] = 0;
        uint n = coinArray.length;
        for(uint i = 0; i < n; i++)
        {
            if(coinArray[i] == coinAddr)
            {
                coinArray[i] = coinArray[n-1];
                coinArray.pop();
                break;
            }
        }
        IERC20(coinAddr).approve(IProxy(proxy).opsContract(), 0);
    }

    function setOracle(address coin, address v3Pool, address quotedIn) external OnlyDeployer
    {
        coinOracleAddr[coin] = v3Pool;
        quoteIn[coin] = quotedIn;
    }

    function updateProxy(address newAddr) external virtual override
    {
        require(msg.sender == proxy, "Sender is not Proxy");
        proxy = newAddr;
    }
    
    function deleteContract(address newAddr) external virtual override OnlyDeployer
    {
        address proxyAddr = proxy;
        IProxy(proxyAddr).setStorageAddr(newAddr);
        //newAddr.delegatecall(abi.encodeWithSignature("initContract(address)", proxyAddr));
        uint n = coinArray.length;
        for(uint i = 0; i < n; i++)
        {
            address tokenToTransfer = coinArray[i];
            IERC20(tokenToTransfer).transfer(newAddr, IERC20(tokenToTransfer).balanceOf(address(this)));
        }
        selfdestruct(payable(deployer));
    }
    
    receive() external payable
    {
        revert();
    }
    
    fallback() external payable
    {
        revert();
    }
}