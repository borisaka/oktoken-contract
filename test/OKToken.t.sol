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
        // (uint256 _initialSupply, string memory _name, string memory _symbol, uint256 _decimals)
        console.log("Msg.sender address: %s", msg.sender);
        asset = new TetherToken(type(uint256).max, "USDT", "USDT", 6);
        asset.transfer(msg.sender, 100000000000000000000 * 1e6);
        uint64 nonce = vm.getNonce(msg.sender);
        address vaultAddress = vm.computeCreateAddress(msg.sender, nonce);
        vm.startPrank(msg.sender);
        console.log("Asset address: %s", address(asset));
        asset.approve(vaultAddress, 100 * 1e6);
        okToken = new OKToken(address(asset), 6, creator);
        console.log("OKToken address: %s", address(okToken));
        // asset.approve(address(okToken), 2 ** 256 - 1);
        // vm.stopPrank();
        // vm.startPrank(alice);
        // vm.stopPrank();
        // asset = TetherToken(0x96a29905AeBa57B5E8516C6d21411802dAeA84f2);
        // vault = OkTokenVault(0xA5481e4298Dfea620Dd664429e52A17461250E94);
        // sigUtils = new SigUtils(vault.DOMAIN_SEPARATOR());

        // asset.transfer(address(vault), 1 * 1e6); // 1 USDT initial deposit
        // uint256 shares = vault.previewDeposit(100 * 1e6);
        // vault.deposit(100 * 1e6, address(this), shares);
        // console.log("Token Vault address: %s", address(vault));
        // console.log("Token Vault decimals: %s", vault.decimals());
    }

    function testInitialValues() public {
        console.log("Rate: %s", okToken.exchangeRate());
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
        asset.transfer(alice, assets);
        vm.startPrank(alice);
        asset.approve(address(okToken), 2 ** 256 - 1);
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
        console.log("CB: %s", asset.balanceOf(creator));
        vm.stopPrank();
        assertEq(withdraw, 10190949);
        assertEq(okToken.totalAssets(), 10494546);
        assertEq(okToken.exchangeRate(), 1444142);
        assertEq(okToken.totalSupply(), 8266972626883245240);
        assertEq(okToken.balanceOf(alice), 0);
        assertEq(asset.balanceOf(alice), 10190949);
        assertEq(asset.balanceOf(creator), 314505);
    }

    // function testPreviewDeposit() public {
    //     uint256 assets = 100 * 1e6;
    //     uint256 fee = okToken._calculateFee(assets);
    //     uint256 shares = okToken.previewDeposit(assets);
    //     console.log("Shares: %s", shares);
    //     assertEq(shares, 100 * 1e6 - fee);
    // }
}
