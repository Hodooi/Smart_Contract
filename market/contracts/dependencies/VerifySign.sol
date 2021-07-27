// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";

contract VerifySign {
    // Using Openzeppelin ECDSA cryptography library
    function getMessageHash(
        address _buyer,
        uint256 _itemId,
        uint256 _quantity,
        uint256 _paymentAmount,
        address _paymentToken
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_buyer, _itemId, _quantity, _paymentAmount, _paymentToken));
    }

    // Verify signature function
    function verify(bytes memory _buyerSignature, address _buyer, uint256 _itemId, uint256 _quantity, uint256 _paymentAmount, address _paymentToken) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_buyer, _itemId, _quantity, _paymentAmount, _paymentToken);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return getSignerAddress(ethSignedMessageHash, _buyerSignature) == _buyer;
    }

    function getSignerAddress(bytes32 _messageHash, bytes memory _signature) public pure returns (address signer) {
        return ECDSA.recover(_messageHash, _signature);
    }

    // Split signature to r, s, v
    function splitSignature(bytes memory _signature)
    public
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    ) {
        require(_signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
    public
    pure
    returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(_messageHash);
    }
}