// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.8.0;

import "./Interfaces/IProxy.sol";

contract SCCommission is ISCCommission
{
	address immutable deployer;
	
	address public proxy;
	
	uint public lastUpdated;
	uint public accumCommission;
	uint public feeYear; //En tanto por uno al aÃ±o, con 18 decimales -> 5% = 5e16
    uint public r; //feeYear calculado para el periodo de tiempo de 1 dia con 18 decimales
    //dt = (block.timestamp - lastUpdated);
    //comission NAV*(1e18 - (1e18 - dt*r))/1e18 - NAV*(dt*(dt-1)*r*r/2)/1e36 + NAV*(dt*(dt-1)*(dt-2)*r*r*r/6)/1e54 - NAV*(dt*(dt-1)*(dt-2)*(dt-3)*r*r*r*r/24)/1e72
    uint public initDone;
    
    constructor()
    {
        deployer = msg.sender;
        initDone = 0;
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

    function initContract(address proxyAddr, uint lastUpdated_, uint accumCommission_, uint feeYear_, uint r_) external virtual override OnlyDeployer NonInit
    {
        proxy = proxyAddr;
        lastUpdated = lastUpdated_;
        accumCommission = accumCommission_;
        feeYear = feeYear_;
        r = r_;
        initDone = 1;
    }

    function setR(uint newR) external OnlyDeployer
    {
        r = newR;
    }

    function setFeeYear(uint newFee) external OnlyDeployer
    {
        feeYear = newFee;
    }

    function computeCommission() internal view returns (uint commission)
    {
        //block.timestamp cuesta 2 gas
        address storageAddr;
        uint time = lastUpdated;

        if(time == block.timestamp) commission = 0;
        else
        {
            uint dt = block.timestamp - time;
            uint rFee = r;
            storageAddr = IProxy(proxy).storageContract();
            
            uint NAVvalue = ISCStorage(storageAddr).NAV();
            
            commission = NAVvalue*(1e18 - (1e18 - dt*rFee))/1e18 - NAVvalue*(dt*(dt-1)*rFee*rFee/2)/1e36 + NAVvalue*(dt*(dt-1)*(dt-2)*rFee*rFee/1e18*rFee/6)/1e36 - NAVvalue*dt*(dt-1)*(dt-2)*(dt-3)*rFee/1e18*rFee/1e18*rFee/1e18*rFee/1e18/24;
        }
    }

    function payComissions(uint buyOrSell) external virtual override returns (uint payedComissions)
    {
        address proxyAddr = proxy;
        require(IProxy(proxyAddr).exchangeContract() == msg.sender);
        uint commission = computeCommission();
        if(buyOrSell == 0)
        {
            payedComissions = accumCommission + commission;
            accumCommission = payedComissions;
        }
        else if(buyOrSell == 1)
        {
            payedComissions = commission + accumCommission;
            ISCStorage(IProxy(proxyAddr).commissionContract()).transferFunds(address(this), payedComissions);
            accumCommission = 0;
        }
        lastUpdated = block.timestamp;
    }

    function collectCommission(address[] calldata tokensToTransfer, uint[] calldata qty) external virtual override OnlyDeployer
    {
        address to = deployer;
        for(uint i = 0; i < qty.length; i++) IERC20(tokensToTransfer[i]).transfer(to, qty[i]);
    }

    function updateProxy(address newAddr) external virtual override
    {
        require(msg.sender == proxy);
        proxy = newAddr;
    }
    
    function deleteContract(address newAddr, address[] calldata tokensToTransfer, uint[] calldata qty) external virtual override OnlyDeployer
    {
        address proxyAddr = proxy;
        IProxy(proxyAddr).setCommissionAddr(newAddr);
        newAddr.delegatecall(abi.encodeWithSignature("initContract(address,uint,uint,uint,uint)", proxyAddr, lastUpdated, accumCommission, feeYear, r));
        proxyAddr = address(0);
        lastUpdated = 0;
        accumCommission = 0;
        feeYear = 0;
        r = 0;
        address(this).delegatecall(abi.encodeWithSignature("collectCommission(address[],uint[])", tokensToTransfer, qty));
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