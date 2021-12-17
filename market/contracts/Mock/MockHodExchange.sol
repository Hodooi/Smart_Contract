pragma solidity >=0.7.0;

contract MockHodExchange {

	function estimateToUSDT(address _paymentToken, uint256 _paymentAmount) public pure returns (uint256) {
		return _paymentAmount;
	}

	function estimateFromUSDT(address _paymentToken, uint256 _usdtAmount) public pure returns (uint256) {
        return _usdtAmount;
    }
}
