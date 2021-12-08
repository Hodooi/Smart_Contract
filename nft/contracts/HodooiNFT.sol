pragma solidity >=0.5.0;

import "./token/ERC1155Tradeble.sol";

/*
 * @title 1155 General
 * 1155General - Collect normal NFTs from user
 */
contract HodooiNFT is ERC1155Tradeble {
    constructor()
        public
        ERC1155Tradeble("HODOOI NFT General", "HODOOI")
    {
        _setBaseMetadataURI("https://nft.hodooi.com/");
    }
}
