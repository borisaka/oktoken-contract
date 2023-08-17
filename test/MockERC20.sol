// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("USDT", "usdt", 6) {
        _mint(msg.sender, 1000 ether);
    }
}
