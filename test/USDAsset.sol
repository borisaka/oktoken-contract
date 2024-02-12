// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract USDAsset is ERC20 {
    constructor() ERC20("USD asset", "USD_Ass", 6) {
        _mint(msg.sender, 100000000000 ether);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
