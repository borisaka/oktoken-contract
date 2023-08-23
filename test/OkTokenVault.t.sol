// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {OkTokenVault} from "../src/OkTokenVault.sol";
import {USDAsset} from "./USDAsset.sol";
import {console} from "forge-std/Script.sol";

contract OkTokenVaultTest is Test {
    OkTokenVault public vault;
    ERC20 public asset;
    address internal alice = address(0x1);
    address internal bob = address(0x2);
    address internal creator = address(0x3);
    // address public usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function setUp() public {
        vm.label(creator, "Creator");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        asset = new USDAsset();
        vault = new OkTokenVault(address(asset), creator);
        // asset.transfer(address(vault), 1 * 1e6);
        console.log("Token Vault address: %s", address(vault));
        console.log("Token Vault decimals: %s", vault.decimals());
    }

    function testDeposit() public {
        uint256 amount = 100 * 1e6;
        asset.transfer(alice, amount);
        vm.startPrank(alice);
        asset.approve(address(vault), amount);
        console.log("previewDeposit", vault.previewDeposit(amount));
        vault.deposit(amount, alice);
        console.log("totalAssets", vault.totalAssets());
        console.log("alice balance: %s", vault.balanceOf(alice));
        console.log("Max withdraw: %s", vault.maxWithdraw(alice));
        vm.stopPrank();
        assertEq(asset.balanceOf(address(vault)), 95 * 1e6);
        assertEq(vault.balanceOf(alice), 90 ether);
        // assertEq(vault.getRate(), 1055555);
    }

    function testWithdraw() public {
        uint256 amountDeposit = 100 * 1e6;
        uint256 amountWithdraw = 50 * 1e6;
        asset.transfer(alice, amountDeposit);
        vm.startPrank(alice);
        asset.approve(address(vault), amountDeposit);
        vault.deposit(amountDeposit, alice);
        console.log("max withdraw Alice", vault.maxWithdraw(alice));
        console.log("previewWithdraw", vault.previewWithdraw(amountWithdraw));
        vault.withdraw(amountWithdraw, alice, alice);
        assertEq(asset.balanceOf(address(vault)), 42500000);
        assertEq(asset.balanceOf(alice), amountWithdraw);
        assertEq(vault.balanceOf(alice), 37894736811634349351);
        // assertEq(vault.exchangeRate(), 1121528);
    }

    function testMultiplyDeposit() public {
        uint256 amount = 100 * 1e6;
        asset.transfer(alice, amount);
        asset.transfer(bob, amount);
        vm.startPrank(alice);
        asset.approve(address(vault), type(uint256).max);
        vault.deposit(amount, alice);
        vm.startPrank(bob);
        asset.approve(address(vault), amount);
        vault.deposit(amount, bob);
        assertEq(asset.balanceOf(address(vault)), 190 * 1e6);
        assertEq(vault.balanceOf(alice), 90 ether);
        assertEq(vault.balanceOf(bob), 85263157944598337425);
        // assertEq(vault.exchangeRate(), 1084083);
    }

    function testMultiplyWithdraw() public {
        uint256 amountDeposit = 100 * 1e6;
        uint256 amountWithdraw = 50 * 1e6;
        asset.transfer(alice, amountDeposit);
        asset.transfer(bob, amountDeposit);
        vm.startPrank(alice);
        asset.approve(address(vault), amountDeposit);
        vault.deposit(amountDeposit, alice);
        vm.startPrank(bob);
        asset.approve(address(vault), amountDeposit);
        vault.deposit(amountDeposit, bob);
        vault.withdraw(amountWithdraw, bob, bob);
        vm.stopPrank();
        vm.startPrank(alice);
        vault.withdraw(amountWithdraw, alice, alice);
        assertEq(asset.balanceOf(address(vault)), 85000000);
        assertEq(asset.balanceOf(alice), 50 * 1e6);
        assertEq(asset.balanceOf(bob), 50 * 1e6);
        assertEq(vault.balanceOf(alice), 40188365608045700128);
        assertEq(vault.balanceOf(bob), 34529085885551829533);
        // assertEq(vault.exchangeRate(), 1142448);
    }
}
