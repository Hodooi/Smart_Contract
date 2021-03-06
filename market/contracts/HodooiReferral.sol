// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HodooiReferral is Ownable {
    address public admin;
    address public market;

    constructor(address _admin) public {
        admin = _admin;
    }
    mapping(address => address) private referralData;

    function setReferral(address _user, address _ref) public returns(bool){
        require(msg.sender == owner() || msg.sender == admin, "sender is not admin or owner");
        referralData[_user] = _ref;
        return true;
    }

    function setMarket(address _marketAddress) public onlyOwner {
        market = _marketAddress;
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function getReferral(address _user) public view returns(address){
        if (referralData[_user] == address (0)) {
            return market;
        }
        return referralData[_user];
    }
}
