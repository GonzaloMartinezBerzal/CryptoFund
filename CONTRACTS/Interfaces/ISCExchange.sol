// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.8.0;

interface ISCExchange
{
    function buyTokensOutput(address stableAddr, uint tokensOut) external;

    function buyTokensInput(address stableAddr, uint qtyIn) external;

    function sellTokens(uint qty) external;

    function deleteContract(address newAddr) external;

    function addToBlacklist(address to) external returns (bool);

    function removeFromBlacklist(address to) external returns (bool);

    function updateProxy(address newAddr) external;
}