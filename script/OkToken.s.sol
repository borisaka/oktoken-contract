// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {OkTokenVault} from "../src/OkTokenVault.sol";

address constant feeRecipient = 0xdb1F09794F45cdc2A1Fd877e1e46808ffC71F72E;
address constant assetAddress = 0x96a29905AeBa57B5E8516C6d21411802dAeA84f2;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address spender, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
}

contract OkTokenScript is Script {
    address vaultAddress;
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    IERC20 asset = IERC20(assetAddress);

    function setUp() public {
        VmSafe.Wallet memory wallet = vm.createWallet(deployerPrivateKey);
        uint64 nonce = vm.getNonce(wallet.addr);
        vaultAddress = vm.computeCreateAddress(wallet.addr, nonce + 1);
        uint256 balance = asset.balanceOf(wallet.addr);
        console.log("balance ", balance);
    }

    function run() public returns (OkTokenVault token) {
        vm.startBroadcast(deployerPrivateKey);
        asset.approve(vaultAddress, 1 * 1e6);
        token = new OkTokenVault(assetAddress, feeRecipient);
        vm.stopBroadcast();
    }
}
