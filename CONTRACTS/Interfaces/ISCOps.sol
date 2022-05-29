// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.8.0;

interface ISCOps
{
    function initContract(address proxyAddr) external;

    function uniSwap(address[] calldata path, uint amount) external;

    function updateProxy(address newAddr) external;

    function deleteContract(address newContract) external;
}