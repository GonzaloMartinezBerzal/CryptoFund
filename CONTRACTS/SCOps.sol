// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.8.0;

import "./Interfaces/IProxy.sol";

//v2 Imports
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./libraries/UniswapV2Library.sol";

contract SCOps is ISCOps
{
	address immutable deployer;
	address public proxy;
    uint8 public initDone;

    address public v2factory;
    
    constructor()
    {
        deployer = msg.sender;
    }
    
	modifier OnlyDeployer()
    {
        require(msg.sender == deployer, "Sender not Deployer");
        _;
    }

    modifier NonInit()
    {
        require(initDone == 0, "Contract non-initiated");
        _;
    }

    function initContract(address proxyAddr) external virtual override OnlyDeployer NonInit
    {
        initDone = 1;
        proxy = proxyAddr;
    }

    function setFactory(address factory) external OnlyDeployer
    {
        v2factory = factory;
    }

    function uniSwap(address[] calldata path, uint amount) external virtual override OnlyDeployer
    {
        address factory = v2factory;
        address proxyAddr = proxy;
        uint qtyIn = amount;
        for(uint i = 0; i < path.length-1; i++)
        {
            address inputPair = UniswapV2Library.pairFor(factory, path[i], path[i+1]);
            (uint aReserves, uint bReserves) = UniswapV2Library.getReserves(factory, path[i], path[i+1]);

            uint amount0Out;
            uint amount1Out;

            if (path[i] == IUniswapV2Pair(inputPair).token0())
            {
                amount0Out = 0;
                amount1Out = UniswapV2Library.getAmountOut(qtyIn, aReserves, bReserves);
                IERC20(path[i]).transferFrom(IProxy(proxyAddr).storageContract(), inputPair, qtyIn);
                qtyIn = amount1Out;
            }
            else
            {
                amount0Out = UniswapV2Library.getAmountOut(qtyIn, aReserves, bReserves);
                amount1Out = 0;
                IERC20(path[i]).transferFrom(IProxy(proxyAddr).storageContract(), inputPair, qtyIn);
                qtyIn = amount0Out;
            }
            IUniswapV2Pair(inputPair).swap(amount0Out, amount1Out, IProxy(proxy).storageContract(), "");
        }
    }
    
    function updateProxy(address newAddr) external virtual override OnlyDeployer
    {
        require(msg.sender == proxy, "Sender not Proxy");
        proxy = newAddr;
    }
    
    function deleteContract(address newContract) external virtual override OnlyDeployer
    {
        address proxyAddr = proxy;
        IProxy(proxyAddr).setOpsAddr(newContract);
        //newContract.delegatecall(abi.encodeWithSignature("initContract(address)", proxyAddr));
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