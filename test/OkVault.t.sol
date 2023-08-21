// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {OkToken} from "../src/OkToken.sol";
import {OkVault} from "../src/OkVault.sol";
import {OkUSD} from "./OkUSD.sol";
import {console} from "forge-std/Script.sol";

contract OkVaultTest is Test {
    OkVault public vault;
    OkToken public token;
    IERC20 public usdt;
    address public alice;
    address public bob;
    address public creator;
    address public whale = 0xF977814e90dA44bFA03b6295A0616a897441aceC;

    function setUp() public {
        creator = address(0x3);
        bob = address(0x2);
        alice = address(0x1);

        address usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        usdt = IERC20(usdtAddress);
        vault = new OkVault(usdtAddress, creator);
        token = OkToken(vault.getOkTokenAddress());
        vm.deal(usdtAddress, address(this), 100000000000 ether);
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

    function test_MultiplyWithdraw() public {
        uint256 amount = 100 * 1e6;
        usdt.transfer(alice, amount);
        usdt.transfer(bob, amount);
        vm.startPrank(alice);
        usdt.approve(address(vault), amount);
        vault.deposit(amount);
        vm.startPrank(bob);
        usdt.approve(address(vault), amount);
        vault.deposit(amount);
        vault.withdraw(50 ether);
        vm.stopPrank();
        vm.startPrank(alice);
        vault.withdraw(50 ether);
        assertEq(usdt.balanceOf(address(vault)), 85984358);
        assertEq(token.balanceOf(alice), 40 ether);
        assertEq(token.balanceOf(bob), 35263202770106721108);
        assertEq(vault.exchangeRate(), 1142448);
    }
}
