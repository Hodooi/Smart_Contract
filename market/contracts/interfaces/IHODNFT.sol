// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

interface IHODNFT {
    function getCreator(uint256 _id) external view returns (address);

	function getLoyaltyFee(uint256 _id) external view returns (uint256);
}