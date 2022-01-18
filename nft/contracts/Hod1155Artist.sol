pragma solidity >=0.7.0;

import "./token/ERC1155Tradeble.sol";

/*
 * @title 1155 General
 * 1155General - Collect normal NFTs from user
 */
contract Hodooi1155NFT is ERC1155Tradeble {
    constructor(string memory name, string memory symbol)
        public
        ERC1155Tradeble(name, symbol)
    {
        _setBaseMetadataURI("https://nft.hodooi.com/");
    }
}
