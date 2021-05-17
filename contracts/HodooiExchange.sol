pragma solidity ^0.7.0;

import "./interfaces/IBSCswapRouter.sol";

contract HodooiExchange {
    address public immutable override bnbRouter;
    address public immutable override usdt;
    address public immutable override busd;
    address public immutable override bnb;

    constructor(address _swapRouter, address _usdt, address _busd, address _bnb) public {
        bnbRouter = _swapRouter;
        usdt = _usdt;
        busd = _busd;
        bnb = _bnb;
    }

    /**
     * @dev get path for exchange ETH->BNB->USDT via Uniswap
     */
    function getPathFromTokenToUSDT(address token) private view returns (address[] memory) {
        if (token == bnb || token == busd) {
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = usdt;
            return path;
        } else {
            address[] memory path = new address[](3);
            path[0] = token;
            path[1] = bnb;
            path[2] = usdt;
            return path;
        }
    }

    function getPathFromUsdtToToken(address token) private view returns (address[] memory) {
        if (token == bnb || token == busd) {
            address[] memory path = new address[](2);
            path[0] = usdt;
            path[1] = token;
            return path;
        } else {
            address[] memory path = new address[](3);
            path[0] = usdt;
            path[1] = bnb;
            path[2] = token;
            return path;
        }
    }

    function estimateToUSDT(address _paymentToken, uint256 _paymentAmount) public view returns (uint256) {
        uint256[] memory amounts;
        uint256 result;
        if (_paymentToken != usdt) {
            address[] memory path;
            uint256 amountIn = _paymentAmount;
            if (_paymentToken == address(0)) {
                path = getPathFromTokenToUSDT(bnb);
                amounts = IBSCswapRouter(bnbRouter).getAmountsOut(
                    amountIn,
                    path
                );
                result = amounts[1];
            } else {
                path = getPathFromTokenToUSDT(_paymentToken);
                amounts = IBSCswapRouter(bnbRouter).getAmountsOut(
                    amountIn,
                    path
                );
                result = amounts[2];            }
        } else {
            result = _paymentAmount;
        }
        return result;
    }

    function estimateFromUSDT(address _paymentToken, uint256 _usdtAmount) public view returns (uint256) {
        uint256[] memory amounts;
        uint256 result;
        if (_paymentToken != usdt) {
            address[] memory path;
            uint256 amountIn = _usdtAmount;
            if (_paymentToken == address(0)) {
                path = getPathFromUsdtToToken(bnb);
                amounts = IBSCswapRouter(bnbRouter).getAmountsOut(
                    amountIn,
                    path
                );
                result = amounts[1];
            } else {
                path = getPathFromUsdtToToken(_paymentToken);
                amounts = IBSCswapRouter(bnbRouter).getAmountsOut(
                    amountIn,
                    path
                );
                result = amounts[2];
            }
        } else {
            result = _usdtAmount;
        }
        return result;
    }
}
