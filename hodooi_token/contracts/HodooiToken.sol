// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HodooiToken is ERC20 {
    constructor() ERC20("Hodooi.com", "HOD") {
        _mint(msg.sender, 1000000000 * (10 ** uint256(decimals())));
    }
}
