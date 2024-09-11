// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUSDT is ERC20 {
    constructor() ERC20("USDT", "USDT") {
        uint256 initialSupply = 1_000_000_000_000 * 10 ** 6;
        _mint(msg.sender, initialSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

    function mintTo(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}
