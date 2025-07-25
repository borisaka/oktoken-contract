// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "../src/OkTokenVault.sol";
import {TetherToken} from "./utils/USDT.sol";
import {console} from "forge-std/Script.sol";
import {SigUtils} from "./SigUtils.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract OkTokenVaultTest is Test {
    using Math for uint256;

    OkTokenVault public vault;
    TetherToken public asset;
    SigUtils public sigUtils;
    uint256 alicePrivateKey = 0xA11CE;
    uint256 bobPrivateKey = 0xB0B;

    address internal alice = vm.addr(alicePrivateKey);
    address internal bob = vm.addr(bobPrivateKey);
    address internal creator = address(0x3);
    address internal joe = address(0x4);

    uint256 private constant _BASIS_POINT_SCALE = 1e27; // 100%
    uint256 private constant _feeToTransferBasePoint = 3e26; // 30% to fee recipient, 70% hold on vault.
    uint256 private constant _feeBasePoint = 111111111111111111111111111; // 11,11111111111111111111111111%

    event ExchangeRateUpdated(uint256 rate, uint256 timestamp);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        vm.label(address(this), "OkTokenVaultTest");
        vm.label(creator, "Creator");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        // (uint256 _initialSupply, string memory _name, string memory _symbol, uint256 _decimals)
        console.log("Msg.sender address: %s", msg.sender);
        asset = new TetherToken(type(uint256).max, "USDT", "USDT", 6);
        asset.transfer(msg.sender, 1 * 1e6);
        uint64 nonce = vm.getNonce(msg.sender);
        address vaultAddress = vm.computeCreateAddress(msg.sender, nonce);
        vm.startPrank(msg.sender);
        asset.approve(vaultAddress, 1 * 1e6);
        vault = new OkTokenVault(address(asset), creator);
        vm.stopPrank();
        // asset = TetherToken(0x96a29905AeBa57B5E8516C6d21411802dAeA84f2);
        // vault = OkTokenVault(0xA5481e4298Dfea620Dd664429e52A17461250E94);
        sigUtils = new SigUtils(vault.DOMAIN_SEPARATOR());

        // asset.transfer(address(vault), 1 * 1e6); // 1 USDT initial deposit
        // asset.approve(address(vault), 100 * 1e6);
        // uint256 shares = vault.previewDeposit(100 * 1e6);
        // vault.deposit(100 * 1e6, address(this), shares);
        // console.log("Token Vault address: %s", address(vault));
        // console.log("Token Vault decimals: %s", vault.decimals());
    }

    function testComission() public {
        // console.log("exchangeRate", vault.exchangeRate());
        // console.log("totalAssets", vault.totalAssets());
        // console.log("totalSupply", vault.totalSupply());
        uint256 amountDeposit = 10 * 1e6;
        // uint256 shares = vault.previewDeposit(amountDeposit);
        // console.log("previewDeposit", amountDeposit, shares);
        // vm.prank(alice);
        // asset.approve(address(vault), amountDeposit);
        _deposit(amountDeposit, alice);
        console.log("exchangeRate", vault.exchangeRate());
        // console.log("totalAssets", vault.totalAssets());
        // console.log("totalSupply", vault.totalSupply());
        _deposit(amountDeposit, alice);
        // console.log("exchangeRate", vault.exchangeRate());
        console.log("totalAssets", vault.totalAssets());
        console.log("totalSupply", vault.totalSupply());
        console.log("exchangeRate", vault.exchangeRate());
        // uint256 toWD = vault.previewRedeem(10 * 1e18);
        // console.log("previewRedeem", toWD);

        _redeem(10 * 1e18, alice);
        console.log("totalAssets", vault.totalAssets());
        console.log("totalSupply", vault.totalSupply());
        console.log("exchangeRate", vault.exchangeRate());
    }

    function testInitialExchangeRate() public {
        assertEq(vault.exchangeRate(), 1000000);
    }

    function testZeroSupplyExchangeRate() public {
        // uint256 oneUSD = 1 * 1e6;
        assertEq(vault.exchangeRate(), 1000000);
        _mint(100 ether, alice);
        _redeem(100 ether, alice);
        // assertEq(vault.exchangeRate(), 1000000);
        assertEq(vault.totalSupply(), 1 ether);
        // assertEq(vault.convertToShares(oneUSD), oneUSD.mulDiv(1e18, vault.totalAssets(), Math.Rounding.Floor));
        // assertEq(vault.exchangeRate(), vault.totalAssets());
    }

    function testFuzzDeposit(address user) public {
        vm.assume(user != address(0));
        // vm.assume(amount = vault.minDeposit());
        uint256 amount = vault.minDeposit();
        _mintAssets(user, amount);
        vm.startPrank(user);
        uint256 shares = vault.previewDeposit(amount);
        console.log("previewDeposit", user, amount, shares);
        vault.deposit(amount, user, shares);
        vm.stopPrank();
    }

    function testSingleDepositWithdraw() public {
        // vm.assume(
        //     aliceAssetsAmount > 100 * 1e6 &&
        //         aliceAssetsAmount < vault.maxDeposit()
        // );
        assertEq(vault.totalAssets(), 1 * 1e6);
        assertEq(vault.totalSupply(), 1 * 1e18);
        assertEq(vault.exchangeRate(), 1 * 1e6);
        uint256 amount = 10 * 1e6;
        for (uint256 i = 0; i < 11; i++) {
            _mintAssets(bob, amount);
            vm.prank(bob);
            vault.deposit(amount, bob);
        }
        console.log("totalAssets", vault.totalAssets());
        uint256 supply = vault.totalSupply();
        uint256 totalAssets = vault.totalAssets();
        uint256 aliceAssetsAmount = 100 * 1e6;
        _mintAssets(alice, aliceAssetsAmount);
        uint256 creatorPreDepositBal = asset.balanceOf(creator);
        uint256 alicePreDepositBal = asset.balanceOf(alice);
        vm.prank(alice);
        console.log("aliceAssetsAmount", aliceAssetsAmount);
        uint256 aliceShareAmount = vault.deposit(aliceAssetsAmount, alice);
        uint256 creatorPostDepositBal = asset.balanceOf(creator);
        uint256 alicePostDepositBal = asset.balanceOf(alice);
        console.log("creatorPostDepositBal", creatorPostDepositBal);
        assertEq(
            creatorPostDepositBal,
            creatorPreDepositBal +
                _feeToTransfer(_feeOnTotal(aliceAssetsAmount))
        );
        console.log("alicePostDepositBal", alicePostDepositBal);
        assertEq(alicePostDepositBal, alicePreDepositBal - aliceAssetsAmount);
        console.log("totalAssets", vault.totalAssets());
        console.log("aliceAssetsAmount", aliceAssetsAmount);
        assertEq(vault.totalSupply(), aliceShareAmount + supply);

        // totalAssets should be aliceAssetsAmount + 1e6 (initial deposit) excluding fee
        assertEq(
            vault.totalAssets(),
            totalAssets +
                aliceAssetsAmount -
                _feeToTransfer(_feeOnTotal(aliceAssetsAmount))
        ); // 30% of fe to creator, 70% reinvested
        assertEq(vault.balanceOf(alice), aliceShareAmount);
        console.log("aliceAssetsAmount", aliceAssetsAmount);
        assertEq(
            asset.balanceOf(alice),
            alicePreDepositBal - aliceAssetsAmount
        );
        uint256 maxWithdraw = vault.maxWithdraw(alice);
        uint256 totalSupplyBeforeWithdraw = vault.totalSupply();
        console.log("Alice maxWithdraw", maxWithdraw);
        uint256 desireShares = vault.previewWithdraw(maxWithdraw);
        console.log("Alice previewWithdraw", desireShares);
        console.log("convertToAssets", vault.convertToAssets(desireShares));
        creatorPreDepositBal = asset.balanceOf(creator);
        alicePreDepositBal = asset.balanceOf(alice);
        vm.prank(alice);
        aliceShareAmount = vault.withdraw(
            maxWithdraw,
            alice,
            alice,
            desireShares
        );
        creatorPostDepositBal = asset.balanceOf(creator);
        alicePostDepositBal = asset.balanceOf(alice);

        uint256 totalSupplyAfterWithdraw = vault.totalSupply();
        console.log("Alice balance", asset.balanceOf(alice));
        console.log("Total supply", vault.totalSupply());
        console.log("Total assets", vault.totalAssets());
        console.log("totalSupplyBeforeWithdraw", totalSupplyBeforeWithdraw);
        console.log("totalSupplyAfterWithdraw", totalSupplyAfterWithdraw);
        // Creator should receive 30% of fee on withdraw
        assertEq(
            creatorPostDepositBal,
            creatorPreDepositBal + _feeToTransfer((_feeOnRaw(maxWithdraw)))
        );
    }

    function testMaxRedeem() public {
        uint256 amountDeposit = 100 * 1e6;
        uint256 amount = 10 * 1e6;
        for (uint256 i = 0; i < 11; i++) {
            _mintAssets(bob, amount);
            vm.prank(bob);
            vault.deposit(amount, bob);
        }
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
        assertEq(
            asset.balanceOf(address(vault)),
            vaultAssets - (assets + _feeToTransfer(_feeOnRaw(assets)))
        );
        assertEq(asset.balanceOf(alice), assets);
    }

    function testMaxWithdraw(uint256 amountDeposit) public {
        uint256 amountDeposit = 100 * 1e6;
        uint256 amount = 10 * 1e6;
        for (uint256 i = 0; i < 11; i++) {
            _mintAssets(bob, amount);
            vm.prank(bob);
            vault.deposit(amount, bob);
        }
        _deposit(amountDeposit, alice);
        uint256 vaultAssets = vault.totalAssets();
        uint256 shares = vault.balanceOf(alice);
        uint256 assets = vault.previewRedeem(shares);
        uint256 amountWithdraw = vault.maxWithdraw(alice);
        _withdraw(amountWithdraw, alice);
        assertEq(assets, amountWithdraw);
        assertEq(
            asset.balanceOf(address(vault)),
            vaultAssets -
                (amountWithdraw + _feeToTransfer(_feeOnRaw(amountWithdraw)))
        );
        assertEq(asset.balanceOf(alice), amountWithdraw);
    }

    function testRevertMinimumDeposit() public {
        uint256 amount = 1;
        uint256 minDeposit = 10 * 1e6;
        vm.expectRevert(
            abi.encodeWithSelector(MinimumDeposit.selector, amount, minDeposit)
        );
        vault.deposit(amount, alice);
    }

    function testMinimumMint() public {
        uint256 amountToMint = vault.minMint();
        console.log("amountToMint", amountToMint);
        console.log("previewMint", vault.previewMint(amountToMint));
        _mint(amountToMint, alice);
        assertEq(vault.balanceOf(alice), amountToMint);
    }

    function testRevertMinimumMint() public {
        uint256 amountToMint = 1;
        uint256 minMint = vault.minMint();
        vm.expectRevert(
            abi.encodeWithSelector(MinimumMint.selector, amountToMint, minMint)
        );
        vault.mint(amountToMint, alice);
    }

    function testRevertMinimumWithdraw() public {
        uint256 amount = 10 * 1e6;
        for (uint256 i = 0; i < 11; i++) {
            _mintAssets(bob, amount);
            vm.prank(bob);
            vault.deposit(amount, bob);
        }
        uint256 amountToDeposit = 100 * 1e6;
        uint256 amountToWithdraw = 1;
        _deposit(amountToDeposit, alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                MinimumWithdraw.selector,
                amountToWithdraw,
                vault.minWithdraw()
            )
        );
        vm.prank(alice);
        vault.withdraw(amountToWithdraw, alice, alice);
    }

    function testRevertMimimumRedeem() public {
        uint256 amount = 10 * 1e6;
        for (uint256 i = 0; i < 11; i++) {
            _mintAssets(bob, amount);
            vm.prank(bob);
            vault.deposit(amount, bob);
        }
        uint256 amountToDeposit = 100 * 1e6;
        uint256 amountToRedeem = 1;
        _deposit(amountToDeposit, alice);
        uint256 minRedeem = vault.minRedeem();
        console.log("minRedeem", minRedeem);
        vm.expectRevert(
            abi.encodeWithSelector(
                MinimumRedeem.selector,
                amountToRedeem,
                minRedeem
            )
        );
        vm.prank(alice);
        vault.redeem(amountToRedeem, alice, alice);
    }

    function testDepositRedeem(uint256 amount) public {
        uint256 amountTemp = 10 * 1e6;
        for (uint256 i = 0; i < 11; i++) {
            _mintAssets(bob, amountTemp);
            vm.prank(bob);
            vault.deposit(amountTemp, bob);
        }
        vm.assume(amount >= 100 * 1e6 && amount < vault.maxDeposit(alice));
        uint256 amountDeposit = amount;
        uint256 amountRedeem = (amount * 1e12) / 2;
        assertEq(vault.exchangeRate(), 1e6);
        console.log("Rate: %s", vault.exchangeRate());
        uint256 desiredShares = vault.previewDeposit(amountDeposit);
        _deposit(amountDeposit, alice);
        console.log("Rate: %s", vault.exchangeRate());
        uint256 aliceBalance = vault.balanceOf(alice);
        uint256 vaultAssets = vault.totalAssets();
        console.log("totalAssets", vault.totalAssets());
        console.log("alice balance: %s", vault.balanceOf(alice));
        console.log("Max withdraw: %s", vault.maxWithdraw(alice));

        assertEq(
            vault.totalAssets(),
            1e6 + amountDeposit - _feeToTransfer(_feeOnTotal(amountDeposit))
        );
        assertEq(vault.balanceOf(alice), desiredShares);
        uint256 desiredAssets = vault.previewRedeem(amountRedeem);
        _redeem(amountRedeem, alice);
        assertEq(
            vault.totalAssets(),
            vaultAssets -
                desiredAssets -
                _feeToTransfer(_feeOnRaw(desiredAssets))
        );
        assertEq(vault.balanceOf(alice), aliceBalance - amountRedeem);

        console.log("totalAssets: %s", vault.totalAssets());
        console.log("totalSupply: %s", vault.totalSupply());
        console.log("Rate: %s", vault.exchangeRate());

        // assertEq(vault.exchangeRate(), 1128124);
    }

    function testDepositWithdraw(uint256 amountDeposit) public {
        uint256 amount = 10 * 1e6;
        for (uint256 i = 0; i < 11; i++) {
            _mintAssets(bob, amount);
            vm.prank(bob);
            vault.deposit(amount, bob);
        }
        vm.assume(
            amountDeposit >= 100 * 1e6 &&
                amountDeposit < vault.maxDeposit(alice)
        );
        uint256 amountWithdraw = amountDeposit / 2;
        uint256 desiredShares = vault.previewDeposit(amountDeposit);
        _deposit(amountDeposit, alice);
        assertEq(vault.balanceOf(alice), desiredShares);
        console.log("Rate: %s", vault.exchangeRate());
        console.log("totalAssets", vault.totalAssets());
        uint256 totalAssets = vault.totalAssets();
        desiredShares = vault.previewWithdraw(amountWithdraw);
        uint256 aliceAssetBalance = asset.balanceOf(alice);
        uint256 aliceSharesBalance = vault.balanceOf(alice);
        _withdraw(amountWithdraw, alice);
        assertEq(
            vault.totalAssets(),
            totalAssets -
                amountWithdraw -
                _feeToTransfer(_feeOnRaw(amountWithdraw))
        );
        assertEq(asset.balanceOf(alice), aliceAssetBalance + amountWithdraw);
        assertEq(vault.balanceOf(alice), aliceSharesBalance - desiredShares);
    }

    function testMintReedem(uint256 amountMint) public {
        vm.assume(amountMint >= 100 ether && amountMint < vault.maxMint(alice));
        _mint(amountMint, alice);
        uint256 amountRedeem = amountMint / 2;
        console.log(
            "Amount mint: %s, amount to redeem: %s",
            amountMint,
            amountRedeem
        );
        console.log("Rate: %s", vault.exchangeRate());
        console.log("totalAssets", vault.totalAssets());
        uint256 totalAssets = vault.totalAssets();
        uint256 desiredAssets = vault.previewRedeem(amountRedeem);
        uint256 aliceAssetBalance = asset.balanceOf(alice);
        uint256 aliceSharesBalance = vault.balanceOf(alice);
        _redeem(amountRedeem, alice);
        assertEq(
            vault.totalAssets(),
            totalAssets -
                desiredAssets -
                _feeToTransfer(_feeOnRaw(desiredAssets))
        );
        assertEq(asset.balanceOf(alice), aliceAssetBalance + desiredAssets);
        assertEq(vault.balanceOf(alice), aliceSharesBalance - amountRedeem);
    }

    function testMintWithdraw(uint256 amountMint) public {
        vm.assume(amountMint >= 100 ether && amountMint < vault.maxMint(alice));
        uint256 amountWithdraw = 50 * 1e6;
        _mint(amountMint, alice);
        console.log("Rate: %s", vault.exchangeRate());
        console.log("totalAssets", vault.totalAssets());
        uint256 totalAssets = vault.totalAssets();
        uint256 desiredShares = vault.previewWithdraw(amountWithdraw);
        uint256 aliceAssetBalance = asset.balanceOf(alice);
        uint256 aliceSharesBalance = vault.balanceOf(alice);
        _withdraw(amountWithdraw, alice);
        assertEq(
            vault.totalAssets(),
            totalAssets -
                amountWithdraw -
                _feeToTransfer(_feeOnRaw(amountWithdraw))
        );
        assertEq(asset.balanceOf(alice), aliceAssetBalance + amountWithdraw);
        assertEq(vault.balanceOf(alice), aliceSharesBalance - desiredShares);
    }

    function testMultiplyDeposit(uint256 amount) public {
        vm.assume(
            amount >= vault.minDeposit() && amount < vault.maxDeposit(alice)
        );
        console.log("Rate: %s", vault.exchangeRate());

        _deposit(amount, alice);
        console.log("Rate: %s", vault.exchangeRate());

        _deposit(amount, bob);
        console.log("Rate: %s", vault.exchangeRate());

        _deposit(amount, joe);
        console.log("Rate: %s", vault.exchangeRate());

        console.log("totalAssets", vault.totalAssets());
        console.log("alice balance: %s", vault.balanceOf(alice));
        console.log("bob balance: %s", vault.balanceOf(bob));
        console.log("joe balance: %s", vault.balanceOf(joe));
        console.log("Alice max withdraw: %s", vault.maxWithdraw(alice));
        console.log("Bob max withdraw: %s", vault.maxWithdraw(bob));
        console.log("Joe max withdraw: %s", vault.maxWithdraw(joe));

        // assertEq(vault.exchangeRate(), 1084083);
    }

    function testPermit(uint256 amount) public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: alice,
            spender: address(this),
            value: amount,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

        vault.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );

        assertEq(vault.allowance(alice, address(this)), amount);
        assertEq(vault.nonces(alice), 1);
    }

    function testWithdrawWithPermit(uint256 amountDeposit) public {
        vm.assume(
            amountDeposit >= 20 * 1e6 && amountDeposit < vault.maxDeposit(alice)
        );
        uint256 deadline = block.timestamp + 1 days;
        uint256 amountWithdraw = amountDeposit / 2;
        _deposit(amountDeposit, alice);
        uint256 aliceShares = vault.balanceOf(alice);
        uint256 shares = vault.previewWithdraw(amountWithdraw);
        uint256 totalAssets = vault.totalAssets();
        console.log("shares %s", shares);
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: alice,
            spender: address(vault),
            value: shares,
            nonce: 0,
            deadline: deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);
        vm.prank(bob); // bob should can withdraw for alice
        vault.withdrawWithPermit(
            amountWithdraw,
            shares,
            permit.owner,
            permit.deadline,
            v,
            r,
            s
        );
        assertEq(vault.nonces(alice), 1);
        assertEq(
            vault.totalAssets(),
            totalAssets -
                amountWithdraw -
                _feeToTransfer(_feeOnRaw(amountWithdraw))
        );
        assertEq(asset.balanceOf(alice), amountWithdraw);
        assertEq(vault.balanceOf(alice), aliceShares - shares);
    }

    function testRedeemWithPermit(uint256 amountDeposit) public {
        vm.assume(
            amountDeposit >= 100 * 1e6 &&
                amountDeposit < vault.maxDeposit(alice)
        );
        uint256 deadline = block.timestamp;
        uint256 amountRedeem = (amountDeposit * 1e12) / 2;
        _deposit(amountDeposit, alice);
        uint256 aliceShares = vault.balanceOf(alice);
        uint256 desiredAssets = vault.previewRedeem(amountRedeem);
        uint256 totalAssets = vault.totalAssets();
        SigUtils.Permit memory _permit = SigUtils.Permit({
            owner: alice,
            spender: address(vault),
            value: amountRedeem,
            nonce: 0,
            deadline: deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(_permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);
        vm.prank(bob); // bob should can redeem for alice.
        vault.redeemWithPermit(
            amountRedeem,
            desiredAssets,
            _permit.owner,
            _permit.deadline,
            v,
            r,
            s
        );
        assertEq(
            asset.balanceOf(address(vault)),
            totalAssets -
                desiredAssets -
                _feeToTransfer(_feeOnRaw(desiredAssets))
        );
        assertEq(asset.balanceOf(alice), desiredAssets);
        assertEq(vault.balanceOf(alice), aliceShares - amountRedeem);
    }

    function testDepositSlippageProtection(uint256 amountDeposit) public {
        vm.assume(
            amountDeposit >= vault.minDeposit() &&
                amountDeposit < vault.maxDeposit(alice)
        );
        asset.transfer(alice, amountDeposit);
        vm.prank(alice);
        asset.approve(address(vault), amountDeposit);
        uint256 desirableShares = vault.previewDeposit(amountDeposit);
        // calculate slippage 1%, bps = 100
        uint256 slippage = 100;
        uint256 desirableSharesWithSlippage = desirableShares -
            ((desirableShares * slippage) / 10000);
        _deposit(amountDeposit, bob); // bob trying to front run alice
        uint256 shares = vault.previewDeposit(amountDeposit);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC5143DepositSlippageProtection.selector,
                shares,
                desirableSharesWithSlippage
            )
        );
        vault.deposit(amountDeposit, alice, desirableSharesWithSlippage);
    }

    function testMintSlippageProtection(uint256 amountMint) public {
        vm.assume(
            amountMint >= vault.minMint() && amountMint < vault.maxMint(alice)
        );
        uint256 assets = vault.previewMint(amountMint);
        _mintAssets(alice, assets * 2);
        vm.prank(alice);
        uint256 desirableShares = vault.previewMint(amountMint);
        // calculate slippage 1%, bps = 100
        uint256 slippage = 100;
        uint256 desirableSharesWithSlippage = desirableShares -
            ((desirableShares * slippage) / 10000);
        _mint(amountMint, bob); // bob trying to front run alice
        uint256 shares = vault.previewMint(amountMint);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC5143MintSlippageProtection.selector,
                shares,
                desirableSharesWithSlippage
            )
        );
        vm.prank(alice);
        vault.mint(amountMint, alice, desirableSharesWithSlippage);
    }

    function testRedeemSlippageProtection() public {
        uint256 amountDeposit = 100 * 1e6;
        _deposit(amountDeposit, alice);
        _deposit(amountDeposit * 100, bob);
        uint256 amountRedeem = vault.maxRedeem(alice);
        uint256 desirableAssets = vault.previewRedeem(amountRedeem);
        console.log("maxRedeem", amountRedeem);
        console.log("desirableAssets", desirableAssets);
        // calculate slippage 10%, bps = 100
        uint256 slippage = 1000;
        uint256 desirableAssetsWithSlippage = desirableAssets -
            ((desirableAssets * slippage) / 10000);
        _withdraw(vault.maxWithdraw(bob), bob); // bob trying to front run alice
        vm.startPrank(alice);
        // vm.expectRevert("ERC5143: redeem slippage protection");
        uint256 assets = vault.redeem(
            amountRedeem,
            alice,
            alice,
            desirableAssetsWithSlippage
        );
        vm.stopPrank();
        console.log("assets", assets);
    }

    function testExpectEmitExchangeRateUpdated() public {
        uint256 amountDeposit = 100 * 1e6;
        _mintAssets(alice, amountDeposit);
        vm.startPrank(alice);
        uint256 shares = vault.previewDeposit(amountDeposit);
        vm.expectEmit(false, false, false, false);
        emit ExchangeRateUpdated(1000000, 1);
        vault.deposit(amountDeposit, alice, shares);
        vm.stopPrank();
    }

    function _mintAssets(address to, uint256 amount) internal {
        asset.transfer(to, amount);
        vm.startPrank(to);
        asset.approve(address(vault), amount);
        vm.stopPrank();
    }

    function _deposit(
        uint256 amount,
        address user
    ) internal returns (uint256 shares) {
        _mintAssets(user, amount);
        vm.startPrank(user);
        shares = vault.previewDeposit(amount);
        console.log("previewDeposit", user, amount, shares);
        vault.deposit(amount, user, shares);
        vm.stopPrank();
    }

    function _withdraw(
        uint256 amount,
        address user
    ) internal returns (uint256 shares) {
        vm.startPrank(user);
        // console.log("maxWithdraw", amount, vault.maxWithdraw(user));
        shares = vault.previewWithdraw(amount);
        console.log("previewWithdraw", user, amount, shares);
        vault.withdraw(amount, user, user, shares);
        vm.stopPrank();
    }

    function _redeem(
        uint256 shares,
        address user
    ) internal returns (uint256 assets) {
        vm.startPrank(user);
        console.log("maxRedeem", vault.maxRedeem(user));
        assets = vault.previewRedeem(shares);
        console.log("previewRedeem", shares, assets);
        vault.redeem(shares, user, user, assets);
        vm.stopPrank();
    }

    function _mint(
        uint256 amount,
        address user
    ) internal returns (uint256 assets) {
        assets = vault.previewMint(amount);
        _mintAssets(user, assets);
        vm.startPrank(user);
        console.log("previewMint", amount, assets);
        vault.mint(amount, user, assets);
        vm.stopPrank();
    }

    function _feeOnRaw(uint256 assets) private pure returns (uint256) {
        return
            assets.mulDiv(
                _feeBasePoint,
                _BASIS_POINT_SCALE,
                Math.Rounding.Ceil
            );
    }

    function _feeOnTotal(uint256 assets) private pure returns (uint256) {
        uint256 feeBasePoint = _feeBasePoint;
        return
            assets.mulDiv(
                feeBasePoint,
                feeBasePoint + _BASIS_POINT_SCALE,
                Math.Rounding.Ceil
            );
    }

    function _feeToTransfer(uint256 assets) private pure returns (uint256) {
        return
            assets.mulDiv(
                _feeToTransferBasePoint,
                _BASIS_POINT_SCALE,
                Math.Rounding.Ceil
            );
    }
}
