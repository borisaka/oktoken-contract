// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {OkToken} from "../src/OkToken.sol";
import {OKVault} from "../src/OKVault.sol";
import {MockERC20} from "./MockERC20.sol";

contract OkVaultTest is Test {
    OKVault public vault;
    OkToken public token;
    MockERC20 public usdt;
    address public alice;
    address public bob;
    address public creator;

    function setUp() public {
        creator = address(0x3);
        bob = address(0x2);
        alice = address(0x1);

        usdt = new MockERC20();
        token = new OkToken(address(this));
        vault = new OKVault(address(usdt), address(token), creator);
        token.transferOwnership(address(vault));
    }

    function test_Constructor() public {
        assertEq(address(vault.usdtContract()), address(usdt));
        assertEq(address(vault.okTokenContract()), address(token));
        assertEq(vault.creatorAddress(), creator);
    }

    function test_getRate() public {
        uint256 amount = 100 * 1e6;
        usdt.transfer(alice, amount);
        vm.startPrank(alice);
        usdt.approve(address(vault), amount);
        vault.deposit(amount);

        assertEq(vault.getRate(), 1055555);
        assertEq(vault.exchangeRate(), 1055555);
    }

    function test_Deposit() public {
        uint256 amount = 100 * 1e6;
        usdt.transfer(alice, amount);
        vm.startPrank(alice);
        usdt.approve(address(vault), amount);
        vault.deposit(amount);
        vm.stopPrank();
        assertEq(usdt.balanceOf(address(vault)), 95 * 1e6);
        assertEq(token.balanceOf(alice), 90 ether);
        assertEq(vault.getRate(), 1055555);
    }

    function test_Withdraw() public {
        uint256 amount = 100 * 1e6;
        usdt.transfer(alice, amount);
        vm.startPrank(alice);
        usdt.approve(address(vault), amount);
        vault.deposit(amount);
        vault.withdraw(50 ether);
        assertEq(usdt.balanceOf(address(vault)), 44861138);
        assertEq(token.balanceOf(alice), 40 ether);
        assertEq(vault.exchangeRate(), 1121528);
    }

    function test_MultiplyDeposit() public {
        uint256 amount = 100 * 1e6;
        usdt.transfer(alice, amount);
        usdt.transfer(bob, amount);
        vm.startPrank(alice);
        usdt.approve(address(vault), amount);
        vault.deposit(amount);
        vm.startPrank(bob);
        usdt.approve(address(vault), amount);
        vault.deposit(amount);
        assertEq(usdt.balanceOf(address(vault)), 190 * 1e6);
        assertEq(token.balanceOf(alice), 90 ether);
        assertEq(token.balanceOf(bob), 85263202770106721108);
        assertEq(vault.exchangeRate(), 1084083);
    }
}
