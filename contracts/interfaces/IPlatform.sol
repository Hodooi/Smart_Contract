pragma solidity ^0.7.0;

interface IPlatform {
    function adminMigrateData(uint256 _itemId, address _owner, address _tokenAddress, address _paymentToken,
        uint256 _tokenId, uint256 _quantity, uint256 _expired, uint256 _status, uint256 _minBid,
        uint256 _price, uint256 _mask, uint256 _lastSalePrice)external onlyOwnerOrAdmin;
}
