// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {OkTokenVault} from "../src/OkTokenVault.sol";
import {USDAsset} from "./USDAsset.sol";
import {console} from "forge-std/Script.sol";
import {SigUtils} from "./SigUtils.sol";

error MinimumDeposit();
error MinimumWidraw();

contract OkTokenVaultTest is Test {
    OkTokenVault public vault;
    USDAsset public asset;
    SigUtils public sigUtils;
    uint256 alicePrivateKey = 0xA11CE;
    uint256 bobPrivateKey = 0xB0B;

    address internal alice = vm.addr(alicePrivateKey);
    address internal bob = vm.addr(bobPrivateKey);
    address internal creator = address(0x3);
    address internal joe = address(0x4);
    // address public usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function setUp() public {
        vm.label(address(this), "OkTokenVaultTest");
        vm.label(creator, "Creator");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        asset = new USDAsset();
        vault = new OkTokenVault(address(asset), creator);
        sigUtils = new SigUtils(vault.DOMAIN_SEPARATOR());
        // asset.mint(address(vault), 1 * 1e6); // 100 USDT initial deposit
        // asset.approve(address(vault), 100 * 1e6);
        // uint256 shares = vault.previewDeposit(100 * 1e6);
        // vault.deposit(100 * 1e6, address(this), shares);
        // console.log("Token Vault address: %s", address(vault));
        // console.log("Token Vault decimals: %s", vault.decimals());
    }

    function testSingleDepositWithdraw() public {
        uint256 aliceAssetsAmount = 100 * 1e6;
        assertEq(vault.totalAssets(), 0);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.exchangeRate(), 1000000);
        _mintAssets(alice, aliceAssetsAmount);
        uint256 creatorPreDepositBal = asset.balanceOf(creator);
        uint256 alicePreDepositBal = asset.balanceOf(alice);
        vm.prank(alice);
        uint256 aliceShareAmount = vault.deposit(aliceAssetsAmount, alice);
        uint256 creatorPostDepositBal = asset.balanceOf(creator);
        uint256 alicePostDepositBal = asset.balanceOf(alice);

        assertEq(creatorPostDepositBal, creatorPreDepositBal + aliceAssetsAmount * 5 / 100); // 5% fee on deposit
        assertEq(alicePostDepositBal, alicePreDepositBal - aliceAssetsAmount);
        // // Expect exchange rate to be 1:1 on initial mint.
        // // assertEq(aliceShareAmount, (aliceAssetsAmount * 10 ** 12) * 95 / 100);
        // assertEq(vault.previewWithdraw(aliceAssetsAmount), aliceAssetsAmount);
        // assertEq(vault.previewDeposit(aliceAssetsAmount), aliceShareAmount);
        assertEq(vault.totalSupply(), aliceShareAmount);
        assertEq(vault.totalAssets(), aliceAssetsAmount * 95 / 100); // 5% fee on deposit, 5% reinvested
        assertEq(vault.balanceOf(alice), aliceShareAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceAssetsAmount * 95 / 100 - 1);
        // assertEq(asset.balanceOf(alice), alicePreDepositBal - aliceAssetsAmount);
        uint256 maxWithdraw = vault.maxWithdraw(alice);
        uint256 totalSupplyBeforeWithdraw = vault.totalSupply();
        console.log("Alice maxWithdraw", maxWithdraw);
        uint256 desireShares = vault.previewWithdraw(maxWithdraw);
        console.log("Alice previewWithdraw", desireShares);
        console.log("convertToAssets", vault.convertToAssets(desireShares));
        creatorPreDepositBal = asset.balanceOf(creator);
        alicePreDepositBal = asset.balanceOf(alice);
        vm.prank(alice);
        aliceShareAmount = vault.withdraw(maxWithdraw, alice, alice, desireShares);
        creatorPostDepositBal = asset.balanceOf(creator);
        alicePostDepositBal = asset.balanceOf(alice);

        uint256 totalSupplyAfterWithdraw = vault.totalSupply();
        console.log("Alice balance", asset.balanceOf(alice));
        console.log("Total supply", vault.totalSupply());
        console.log("Total assets", vault.totalAssets());
        console.log("totalSupplyBeforeWithdraw", totalSupplyBeforeWithdraw);
        console.log("totalSupplyAfterWithdraw", totalSupplyAfterWithdraw);
        assertEq(creatorPostDepositBal, creatorPreDepositBal + maxWithdraw * 5 / 100); // 5% fee on withdraw
            // // assertEq(vault.beforeWithdrawHookCalledCounter(), 1);

        // assertEq(vault.totalAssets(), 0);
        // assertEq(vault.balanceOf(alice), );
        // assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
        // assertEq(alicePostDepositBal, alicePreDepositBal);
    }

    function testMaxRedeem() public {
        uint256 amountDeposit = 100 * 1e6;
        _deposit(amountDeposit, alice);
        uint256 vaultAssets = vault.totalAssets();
        console.log("totalAssets", vaultAssets);
        uint256 amountRedeem = vault.maxRedeem(alice);
        uint256 rawAssets = vault.convertToAssets(amountRedeem);
        console.log("rawAssets", rawAssets);
        console.log("maxRedeem", amountRedeem);
        uint256 assets = vault.previewRedeem(amountRedeem);
        console.log("previewRedeem", vault.previewRedeem(amountRedeem));
        _redeem(amountRedeem, alice);
        assertEq(asset.balanceOf(address(vault)), vaultAssets - (assets * 105 / 100));
        assertEq(asset.balanceOf(alice), assets);
    }

    function testRevertMinimumDeposit() public {
        uint256 amount = 1;
        vm.expectRevert(MinimumDeposit.selector);
        vault.deposit(amount, alice);
    }

    function testRevertMinimumWidraw() public {
        uint256 amountToDeposit = 100 * 1e6;
        uint256 amountToWithdraw = 1;
        _deposit(amountToDeposit, alice);
        vm.expectRevert(MinimumWidraw.selector);
        vault.withdraw(amountToWithdraw, alice, alice);
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
        vm.warp(1 minutes);
        uint256 amountRedeemAlice = vault.maxRedeem(alice);
        uint256 assetsAlice = vault.previewRedeem(amountRedeemAlice);
        _redeem(amountRedeemAlice, alice);
        vm.warp(1 minutes);
        uint256 amountRedeemBob = vault.maxRedeem(bob);
        uint256 assetsBob = vault.previewRedeem(amountRedeemBob);
        _redeem(amountRedeemBob, bob);
        vm.warp(1 minutes);

        uint256 amountRedeemJoe = vault.maxRedeem(joe);
        uint256 assetsJoe = vault.previewRedeem(amountRedeemJoe);
        _redeem(amountRedeemJoe, joe);
        vm.warp(1 minutes);

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

    function testPermit() public {
        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: alice, spender: address(this), value: 10e18, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

        vault.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        assertEq(vault.allowance(alice, address(this)), 10e18);
        assertEq(vault.nonces(alice), 1);
    }

    function testWithdrawWithPermit() public {
        uint256 amountDeposit = 100 * 1e6;
        uint256 deadline = block.timestamp + 1 days;
        uint256 amountWithdraw = 50 * 1e6;
        _deposit(amountDeposit, alice);
        uint256 shares = vault.previewWithdraw(amountWithdraw);
        console.log("shares %s", shares);
        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: alice, spender: address(vault), value: shares, nonce: 0, deadline: deadline});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);
        vm.prank(bob); // bob should can withdraw for alice
        vault.withdrawWithPermit(amountWithdraw, permit.owner, permit.deadline, v, r, s);
        assertEq(vault.nonces(alice), 1);
        assertEq(asset.balanceOf(address(vault)), 42500000);
        assertEq(asset.balanceOf(alice), amountWithdraw);
        assertEq(vault.balanceOf(alice), 37894736811634349351);
        assertEq(vault.exchangeRate(), 1121527);
    }

    function testRedeemWithPermit() public {
        uint256 amountDeposit = 100 * 1e6;
        uint256 deadline = block.timestamp;
        uint256 amountRedeem = 50 ether;
        _deposit(amountDeposit, alice);
        SigUtils.Permit memory _permit =
            SigUtils.Permit({owner: alice, spender: address(vault), value: amountRedeem, nonce: 0, deadline: deadline});

        bytes32 digest = sigUtils.getTypedDataHash(_permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);
        vm.prank(bob); // bob should can redeem for alice
        vault.redeemWithPermit(amountRedeem, _permit.owner, _permit.deadline, v, r, s);
        assertEq(asset.balanceOf(address(vault)), 45125000);
        assertEq(asset.balanceOf(alice), 47500000);
        assertEq(vault.balanceOf(alice), 40 ether);
        assertEq(vault.exchangeRate(), 1128124);
    }

    function testDepositSlippageProtection() public {
        uint256 amountDeposit = 100 * 1e6;
        asset.transfer(alice, amountDeposit);
        vm.prank(alice);
        asset.approve(address(vault), amountDeposit);
        uint256 desirableShares = vault.previewDeposit(amountDeposit);
        // calculate slippage 1%, bps = 100
        uint256 slippage = 100;
        uint256 desirableSharesWithSlippage = desirableShares - (desirableShares * slippage / 10000);
        _deposit(amountDeposit, bob); // bob trying to front run alice
        vm.prank(alice);
        vm.expectRevert("ERC5143: deposit slippage protection");
        vault.deposit(amountDeposit, alice, desirableSharesWithSlippage);
    }

    function testMintSlippageProtection() public {
        uint256 amountMint = 100 ether;
        _mintAssets(alice, 1000 * 1e6);
        vm.prank(alice);
        uint256 desirableShares = vault.previewMint(amountMint);
        // calculate slippage 1%, bps = 100
        uint256 slippage = 100;
        uint256 desirableSharesWithSlippage = desirableShares - (desirableShares * slippage / 10000);
        _mint(amountMint, bob); // bob trying to front run alice
        vm.expectRevert("ERC5143: mint slippage protection");
        vm.prank(alice);
        vault.mint(amountMint, alice, desirableSharesWithSlippage);
    }

    // function testRedeemSlippageProtection() public {
    //     uint256 amountDeposit = 100 * 1e6;
    //     _deposit(amountDeposit, alice);
    //     _deposit(amountDeposit * 100, bob);
    //     uint256 amountRedeem = vault.maxRedeem(alice);
    //     uint256 desirableAssets = vault.previewRedeem(amountRedeem);
    //     console.log("maxRedeem", amountRedeem);
    //     console.log("desirableAssets", desirableAssets);
    //     // calculate slippage 10%, bps = 100
    //     uint256 slippage = 1000;
    //     uint256 desirableAssetsWithSlippage = desirableAssets - (desirableAssets * slippage / 10000);
    //     _withdraw(vault.maxWithdraw(bob), bob); // bob trying to front run alice
    //     vm.startPrank(alice);
    //     // vm.expectRevert("ERC5143: redeem slippage protection");
    //     uint256 assets = vault.redeem(amountRedeem, alice, alice, desirableAssetsWithSlippage);
    //     vm.stopPrank();
    //     console.log("assets", assets);
    // }

    function _mintAssets(address to, uint256 amount) internal {
        vm.startPrank(to);
        asset.mint(to, amount);
        asset.approve(address(vault), amount);
        vm.stopPrank();
    }

    function _deposit(uint256 amount, address user) internal {
        _mintAssets(user, amount);
        vm.startPrank(user);
        uint256 shares = vault.previewDeposit(amount);
        console.log("previewDeposit", user, amount, shares);
        vault.deposit(amount, user, shares);
        vm.stopPrank();
    }

    function _withdraw(uint256 amount, address user) internal {
        vm.startPrank(user);
        console.log("maxWithdraw", amount, vault.maxWithdraw(user));
        uint256 shares = vault.previewWithdraw(amount);
        console.log("previewWithdraw", user, amount, shares);
        vault.withdraw(amount, user, user, shares);
        vm.stopPrank();
    }

    function _redeem(uint256 shares, address user) internal {
        vm.startPrank(user);
        console.log("maxRedeem", vault.maxRedeem(user));
        uint256 assets = vault.previewRedeem(shares);
        console.log("previewRedeem", shares, assets);
        vault.redeem(shares, user, user, assets);
        vm.stopPrank();
    }

    function _mint(uint256 amount, address user) internal {
        uint256 assets = vault.previewMint(amount);
        _mintAssets(user, assets);
        vm.startPrank(user);
        console.log("previewMint", amount, assets);
        vault.mint(amount, user, assets);
        vm.stopPrank();
    }
}
