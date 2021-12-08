// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IMarket.sol";

contract HodooiManager is Ownable, Pausable {
    address public farmingContract;
    address public referralContract;
    address public exchangeContract;
    address public oldMarket;

    uint256 public marketFee;
    uint256 public firstSellFee;
    uint256 public artistLoyaltyFee;
    uint256 public referralFee;

    uint256 public limitAuction;
    uint256 public numberItems;
    uint256 public numberBidOrders;
    //A record of bidding status
    bool public biddingStatus;

    mapping(address => uint256) whitelistPayableToken;

    event BiddingStatus(address _account, bool _status);

    function pause() onlyOwner public {
        _pause();
    }
    function unPause() onlyOwner public {
        _unpause();
    }

    function enableBidding() onlyOwner public {
        biddingStatus = true;
        emit BiddingStatus(msg.sender, biddingStatus);
    }

    function disableBidding() onlyOwner public {
        biddingStatus = false;
        emit BiddingStatus(msg.sender, biddingStatus);
    }

    function setSystemFee(uint256 _marketFee, uint256 _firstSellFee, uint256 _artistLoyaltyFee, uint256 _referralFee) onlyOwner
    public returns (bool) {
        marketFee = _marketFee;
        firstSellFee = _firstSellFee;
        artistLoyaltyFee = _artistLoyaltyFee;
        referralFee = _referralFee;
        return true;
    }

    function setOldMarket(address _oldMarket) onlyOwner public returns (bool) {
        oldMarket = _oldMarket;
        return true;
    }

    function setLimitAuction(uint256 _limit) onlyOwner public returns (bool) {
        limitAuction = _limit;
        return true;
    }

    function setFarmingContract(address _farmingContract) onlyOwner public returns (bool) {
        farmingContract = _farmingContract;
        return true;
    }

    function setReferralContract(address _referralContract) onlyOwner public returns (bool) {
        referralContract = _referralContract;
        return true;
    }

    function setExchangeContract(address _exchangeContract) onlyOwner public returns (bool) {
        exchangeContract = _exchangeContract;
        return true;
    }

    function setWhiteListPayableToken(address _token, uint256 _status) onlyOwner public returns (bool){
        whitelistPayableToken[_token] = _status;
        if (_token != address (0)) {
            IERC20(_token).approve(msg.sender, uint(-1));
            IERC20(_token).approve(address (this), uint(-1));
        }
        return true;
    }

    function transferOwnerOldMarket(address _newOwner) external onlyOwner {
        IMarket(oldMarket).transferOwnership(_newOwner);
    }
}
