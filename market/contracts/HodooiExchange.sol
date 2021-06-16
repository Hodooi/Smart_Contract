// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBSCswapRouter.sol";

contract HodooiExchange is Ownable {
    address public bnbRouter;
    address public usdt;
    address public usdtMarket;
    address public busd;
    address public bnb;

    constructor(address _bnbRouter, address _usdt, address _busd, address _bnb) public {
        bnbRouter = _bnbRouter;
        usdt = _usdt;
        usdtMarket = _usdt;
        busd = _busd;
        bnb = _bnb;
    }

    function setBnbRouter(address _bnbRouter) onlyOwner public returns (bool) {
        bnbRouter = _bnbRouter;
        return true;
    }

    function setUsdtMarket(address _usdt) onlyOwner public returns (bool) {
        usdtMarket = _usdt;
        return true;
    }

    function setUsdt(address _usdt) onlyOwner public returns (bool) {
        usdt = _usdt;
        return true;
    }

    function setBnb(address _bnb) onlyOwner public returns (bool) {
        bnb = _bnb;
        return true;
    }

    function setBusd(address _busd) onlyOwner public returns (bool) {
        busd = _busd;
        return true;
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
        if (_paymentToken != usdt && _paymentToken != usdtMarket) {
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
        if (_paymentToken != usdt && _paymentToken != usdtMarket) {
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
