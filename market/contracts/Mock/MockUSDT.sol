//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockUSDT is ERC20 {
	constructor(address _address, uint256 amount) ERC20('Tether', 'USDT') {
        _mint(_address, amount);
    }

    function mint(address _address, uint256 amount) public returns(bool) {
        _mint(_address, amount);
        return true;
    }
}
