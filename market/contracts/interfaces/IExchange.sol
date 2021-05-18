// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

interface IExchange {
    function estimateToUSDT(
        address _paymentToken,
        uint256 _paymentAmount)
    external view returns (uint256);

    function estimateFromUSDT(
        address _paymentToken,
        uint256 _usdtAmount)
    external view returns (uint256);
}
