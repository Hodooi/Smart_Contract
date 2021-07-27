// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import "./interfaces/IERC1155.sol";
import "./interfaces/IBSCswapRouter.sol";
import "./interfaces/IReferral.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/IMarket.sol";

import "./token/ERC1155Holder.sol";
import "./dependencies/VerifySign.sol";

contract HodooiMarket is Ownable, Pausable, ERC1155Holder, VerifySign, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address public farmingContract;
    address public referralContract;
    address public exchangeContract;
    address public oldMarket;

    uint256 public constant ZOOM_USDT = 10 ** 6;
    uint256 public constant ZOOM_FEE = 10 ** 4;

    uint256 public marketFee;
    uint256 public firstSellFee;
    uint256 public artistLoyaltyFee;
    uint256 public referralFee;

    uint256 public limitAuction;
    uint256 public numberItems;
    uint256 public numberBidOrders;
    //A record of bidding status
    bool public biddingStatus;

    struct Item {
        address owner;
        address tokenAddress;
        address paymentToken;
        uint256 tokenId;
        uint256 quantity;
        uint256 expired;
        uint256 status; // 1: available| 2: sold out| 3: cancel list
        uint256 minBid;
        uint256 price;
        uint256 mask; // 1: for sale | 2: for bid
    }

    struct Fee {
        uint256 itemFee;
        uint256 buyerFee;
        uint256 sellerFee;
        uint256 loyaltyFee;
    }
    struct ReferralAddress {
        address payable buyerRef;
        address payable sellerRef;
    }
    struct BidOrder {
        address fromAddress;
        address bidToken;
        uint256 bidAmount;
        uint256 itemId;
        uint256 quantity;
        uint256 expired;
        uint256 status; // 1: available | 2: done | 3: reject
    }

    mapping(uint256 => Item) public items;
    mapping(address => mapping(uint256 => uint256)) lastSalePrice;
    mapping(uint256 => BidOrder) bidOrders;
    mapping(address => uint256) whitelistPayableToken;

    event Withdraw(address indexed beneficiary, uint256 withdrawAmount);
    event FailedWithdraw(address indexed beneficiary, uint256 withdrawAmount);
    event Buy(uint256 _itemId, uint256 _quantity, address _paymentToken, uint256 _paymentAmount);
    event AcceptSale(address _buyer, uint256 _itemId, uint256 _quantity, address _paymentToken, uint256 _paymentAmount, uint256 _status);
    event UpdateItem(uint256 _itemId, uint256 _mask, uint256 _price, address _paymentToken, uint256 _expiration);
    event CancelListed(uint256 _itemId, address _receiver);
    event Bid(uint _bidId, uint256 _itemId, uint256 _quantity, address _bidToken, uint256 _bidAmount, uint256 _expiration);
    event List(uint _orderId, address _tokenAddress, uint256 tokenId, uint256 _quantity, uint256 _mask, uint256 _price, address _paymentToken, uint256 _expiration);
    event AcceptBid(uint256 _bidOrderId, bool _result);
    event UpdateBid(uint256 _bidId, uint256 _quantity, address _bidToken, uint256 _bidAmount, uint256 _expiration, uint _status);
    event AdminMigrateData(uint256 _itemId, address _owner, address _toContract);
    event BiddingStatus(address _account, bool _status);
    event PayBack(address _account, uint256 _repay);

    constructor(address _oldMarket, uint256 _limit) public {
        oldMarket = _oldMarket;
        limitAuction = _limit;
    }
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

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


    function getReferralAddress(address _user) private returns(address payable) {
        return payable(IReferral(referralContract).getReferral(_user));
    }

    Fee fee;
    ReferralAddress ref;

    function estimateUSDT(address _paymentToken, uint256 _paymentAmount) private returns (uint256) {
        return IExchange(exchangeContract).estimateToUSDT(_paymentToken, _paymentAmount);
    }

    function estimateToken(address _paymentToken, uint256 _usdtAmount) private returns (uint256) {
        return IExchange(exchangeContract).estimateFromUSDT(_paymentToken, _usdtAmount);
    }

    function executeOrder(address _buyer, uint256 _itemId, uint256 _quantity, address _paymentToken, uint256 _paymentAmount)
    private returns(bool) {
        Item storage item = items[_itemId];
        address payable creator = payable(IERC1155(item.tokenAddress).getCreator(item.tokenId));
        uint256 loyalty = IERC1155(item.tokenAddress).getLoyaltyFee(item.tokenId);

        uint256 itemPrice = estimateToken(_paymentToken, item.price.div(item.quantity).mul(_quantity));
        uint256 priceInUsdt = item.price.div(item.quantity).mul(_quantity);

        if(_paymentToken == address(0)){
            require (msg.value >= _paymentAmount, 'Invalid price (BNB)');
        }

        // for sale
        if(item.mask == 1){
            require (_paymentAmount >= itemPrice.mul(ZOOM_FEE + marketFee).div(ZOOM_FEE), 'Invalid price');
            if(_paymentToken == address(0)){
                // excess cash (BNB)
                uint256 _repay = _paymentAmount.sub(itemPrice.mul(ZOOM_FEE + marketFee).div(ZOOM_FEE));
                if(_repay > 0){
                    address payable _payee = payable(_buyer);
                    _payee.transfer(_repay);
                    emit PayBack(_buyer, _repay);
                }
            }else{
                // erc20
                _paymentAmount = itemPrice.mul(ZOOM_FEE + marketFee).div(ZOOM_FEE);
            }
        }else{
            // for acceptSale
            require (_paymentAmount >= itemPrice, 'Invalid min price');
            itemPrice = estimateToken(_paymentToken, _paymentAmount.div(ZOOM_FEE + marketFee).mul(ZOOM_FEE));
            priceInUsdt = itemPrice;
        }

        ref.buyerRef = getReferralAddress(_buyer);
        ref.sellerRef = getReferralAddress(item.owner);
        if (lastSalePrice[item.tokenAddress][item.tokenId] == 0) { // first sale
            if (msg.value == 0) {
                if (item.tokenAddress == farmingContract) {
                    /**
                        * buyer pay itemPrice + marketFee
                        * seller receive artistLoyaltyFee * itemPrice / 100
                        * artist receive itemPrice * (100 - artistLoyaltyFee)
                        * referral of buyer receive (marketFee * itemPrice / 100) * (referralFee / 100)
                    */
                    fee.itemFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    ERC20(_paymentToken).safeTransferFrom(_buyer, address(this), _paymentAmount);
                    IERC20(_paymentToken).transfer(creator, itemPrice.mul(artistLoyaltyFee).div(ZOOM_FEE));
                    IERC20(_paymentToken).transfer(item.owner, itemPrice.mul(ZOOM_FEE - artistLoyaltyFee).div(ZOOM_FEE));
                    if (ref.buyerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.buyerRef, fee.itemFee.mul(referralFee).div(ZOOM_FEE));
                    }
                } else {
                    /**
                       * buyer pay itemPrice + marketFee
                       * seller receive itemPrice - itemPrice * firstSellFee / 100
                       * referral of seller receive itemPrice * firstSellFee / 100 * (referralFee / 100)
                       * referral of buyer receive itemPrice * marketFee / 100 * (referralFee / 100)
                   */
                    fee.buyerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    fee.sellerFee = itemPrice.mul(firstSellFee).div(ZOOM_FEE);
                    ERC20(_paymentToken).safeTransferFrom(_buyer, address(this), _paymentAmount);
                    IERC20(_paymentToken).transfer(item.owner, itemPrice.mul(ZOOM_FEE - firstSellFee).div(ZOOM_FEE));
                    if (ref.buyerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.buyerRef, fee.buyerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                    if (ref.sellerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.sellerRef, fee.sellerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                }
            } else {
                if (item.tokenAddress == farmingContract) {
                    /**
                        * buyer pay itemPrice + marketFee
                        * seller receive artistLoyaltyFee * itemPrice / 100
                        * artist receive itemPrice * (100 - artistLoyaltyFee)
                        * referral of buyer receive (marketFee * itemPrice / 100) * (referralFee / 100)
                    */
                    fee.itemFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    creator.transfer(itemPrice.mul(artistLoyaltyFee).div(ZOOM_FEE));
                    payable(item.owner).transfer(itemPrice.mul(ZOOM_FEE - artistLoyaltyFee).div(ZOOM_FEE));
                    if (ref.buyerRef != address(0)) {
                        ref.buyerRef.transfer(fee.itemFee.mul(referralFee).div(ZOOM_FEE));
                    }
                } else {
                    /**
                       * buyer pay itemPrice + marketFee
                       * seller receive itemPrice - itemPrice * firstSellFee / 100
                       * referral of seller receive itemPrice * firstSellFee / 100 * (referralFee / 100)
                       * referral of buyer receive itemPrice * marketFee / 100 * (referralFee / 100)
                   */
                    fee.buyerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    fee.sellerFee = itemPrice.mul(firstSellFee).div(ZOOM_FEE);
                    payable(item.owner).transfer(itemPrice.mul(ZOOM_FEE - firstSellFee).div(ZOOM_FEE));
                    if (ref.buyerRef != address(0)) {
                        ref.buyerRef.transfer(fee.buyerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                    if (ref.sellerRef != address(0)) {
                        ref.sellerRef.transfer(fee.sellerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                }
            }
        } else {
            if (lastSalePrice[item.tokenAddress][item.tokenId] < priceInUsdt) {
                uint256 revenue = (priceInUsdt - lastSalePrice[item.tokenAddress][item.tokenId]).mul(ZOOM_FEE).div(priceInUsdt);
                /**
                       * buyer pay itemPrice + marketFee
                       * seller receive itemPrice - itemPrice * marketFee / 100 - revenue * lastSalePrice[tokenAddress][tokenId] * item.loyalty
                       * referral of seller receive  itemPrice * marketFee / 100 * (referralFee / 100)
                       * referral of buyer receive itemPrice * marketFee / 100 * (referralFee / 100)
                       * creator receive revenue * lastSalePrice[tokenAddress][tokenId] * loyalty
                   */
                if (msg.value > 0) {
                    fee.loyaltyFee = itemPrice.mul(revenue).div(ZOOM_FEE).mul(loyalty).div(ZOOM_FEE);
                    fee.buyerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    fee.sellerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    payable(item.owner).transfer(itemPrice.mul(ZOOM_FEE - marketFee).div(ZOOM_FEE).sub(fee.loyaltyFee));
                    creator.transfer(fee.loyaltyFee);
                    if (ref.buyerRef != address(0)) {
                        ref.buyerRef.transfer(fee.buyerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                    if (ref.sellerRef != address(0)) {
                        ref.sellerRef.transfer(fee.sellerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                } else {
                    fee.loyaltyFee = itemPrice.mul(revenue).div(ZOOM_FEE).mul(loyalty).div(ZOOM_FEE);
                    fee.buyerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    fee.sellerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                    ERC20(_paymentToken).safeTransferFrom(_buyer, address(this), _paymentAmount);
                    IERC20(_paymentToken).transfer(item.owner, itemPrice.mul(ZOOM_FEE - marketFee).div(ZOOM_FEE).sub(fee.loyaltyFee));
                    IERC20(_paymentToken).transfer(creator, fee.loyaltyFee);
                    if (ref.buyerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.buyerRef, fee.buyerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                    if (ref.sellerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.sellerRef, fee.sellerFee.mul(referralFee).div(ZOOM_FEE));
                    }

                }
            } else {
                fee.buyerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                fee.sellerFee = itemPrice.mul(marketFee).div(ZOOM_FEE);
                if (msg.value == 0) {
                    ERC20(_paymentToken).safeTransferFrom(_buyer, address(this), _paymentAmount);
                    IERC20(_paymentToken).transfer(item.owner, itemPrice.mul(ZOOM_FEE - marketFee).div(ZOOM_FEE));
                    if (ref.buyerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.buyerRef, fee.buyerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                    if (ref.sellerRef != address(0)) {
                        IERC20(_paymentToken).transfer(ref.sellerRef, fee.sellerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                } else {
                    payable(item.owner).transfer(itemPrice.mul(ZOOM_FEE - marketFee).div(ZOOM_FEE));
                    if (ref.buyerRef != address(0)) {
                        ref.buyerRef.transfer(fee.buyerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                    if (ref.sellerRef != address(0)) {
                        ref.sellerRef.transfer(fee.sellerFee.mul(referralFee).div(ZOOM_FEE));
                    }
                }
            }
        }
        _1155SafeTransferFrom(item.tokenAddress, address(this), _buyer, item.tokenId, _quantity);
        lastSalePrice[item.tokenAddress][item.tokenId] = priceInUsdt.mul(ZOOM_FEE + marketFee).div(ZOOM_FEE);

        // for sale
        if(item.mask == 1){
            item.price = item.price.sub(priceInUsdt);
        }

        item.quantity = item.quantity.sub(_quantity);
        if (item.quantity == 0) {
            item.price = 0;
            item.status = 2; // sold out
        }
        return true;
    }

    function list(address _tokenAddress, uint256 _tokenId, uint256 _quantity, uint256 _mask, uint256 _price, address _paymentToken, uint256 _expiration)
    public whenNotPaused returns (uint256 _idx){
        uint balance = IERC1155(_tokenAddress).balanceOf(msg.sender, _tokenId);
        require(balance >= _quantity, 'Not enough token for sale');
        if(_paymentToken != address(0)){
            require(whitelistPayableToken[_paymentToken] == 1, 'Payment token not support');
        }
        if (_mask == 2) {
            require(_quantity <= limitAuction, 'Quantity exceeded limit');
        }

        _1155SafeTransferFrom(_tokenAddress, msg.sender, address(this), _tokenId, _quantity);

        _idx = numberItems;
        uint256 _minBid = 0;
        if (_mask == 2) {
            _minBid = _price;
        }
        Item memory data = Item(msg.sender, _tokenAddress, _paymentToken, _tokenId, _quantity, _expiration, 1, _minBid, _price, _mask);
        _createItem(_idx, data);

        emit List(_idx, _tokenAddress, _tokenId, _quantity, _mask, _price, _paymentToken, _expiration);
        ++numberItems;
        return _idx;
    }

    function bid(uint256 _itemId, uint256 _quantity, address _bidToken, uint256 _bidAmount, uint256 _expiration)
    public returns (uint256 _idx){
        require(biddingStatus,'Bidding is disabled');

        _idx = numberBidOrders;
        Item memory item = items[_itemId];

        require(item.owner != address(0), 'Item not exist');
        require(item.status == 1, 'Item unavailable');
        require(item.quantity >= _quantity, 'Quantity invalid');
        require(item.owner != msg.sender, 'Owner cannot bid');
        require(item.mask == 2, 'Not for bid');
        require(item.expired >= block.timestamp, 'Item expired');

        if(_bidToken != address(0)){
            require(whitelistPayableToken[_bidToken] == 1, 'Payment token not support');

            uint256 estimateBidUSDT = estimateUSDT(_bidToken, _bidAmount);
            estimateBidUSDT = estimateBidUSDT.div(marketFee + ZOOM_FEE).mul(ZOOM_FEE);
            require(estimateBidUSDT >= item.minBid, 'Bid amount must greater than min bid');
            require(IERC20(_bidToken).approve(address(this), _bidAmount) == true, 'Approve token for bid fail');
        }

        BidOrder storage bidOrder = bidOrders[_idx];
        bidOrder.fromAddress = msg.sender;
        bidOrder.bidToken = _bidToken;
        bidOrder.bidAmount = _bidAmount;
        bidOrder.quantity = _quantity;
        bidOrder.expired = block.timestamp.add(_expiration);
        bidOrder.status = 1;

        numberBidOrders++;
        emit Bid(_idx, _itemId, _quantity, _bidToken, _bidAmount, _expiration);
        return _idx;
    }

    function buy(uint256 _itemId, uint256 _quantity, address _paymentToken, uint256 _paymentAmount)
    external payable whenNotPaused returns (bool) {
        Item storage item = items[_itemId];

        require(item.owner != address(0), 'Item not exist');
        require(msg.sender != item.owner, 'You are the owner');
        if(_paymentToken != address(0)){
            require(whitelistPayableToken[_paymentToken] == 1, 'Payment token not support');
        }

        require(item.status == 1, 'Item unavailable');
        require(item.quantity >= _quantity, 'Invalid quantity');
        //        require(item.expired >= block.timestamp, 'Item expired');
        require(item.mask == 1, 'Not for sale');

        if (executeOrder(msg.sender, _itemId, _quantity, _paymentToken, _paymentAmount)) {
            emit Buy(_itemId, _quantity, _paymentToken, _paymentAmount);
            return true;
        }
        return false;
    }

    function acceptSale( bytes memory _buyerSignature, address _buyer, uint256 _itemId, uint256 _quantity, address _paymentToken, uint256 _paymentAmount)
    external whenNotPaused returns (bool) {
        Item storage item = items[_itemId];

        require(item.owner != address(0), 'Item not exist');
        require(_buyer != address(0), 'Buyer not exist');
        require(msg.sender == item.owner, 'You are not owner');
        require(_buyer != item.owner, 'You are the owner');

        if(_paymentToken != address(0)){
            require(whitelistPayableToken[_paymentToken] == 1, 'Payment token not support');
        }

        require(item.status == 1, 'Item unavailable');
        require(item.quantity == _quantity, 'Invalid quantity');
        require(item.mask == 2, 'Not for bid');

        require(verify(_buyerSignature, _buyer, _itemId, _quantity, _paymentAmount, _paymentToken), 'You are not buyer');

        if (executeOrder(_buyer, _itemId, _quantity, _paymentToken, _paymentAmount)) {
            emit AcceptSale(_buyer, _itemId, _quantity, _paymentToken, _paymentAmount, 1);
            return true;
        }

        emit AcceptSale(_buyer, _itemId, _quantity, _paymentToken, _paymentAmount, 0);
        return false;
    }

    function acceptBid(uint256 _bidOrderId) public whenNotPaused returns (bool) {
        require(biddingStatus,'Bidding is disabled');

        BidOrder storage bidOrder = bidOrders[_bidOrderId];
        require(bidOrder.status == 1, 'Bid order unavailable');
        require(bidOrder.expired <= block.timestamp, 'Bid order has expired');

        if (executeOrder(bidOrder.fromAddress, bidOrder.itemId, bidOrder.quantity, bidOrder.bidToken, bidOrder.bidAmount)) {
            bidOrder.status = 2;
            emit AcceptBid(_bidOrderId, true);
            return true;
        }
        emit AcceptBid(_bidOrderId, false);
        return false;
    }

    function updateItem(uint256 _itemId, uint256 _mask, uint256 _price, address _paymentToken, uint256 _expiration)
    public returns (bool) {
        Item storage item = items[_itemId];
        require(item.owner == msg.sender, 'Not the owner of this item');
        if(_paymentToken != address(0)){
            require(whitelistPayableToken[_paymentToken] == 1, 'Payment token not support');
        }
        item.mask = _mask;
        if (_mask == 1) {
            item.price = _price;
        } else {
            item.minBid = _price;
        }
        item.paymentToken = _paymentToken;
        item.expired = block.timestamp.add(_expiration);
        emit UpdateItem(_itemId, _mask, _price, _paymentToken, _expiration);
        return true;
    }

    function updateBid(uint256 _bidId, uint256 _quantity, address _bidToken, uint256 _bidAmount, uint256 _expiration, uint _status)
    public returns (bool) {
        require(biddingStatus,'Bidding is disabled');

        BidOrder storage bidOrder = bidOrders[_bidId];
        require(bidOrder.fromAddress == msg.sender, 'Not owner');
        require(IERC20(_bidToken).approve(address(this), _bidAmount) == true, 'Approve token for bid fail');
        bidOrder.bidToken = _bidToken;
        bidOrder.bidAmount = _bidAmount;
        bidOrder.quantity = _quantity;
        bidOrder.expired = block.timestamp.add(_expiration);
        bidOrder.status = _status;
        emit UpdateBid(_bidId, _quantity, _bidToken, _bidAmount, _expiration, _status);
        return true;
    }

    function cancelListed(uint256 _itemId) public returns (bool) {
        Item storage item = items[_itemId];
        require(item.owner == msg.sender, 'Not the owner of this item');

        _1155SafeTransferFrom(item.tokenAddress, address(this), msg.sender, item.tokenId, item.quantity);

        item.status = 3;
        item.quantity = 0;
        item.price = 0;
        emit CancelListed(_itemId, item.owner);
        return true;
    }

    function withdrawFunds(address payable _beneficiary, address _tokenAddress) external onlyOwner {
        uint _withdrawAmount;
        if (_tokenAddress == address(0)) {
            _beneficiary.transfer(address(this).balance);
            _withdrawAmount = address(this).balance;
        } else {
            _withdrawAmount = IERC20(_tokenAddress).balanceOf(address(this));
            IERC20(_tokenAddress).transfer( _beneficiary, _withdrawAmount);
        }
        emit Withdraw(_beneficiary, _withdrawAmount);
    }

    function adminCancelList(uint256 _itemId, address _receiver) external onlyOwner {
        Item storage item = items[_itemId];
        _1155SafeTransferFrom(item.tokenAddress, address(this), _receiver, item.tokenId, item.quantity);
        item.status = 3;
        item.quantity = 0;
        item.price = 0;
        emit CancelListed(_itemId, _receiver);
    }

    function adminMigrateData(uint256 _fromOrderId, uint256 _toOrderId) external onlyOwner() {
        for (uint256 _itemId = _fromOrderId; _itemId <= _toOrderId; _itemId++) {
            ( address _owner, address _tokenAddress, address _paymentToken, uint256 _tokenId, uint256 _quantity, uint256 _expired, uint256 _status, uint256 _minBid, uint256 _price, uint256 _mask ) = IMarket(oldMarket).items(_itemId);
            numberItems = _itemId;
            if (_quantity > 0) {
                IMarket(oldMarket).adminCancelList(_itemId, address(this));
                Item memory data = Item(_owner, _tokenAddress, _paymentToken, _tokenId, _quantity, _expired, _status, _minBid, _price, _mask);
                _createItem(_itemId, data);
            }
        }
    }

    function adminMigrateLastSale(address[] memory _tokenAddress, uint256[] memory _tokenId, uint256[] memory _price) external onlyOwner() {
        for (uint i = 0; i < _tokenAddress.length; i++) {
            lastSalePrice[_tokenAddress[i]][_tokenId[i]] = _price[i];
        }
    }

    function transferOwnerOldMarket(address _newOwner) external onlyOwner() {
        IMarket(oldMarket).transferOwnership(_newOwner);
    }

    function getLastSale(address _tokenAddress, uint256 _tokenId) public view returns (uint256) {
        return lastSalePrice[_tokenAddress][_tokenId];
    }

    function _createItem(uint256 _itemId, Item memory data)
    private returns(bool){
        items[_itemId] = data;
        return true;
    }

    function _1155SafeTransferFrom(address _token, address _from, address _to, uint256 _id, uint256 _amount)
    private returns(bool){
        IERC1155(_token).safeTransferFrom(_from, _to, _id, _amount, abi.encodePacked(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")));
        return true;
    }
}
