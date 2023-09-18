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
    ERC20 public asset;
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

        // console.log("Token Vault address: %s", address(vault));
        // console.log("Token Vault decimals: %s", vault.decimals());
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

    function _deposit(uint256 amount, address user) internal {
        asset.transfer(user, amount);
        vm.startPrank(user);
        asset.approve(address(vault), amount);
        uint256 shares = vault.previewDeposit(amount);
        console.log("previewDeposit", amount, shares);
        vault.deposit(amount, user, shares);
        vm.stopPrank();
    }

    function _withdraw(uint256 amount, address user) internal {
        vm.startPrank(user);
        console.log("maxWithdraw", amount, vault.maxWithdraw(user));
        uint256 shares = vault.previewWithdraw(amount);
        console.log("previewWithdraw", amount, shares);
        vault.withdraw(amount, user, user, shares);
        vm.stopPrank();
    }

    function _redeem(uint256 amount, address user) internal {
        vm.startPrank(user);
        console.log("maxRedeem", vault.maxRedeem(user));
        uint256 assets = vault.previewRedeem(amount);
        console.log("previewRedeem", amount, assets);
        vault.redeem(amount, user, user, assets);
        vm.stopPrank();
    }

    function _mint(uint256 amount, address user) internal {
        uint256 assets = vault.previewMint(amount);
        console.log("previewMint", amount, assets);
        asset.transfer(user, assets);
        vm.startPrank(user);
        asset.approve(address(vault), assets);
        vault.mint(amount, user, assets);
        vm.stopPrank();
    }
}
