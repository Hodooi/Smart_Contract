pragma solidity ^0.7.0;

import "./interfaces/IBSCswapRouter.sol";

contract HodooiExchange {
//    main net
//    address public bnbRouter = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
//    address public usdt = 0x55d398326f99059fF775485246999027B3197955;
//    address public busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
//    address public bnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

//    test net
//    address public bnbRouter = 0x0000000000000000000000000000000000000000;
//    address public usdt = 0x584119951fA66bf223312A29FB6EDEBdd957C5d8;
//    address public busd = 0x1a0B0c776950e31b05FB25e3d7E14f99592bFB71;
//    address public bnb = 0xD5513cbe97986e7D366B8979D887CB76e441b148;

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
