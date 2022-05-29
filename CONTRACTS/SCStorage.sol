// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.8.0;

import "./Interfaces/IProxy.sol";
import "./libraries/OracleLibrary.sol";

contract SCStorage is ISCStorage
{
	address immutable deployer;
	
	uint public NAV;
    uint8 public initDone;
    uint8 nStable;
	
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
        require(msg.sender == deployer);
        _;
    }

    modifier NonInit()
    {
        require(initDone == 0);
        _;
    }

    function initContract(address proxyAddr) external OnlyDeployer NonInit
    {
        proxy = proxyAddr;
        initDone = 1;
    }

    function updateNAV(uint comission) external virtual override returns (uint newNAV)
    {
        require(msg.sender == IProxy(proxy).exchangeContract());
        newNAV = calculateNAV() - comission;
        NAV = newNAV;
    }
    
    function transferFunds(address to, uint totalToTransfer) external virtual override returns (bool)
    {
        address proxyAddr = proxy;
        require(msg.sender == IProxy(proxyAddr).exchangeContract() || msg.sender == IProxy(proxyAddr).commissionContract());
        uint n = coinArray.length;
        
        for(uint i = 0; i < n; i++)
        {
            address coinAddr = coinArray[i];
            if(coins[coinAddr] == 2)
            {
                uint8 decimals = IERC20(coinAddr).decimals();
                if(decimals < 18) IERC20(coinAddr).transfer(to, totalToTransfer/nStable/10**(uint(decimals)-18));
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
            uint stable = coins[coin];
            
            if(stable == 1)
            {
                uint quote;
                unchecked{
                    (int24 arithmeticMeanTick,) = OracleLibrary.consult(coinOracleAddr[coin], 0);
                    quote = OracleLibrary.getQuoteAtTick(arithmeticMeanTick, uint128(balance), coin, quoteIn[coin]);
                }
                newNAV += balance * quote;
            }
            else if(stable == 2) newNAV += balance;
        }
    }
    
    function addCoin(address coinAddr, uint stable) external  OnlyDeployer
    {
        if(stable == 0) coins[coinAddr] = 1;
        else if(stable == 1)
        {
            coins[coinAddr] = 2;
            nStable++;
        }
        coinArray.push(coinAddr);
    }
    
    function delCoin(address coinAddr) external
    {
        require(msg.sender == deployer || msg.sender == IProxy(proxy).exchangeContract());
        if(coins[coinAddr] == 2) nStable--;
        coins[coinAddr] = 0;
        uint n = coinArray.length;
        for(uint i = 0; i < n; i++)
        {
            if(coinArray[i] == coinAddr)
            {
                coinArray[i] = coinArray[n-1];
                coinArray.pop();
            }
        }
    }

    function updateProxy(address newAddr) external virtual override
    {
        require(msg.sender == proxy);
        proxy = newAddr;
    }
    
    function deleteContract(address newAddr) external virtual override OnlyDeployer
    {
        address proxyAddr = proxy;
        IProxy(proxyAddr).setStorageAddr(newAddr);
        newAddr.delegatecall(abi.encodeWithSignature("initContract(address)", proxyAddr));
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