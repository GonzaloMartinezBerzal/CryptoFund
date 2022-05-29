// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.8.0;

interface ISCCommission
{
    function lastUpdated() external view returns(uint);

    function accumCommission() external view returns(uint);

    function initContract(address proxyAddr, uint lastUpdated_, uint accumCommission_, uint feeYear_, uint r_) external;

    function payComissions(uint buyOrSell) external returns (uint payedComissions);

    function collectCommission(address[] calldata tokensToTransfer, uint[] calldata qty) external;

    function updateProxy(address newAddr) external;

    function deleteContract(address newAddr, address[] calldata tokensToTransfer, uint[] calldata qty) external;
}