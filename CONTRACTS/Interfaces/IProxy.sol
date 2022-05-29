// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.8.0;

import "./ISCStorage.sol";
import "./ISCCommission.sol";
import "./ISCOps.sol";
import "./ISCExchange.sol";
import "./IERC20.sol";

interface IProxy
{
	function initAddrs(address exchangeAddr, address storageAddr, address commissionAddr, address opsAddr, address tokenAddr) external;
	
	function multicall(bytes[] calldata data, address[] calldata contractAddr) external returns (bytes[] memory results);

	function exchangeContract() external view returns (address);
	function setExchangeAddr(address exchangeAddr) external;

	function storageContract() external view returns (address);
	function setStorageAddr(address storageAddr) external;

	function commissionContract() external view returns (address);
	function setCommissionAddr(address commissionAddr) external;

	function opsContract() external view returns (address);
	function setOpsAddr(address opsAddr) external;

	function token() external view returns (address);
	function setTokenAddr(address tokenAddr) external;

	function deleteContract(address newAddr) external;
}