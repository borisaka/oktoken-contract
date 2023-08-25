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
    address internal joe = address(0x4);
    // address public usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function setUp() public {
        vm.label(creator, "Creator");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        asset = new USDAsset();
        vault = new OkTokenVault(address(asset), creator);
        // console.log("Token Vault address: %s", address(vault));
        // console.log("Token Vault decimals: %s", vault.decimals());
    }

    function testDepositRedeem() public {
        uint256 amountDeposit = 1000 * 1e6;
        uint256 amountRedeem = 500 ether;
        console.log("Rate: %s", vault.exchangeRate());
        _deposit(amountDeposit, alice);
        console.log("Rate: %s", vault.exchangeRate());

        console.log("totalAssets", vault.totalAssets());
        console.log("alice balance: %s", vault.balanceOf(alice));
        console.log("Max withdraw: %s", vault.maxWithdraw(alice));

        assertEq(asset.balanceOf(address(vault)), 950 * 1e6);
        assertEq(vault.balanceOf(alice), 900 ether);

        _redeem(amountRedeem, alice);
        assertEq(asset.balanceOf(address(vault)), 451250000);
        assertEq(vault.balanceOf(alice), 400 ether);

        console.log("totalAssets: %s", vault.totalAssets());
        console.log("totalSupply: %s", vault.totalSupply());
        console.log("Rate: %s", vault.exchangeRate());

        assertEq(vault.exchangeRate(), 1128124);
    }

    function testDepositWithdraw() public {
        uint256 amountDeposit = 100 * 1e6;
        uint256 amountWithdraw = 50 * 1e6;
        _deposit(amountDeposit, alice);
        console.log("Rate: %s", vault.exchangeRate());
        console.log("totalAssets", vault.totalAssets());
        _withdraw(amountWithdraw, alice);
        assertEq(asset.balanceOf(address(vault)), 42500000);
        assertEq(asset.balanceOf(alice), amountWithdraw);
        assertEq(vault.balanceOf(alice), 37894736811634349351);
        assertEq(vault.exchangeRate(), 1121527);
    }

    function testMintReedem() public {
        uint256 amountMint = 100 ether;
        uint256 amountRedeem = 50 ether;
        _mint(amountMint, alice);
        console.log("Rate: %s", vault.exchangeRate());
        console.log("totalAssets", vault.totalAssets());
        _redeem(amountRedeem, alice);
        assertEq(asset.balanceOf(address(vault)), 55123750);
        assertEq(asset.balanceOf(alice), 47025000);
        assertEq(vault.balanceOf(alice), amountRedeem);
        assertEq(vault.exchangeRate(), 1102474);
    }

    function testMintWithdraw() public {
        uint256 amountMint = 100 ether;
        uint256 amountWithdraw = 50 * 1e6;
        _mint(amountMint, alice);
        console.log("Rate: %s", vault.exchangeRate());
        console.log("totalAssets", vault.totalAssets());
        _withdraw(amountWithdraw, alice);
        assertEq(asset.balanceOf(creator), 8 * 1e6);
        assertEq(asset.balanceOf(address(vault)), 52 * 1e6);
        assertEq(asset.balanceOf(alice), amountWithdraw);
        assertEq(vault.balanceOf(alice), 47368421029967262871);
        assertEq(vault.exchangeRate(), 1097777);
    }

    function testMultiplyDeposit() public {
        uint256 amount = 100 * 1e6;
        _deposit(amount, alice);
        _deposit(amount, bob);
        _deposit(amount, joe);
        console.log("totalAssets", vault.totalAssets());
        console.log("alice balance: %s", vault.balanceOf(alice));
        console.log("bob balance: %s", vault.balanceOf(bob));
        console.log("joe balance: %s", vault.balanceOf(joe));
        console.log("Alice max withdraw: %s", vault.maxWithdraw(alice));
        console.log("Bob max withdraw: %s", vault.maxWithdraw(bob));
        console.log("Joe max withdraw: %s", vault.maxWithdraw(joe));
        assertEq(asset.balanceOf(address(vault)), 285 * 1e6);
        assertEq(vault.balanceOf(alice), 90 ether);
        assertEq(vault.balanceOf(bob), 85263157944598337425);
        assertEq(vault.balanceOf(joe), 83019390642076103821);
        assertEq(asset.balanceOf(creator), 15 * 1e6);
        // assertEq(vault.exchangeRate(), 1084083);
    }

    function testMultiplyRedeem() public {
        uint256 amountDeposit = 100 * 1e6;
        _deposit(amountDeposit, alice);
        _deposit(amountDeposit, bob);
        _deposit(amountDeposit, joe);

        uint256 amountRedeemAlice = vault.maxRedeem(alice);
        uint256 assetsAlice = vault.previewRedeem(amountRedeemAlice);
        _redeem(amountRedeemAlice, alice);

        uint256 amountRedeemBob = vault.maxRedeem(bob);
        uint256 assetsBob = vault.previewRedeem(amountRedeemBob);
        _redeem(amountRedeemBob, bob);

        uint256 amountRedeemJoe = vault.maxRedeem(joe);
        uint256 assetsJoe = vault.previewRedeem(amountRedeemJoe);
        _redeem(amountRedeemJoe, joe);

        assertEq(asset.balanceOf(address(vault)), 5479570);
        assertEq(asset.balanceOf(creator), 28310496);
        assertEq(vault.totalSupply(), 0);
        assertEq(asset.balanceOf(alice), assetsAlice);
        assertEq(asset.balanceOf(bob), assetsBob);
        assertEq(asset.balanceOf(joe), assetsJoe);
        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.balanceOf(bob), 0);
        assertEq(vault.balanceOf(joe), 0);
        console.log("previewDeposit 100 USDT", vault.previewDeposit(100 * 1e6));
        console.log("previewMint 100 OKT", vault.previewMint(100 * 1e18));
        console.log("Rate: %s", vault.exchangeRate());

        // assertEq(vault.exchangeRate(), 1142448);
    }

    function _deposit(uint256 amount, address user) internal {
        asset.transfer(user, amount);
        vm.startPrank(user);
        asset.approve(address(vault), amount);
        console.log("previewDeposit", amount, vault.previewDeposit(amount));
        vault.deposit(amount, user);
        vm.stopPrank();
    }

    function _withdraw(uint256 amount, address user) internal {
        vm.startPrank(user);
        console.log("maxWithdraw", amount, vault.maxWithdraw(user));
        console.log("previewWithdraw", amount, vault.previewWithdraw(amount));
        vault.withdraw(amount, user, user);
        vm.stopPrank();
    }

    function _redeem(uint256 amount, address user) internal {
        vm.startPrank(user);
        console.log("maxRedeem", vault.maxRedeem(user));
        console.log("previewRedeem", amount, vault.previewRedeem(amount));
        vault.redeem(amount, user, user);
        vm.stopPrank();
    }

    function _mint(uint256 amount, address user) internal {
        uint256 assets = vault.previewMint(amount);
        console.log("previewMint", amount, assets);
        asset.transfer(user, assets);
        vm.startPrank(user);
        asset.approve(address(vault), assets);
        vault.mint(amount, user);
        vm.stopPrank();
    }
}
