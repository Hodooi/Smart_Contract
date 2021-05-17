// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./interfaces/IBSCswapRouter.sol";

contract HodooiExchange {
    address public bnbRouter = 0x0000000000000000000000000000000000000000;
    address public usdt = 0x584119951fA66bf223312A29FB6EDEBdd957C5d8;
    address public busd = 0x1a0B0c776950e31b05FB25e3d7E14f99592bFB71;
    address public bnb = 0xD5513cbe97986e7D366B8979D887CB76e441b148;

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
