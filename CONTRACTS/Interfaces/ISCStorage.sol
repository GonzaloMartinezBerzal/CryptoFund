// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.8.0;

interface ISCStorage
{
    function updateNAV(uint comission) external returns (uint newNAV);

    function NAV() external view returns (uint);

    function transferFunds(address to, uint totalToTransfer) external returns (bool);

    function addCoin(address coinAddr, uint stable) external;

    function delCoin(address coinAddr) external;

    function updateProxy(address newAddr) external;

    function deleteContract(address newAddr) external;
}