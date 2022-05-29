// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.8.0;

import "./Interfaces/IProxy.sol";

contract SCExchange is ISCExchange
{
	address immutable deployer;
    address public proxy;

	mapping(address => uint) public coins;
	mapping(address => uint) public blacklist;
	uint8 public lock;
    uint8 public initDone;
    
    constructor()
    {
        deployer = msg.sender;
        lock = 1;
    }
    
	modifier OnlyDeployer()
    {
        require(msg.sender == deployer);
        _;
    }

    modifier Blacklisted()
    {
    	require(blacklist[msg.sender] != 1);
    	_;
    }

    modifier Coin(address stableAddr)
    {
    	require(coins[stableAddr] == 1);
    	_;
    }
    
    modifier Locked()
    {
        require(lock == 0);
        _;
    }

    modifier NonInit()
    {
        require(initDone == 0);
        _;
    }
    
    function initContract(address proxyAddr) external OnlyDeployer NonInit
    {
        lock = 0;
        proxy = proxyAddr;
        initDone = 1;
    }

    function lockOn() external OnlyDeployer
    {
        lock = 1;
    }
    
    function lockOff() external OnlyDeployer
    {
        lock = 0;
    }

    function buyTokensOutput(address stableAddr, uint tokensOut) external virtual override Blacklisted Locked Coin(stableAddr)
    {
        address proxyAddr = proxy;
        address storageAddr = IProxy(proxyAddr).storageContract();
        
        uint NAVvalue = ISCStorage(storageAddr).updateNAV(ISCCommission(IProxy(proxyAddr).commissionContract()).payComissions(0)); //0 si es buy
    	
        uint payment;
        uint tokenDecimals = IERC20(stableAddr).decimals();
        uint tokenSupply = IERC20(IProxy(proxyAddr).token()).totalSupply();
    	
        if(tokenDecimals < 18) //Decimales del NAV
    	{
            if(tokenSupply == 0 && NAVvalue == 0)
            {
                payment = tokensOut * tokenDecimals;
            }
    	    else payment = tokensOut * (NAVvalue / tokenSupply) / 10**(18 - tokenDecimals);
    	}
    	else
        {
            if(tokenSupply == 0 || NAVvalue == 0) payment = tokensOut * 1e18;
            else payment = tokensOut * (NAVvalue / tokenSupply);
        }
        require(IERC20(stableAddr).transferFrom(msg.sender, storageAddr, payment));
        require(IERC20(IProxy(proxyAddr).token()).mint(msg.sender, tokensOut));
    }
    
    function buyTokensInput(address stableAddr, uint qtyIn) external virtual override Blacklisted Locked Coin(stableAddr)
    {
        require(qtyIn > 0);
        address proxyAddr = proxy;
        address storageAddr = IProxy(proxyAddr).storageContract();

        uint NAVvalue = ISCStorage(storageAddr).updateNAV(ISCCommission(IProxy(proxyAddr).commissionContract()).payComissions(0)); //0 si es buy
        
        uint payment;
        uint tokenDecimals = IERC20(stableAddr).decimals();
        uint tokenSupply = IERC20(IProxy(proxyAddr).token()).totalSupply();
        uint tokensOut;

    	if(tokenDecimals < 18) //Decimales del NAV
    	{
    	    uint qtyWithDec = qtyIn * 10**(18 - tokenDecimals);
            if(NAVvalue == 0 && tokenSupply == 0)
            {
                tokensOut = qtyWithDec / 1e18;
                payment = tokensOut * 10**tokenDecimals;
            }
            
    	    else 
            {
                tokensOut = qtyWithDec / (NAVvalue / tokenSupply);
                payment = (tokensOut * NAVvalue / tokenSupply) / 10**(18 - tokenDecimals) + 1;
            }
        }

    	else
        {
            if(NAVvalue == 0 || tokenSupply == 0)
            {
                tokensOut = qtyIn / 1e18;
                payment = tokensOut * 1e18;
            }
            else
            {
                tokensOut = qtyIn / (NAVvalue / tokenSupply);
                payment = tokensOut * (NAVvalue/tokenSupply);
            }
        }
    	require(IERC20(stableAddr).transferFrom(msg.sender, storageAddr, payment));
    	require(IERC20(IProxy(proxyAddr).token()).mint(msg.sender, tokensOut));
    }

	function sellTokens(uint qty) external virtual override Blacklisted Locked
    {
        address proxyAddr = proxy;
        address storageAddr = IProxy(proxyAddr).storageContract();
        address tokenAddr = IProxy(proxyAddr).token();
        
        require(IERC20(tokenAddr).burnFrom(msg.sender, qty));
    	
        uint NAVvalue = ISCStorage(storageAddr).updateNAV(ISCCommission(IProxy(proxyAddr).commissionContract()).payComissions(1)); //1 si es sell

        uint supply = IERC20(tokenAddr).totalSupply();
        uint totalToTransfer = qty * (NAVvalue / supply);

        require(ISCStorage(storageAddr).transferFunds(msg.sender, totalToTransfer));
    }

    function addCoin(address coinAddr) external  OnlyDeployer
    {
        coins[coinAddr] = 1;
    }
    
    function delCoin(address coinAddr) external OnlyDeployer
    {
        coins[coinAddr] = 0;
    }

	function addToBlacklist(address to) external virtual override OnlyDeployer returns (bool)
    {
        blacklist[to] = 1;
        return true;
    }

    function removeFromBlacklist(address to) external virtual override OnlyDeployer returns (bool)
    {
        blacklist[to] = 0;
        return true;
    }
    
    function updateProxy(address newAddr) external virtual override OnlyDeployer
    {
        require(msg.sender == proxy);
        proxy = newAddr;
    }
    
    function deleteContract(address newAddr) external virtual override OnlyDeployer
    {
        address proxyAddr = proxy;
        IProxy(proxyAddr).setExchangeAddr(newAddr);
        newAddr.delegatecall(abi.encodeWithSignature("initContract(address)", proxyAddr));
        address(IProxy(proxyAddr).token()).delegatecall(abi.encodeWithSignature("setOwner(address)", newAddr));
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