// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "../src/OKToken.sol";
import {TetherToken} from "./utils/USDT.sol";
import {SigUtils} from "./SigUtils.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {console} from "forge-std/Script.sol";

contract OKTokenTest is Test {
    using Math for uint256;

    OKToken public okToken;
    TetherToken public asset;
    SigUtils public sigUtils;
    uint256 alicePrivateKey = 0xA11CE;
    uint256 bobPrivateKey = 0xB0B;

    address internal alice = vm.addr(alicePrivateKey);
    address internal bob = vm.addr(bobPrivateKey);
    address internal creator = address(0x3);
    address internal joe = address(0x4);

    event ExchangeRateUpdated(uint256 rate, uint256 timestamp);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        vm.label(address(this), "OkTokenVaultTest");
        vm.label(creator, "Creator");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        asset = new TetherToken(type(uint256).max, "USDT", "USDT", 6);
        asset.transfer(msg.sender, 100000000000000000000 * 1e6);
        uint64 nonce = vm.getNonce(msg.sender);
        address vaultAddress = vm.computeCreateAddress(msg.sender, nonce);
        vm.startPrank(msg.sender);
        asset.approve(vaultAddress, 100 * 1e6);
        okToken = new OKToken(address(asset), 6, creator);
    }

    function testInitialValues() public {
        assertEq(okToken.asset(), address(asset));
        assertEq(okToken.totalAssets(), 1e6);
        assertEq(okToken.exchangeRate(), 1e6);
        assertEq(okToken.totalSupply(), 1e18);
    }

    function testPreviewDeposit() public {
        uint256 assets = 10 * 1e6;
        // uint256 fee = okToken._calculateFee(assets);
        uint256 shares = okToken.previewDeposit(assets);
        assertEq(shares, 89 * 1e17);
        // assertEq(shares, 100 * 1e6 - fee);
    }

    function testSuccessDeposit() public {
        uint256 assets = 10 * 1e6;

        uint256 expectedShares = 89 * 1e17;
        bytes32 expectedId = keccak256(
            abi.encodePacked(alice, block.timestamp, assets, expectedShares)
        );

        asset.transfer(alice, assets);
        vm.startPrank(alice);
        asset.approve(address(okToken), 2 ** 256 - 1);
        // vm.expectEmit(true, true, false, true);
        // emit OKToken.Deposit(expectedId, alice, assets, expectedShares);
        // emit OKToken.ExchangeRateUpdated(1224719, block.timestamp);
        (uint256 shares, bytes32 depositId) = okToken.deposit(assets);

        vm.stopPrank();
        assertEq(shares, 8900000000000000000);
        assertEq(okToken.totalAssets(), 10900000);
        assertEq(okToken.exchangeRate(), 1224719);
        assertEq(okToken.totalSupply(), 9900000000000000000);
        assertEq(okToken.balanceOf(alice), 8900000000000000000);
        assertEq(asset.balanceOf(address(okToken)), 10900000);
        assertEq(asset.balanceOf(creator), 100000);
    }

    function testRevertMinDeposit() public {
        uint256 assets = 5e6;
        asset.transfer(alice, assets);
        vm.startPrank(alice);
        asset.approve(address(okToken), 2 ** 256 - 1);
        vm.expectRevert("MIN_DEPOSIT");
        okToken.deposit(assets);
        vm.stopPrank();
    }

    function testRevertMaxDeposit() public {
        // uint256 assets = 40 * 1e6;
        asset.transfer(alice, 10_000_000 * 1e6);
        vm.startPrank(alice);
        asset.approve(address(okToken), 2 ** 256 - 1);
        // First deposit <= 10 USDT
        vm.expectRevert("MAX_DEPOSIT");
        okToken.deposit(11 * 1e6);
        okToken.deposit(10 * 1e6);
        // Same with second (because totalAssets == 10 USDT)
        vm.expectRevert("MAX_DEPOSIT");
        okToken.deposit(20 * 1e6);
        // Deposit 10 USDT
        okToken.deposit(10 * 1e6);
        // Now we can deposit 20 USDT
        okToken.deposit(20 * 1e6);
        // But still can't deposit >= 200K USDT
        vm.expectRevert("MAX_DEPOSIT");
        okToken.deposit(200_001 * 1e6);
        // Reaching 200K USDT total assets
        while (okToken.totalAssets() <= 200_000 * 1e6) {
            okToken.deposit(okToken.totalAssets());
        }
        // // And we still can't deposit >= 200K USDT
        okToken.deposit(200_000 * 1e6);
        vm.expectRevert("MAX_DEPOSIT");
        okToken.deposit(200_001 * 1e6);
    }

    function testPreviewWithdraw() public {
        uint256 assets = 10 * 1e6;
        asset.transfer(alice, 20 * 1e6);
        vm.startPrank(alice);
        asset.approve(address(okToken), 2 ** 256 - 1);
        (uint256 shares, bytes32 depositId) = okToken.deposit(10 * 1e6);
        okToken.deposit(10 * 1e6);
        vm.stopPrank();
        uint256 withdraw = okToken.previewWithdraw(depositId);
        assertEq(withdraw, 10190949);
        // assertEq(asset)
    }

    function testWithdraw() public {
        // uint256 assets = 10 * 1e6;
        asset.transfer(alice, 10 * 1e6);
        asset.transfer(bob, 10 * 1e6);
        vm.startPrank(alice);
        asset.approve(address(okToken), 2 ** 256 - 1);
        (uint256 shares, bytes32 depositId) = okToken.deposit(10 * 1e6);
        vm.stopPrank();
        vm.startPrank(bob);
        asset.approve(address(okToken), 2 ** 256 - 1);
        okToken.deposit(10 * 1e6);
        vm.stopPrank();
        vm.startPrank(alice);
        // okToken.approve(address(okToken), shares);
        // uint256 creatorBalance = asset.balanceOf(creator);
        uint256 withdraw = okToken.withdraw(depositId);
        vm.stopPrank();
        assertEq(withdraw, 10190949);
        assertEq(okToken.totalAssets(), 10494546);
        assertEq(okToken.exchangeRate(), 1444142);
        assertEq(okToken.totalSupply(), 8266972626883245240);
        assertEq(okToken.balanceOf(alice), 0);
        assertEq(asset.balanceOf(alice), 10190949);
        assertEq(asset.balanceOf(creator), 314505);
    }

    function testRevertWithdrawNotOwner() public {
        asset.transfer(alice, 10 * 1e6);
        vm.startPrank(alice);
        asset.approve(address(okToken), 2 ** 256 - 1);
        (uint256 shares, bytes32 depositId) = okToken.deposit(10 * 1e6);
        vm.stopPrank();
        asset.transfer(bob, 10 * 1e6);
        vm.startPrank(bob);
        asset.approve(address(okToken), 2 ** 256 - 1);
        vm.expectRevert("NOT_OWNER");
        okToken.withdraw(depositId);
        vm.stopPrank();
    }

    function testRewertWithdrawClosedDeposit() public {
        asset.transfer(alice, 10 * 1e6);
        vm.startPrank(alice);
        asset.approve(address(okToken), 2 ** 256 - 1);
        (uint256 shares, bytes32 depositId) = okToken.deposit(10 * 1e6);
        vm.stopPrank();
        vm.startPrank(alice);
        okToken.withdraw(depositId);
        vm.stopPrank();
        vm.startPrank(alice);
        vm.expectRevert("DEPOSIT_CLOSED");
        okToken.withdraw(depositId);
        vm.stopPrank();
    }

    function testCanLiquidate() public {
        asset.transfer(alice, 10 * 1e6);
        vm.startPrank(alice);
        asset.approve(address(okToken), 2 ** 256 - 1);
        (uint256 shares, bytes32 depositId) = okToken.deposit(10 * 1e6);
        vm.stopPrank();
        // Testing forbid liquidation
        vm.prank(bob);
        asset.approve(address(okToken), 2 ** 256 - 1);
        while (okToken.previewWithdraw(depositId) < 145e5) {
            // vm.expectRevert("NOT_LIQUIDABLE");
            assertEq(okToken.canLiquidate(depositId), false);
            uint256 amount = okToken.maxDeposit();
            asset.transfer(bob, amount);
            vm.prank(bob);
            okToken.deposit(amount);
        }
        vm.prank(bob);
        assertEq(okToken.canLiquidate(depositId), true);
    }

    function testLiquidate() public {
        asset.transfer(alice, 10 * 1e6);
        vm.startPrank(alice);
        asset.approve(address(okToken), 2 ** 256 - 1);
        (uint256 shares, bytes32 depositId) = okToken.deposit(10 * 1e6);
        vm.stopPrank();
        // Testing forbid liquidation
        vm.prank(bob);
        asset.approve(address(okToken), 2 ** 256 - 1);
        while (okToken.previewWithdraw(depositId) < 145e5) {
            vm.expectRevert("NOT_LIQUIDABLE");
            okToken.liquidate(depositId);
            uint256 amount = okToken.maxDeposit();
            asset.transfer(bob, amount);
            vm.prank(bob);
            okToken.deposit(amount);
        }
        vm.prank(bob);
        okToken.liquidate(depositId);
        assertEq(14653679, asset.balanceOf(alice));
        vm.expectRevert("DEPOSIT_CLOSED");
        okToken.liquidate(depositId);
    }
}
