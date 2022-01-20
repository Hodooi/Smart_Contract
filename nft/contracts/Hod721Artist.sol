//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract Hod721Artist is ERC721, Ownable {
	using SafeMath for uint256;

	uint256 public _currentTokenId = 0;
	mapping(uint256 => address) public creators;
	mapping(uint256 => uint256) public loyaltyFee;

	constructor(string memory name, string memory symbol) public ERC721(name, symbol) {
		_setBaseURI('https://api-test.hodooi.com');
	}

	/*
	 * @dev Create new NFT
	 * @param _tokenURI _tokenURI of tokenID
	 */

	function create(string calldata _tokenURI, uint256 _loyaltyFee) external {
		uint256 newTokenId = _getNextTokenId();
		_mint(msg.sender, newTokenId);
		creators[newTokenId] = msg.sender;
		loyaltyFee[newTokenId] = _loyaltyFee;
		_setTokenURI(newTokenId, _tokenURI);
		_incrementTokenId();
	}

	/*
	 * @dev calculates the next token ID based on value of _currentTokenId
	 * @return uint256 for the next token ID
	 */
	function _getNextTokenId() private view returns (uint256) {
		return _currentTokenId.add(1);
	}

	/*
	 * @dev increments the value of _currentTokenId
	 */
	function _incrementTokenId() private {
		_currentTokenId++;
	}

	function setBaseURI(string calldata baseURI_) external onlyOwner() {
		_setBaseURI(baseURI_);
	}

	function getCreator(uint256 _id) public view returns (address) {
		return creators[_id];
	}

	function getLoyaltyFee(uint256 _id) public view returns (uint256) {
		return loyaltyFee[_id];
	}
}
