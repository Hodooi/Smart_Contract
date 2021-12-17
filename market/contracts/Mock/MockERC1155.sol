//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.7/contracts/token/ERC1155/ERC1155.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    
    uint256 public _currentTokenID = 0;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public loyaltyFee;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    mapping(uint256 => string)  public tokenURI;

    event Create(
        address indexed _creator,
        uint256 indexed _id,
        uint256 indexed _loyaltyFee,
        uint256 _maxSupply,
        uint256 _initSupply
    );

    constructor() ERC1155("https://example.json") {
    }

    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        uint256 _loyaltyFee,
        string memory _uri,
        bytes memory _data
    ) public returns (uint256 tokenId) {
        require(
            _initialSupply <= _maxSupply,
            "Initial supply cannot be more than max supply"
        );
        require(0 <= _loyaltyFee && _loyaltyFee <= 10000, "Invalid-loyalty-fee");
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;
        loyaltyFee[_id] = _loyaltyFee;
        tokenURI[_id] = _uri;

        if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        emit Create(msg.sender, _id, _loyaltyFee, _maxSupply, _initialSupply);
        return _id;
    }

    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID + 1;
    }

    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }

	function getCreator(uint256 _id) public view returns (address) {
		return creators[_id];
	}

	function getLoyaltyFee(uint256 _id) public view returns (uint256) {
		return loyaltyFee[_id];
	}
    
}