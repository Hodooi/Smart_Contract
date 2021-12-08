// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

interface IMarket {
    function items(uint256 _itemId)
    external
    view
    returns (
        address,
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );

    function lastSalePrice(address _tokenAddress, uint256 _tokenId)
    external
    view
    returns (uint256);

    function adminCancelList(uint256 orderid, address receiver) external;

    function transferOwnership(address _newOwner) external;
}