// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {OkToken} from "../src/OkToken.sol";

contract CounterTest is Test {
    OkToken public token;
    address public user;
    function setUp() public {
        token = new OkToken(address(this));
        user = address(0x1);
    }

    function test_Mint() public {
        token.mint(user, 100);
        assertEq(token.balanceOf(user), 100);
    }

    function test_Burn() public {
        token.mint(user, 100);
        token.burn(user, 50);
        assertEq(token.balanceOf(user), 50);
    }

}
