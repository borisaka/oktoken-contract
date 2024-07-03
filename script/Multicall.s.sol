// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Multicall3} from "../src/Multicall3.sol";

contract MulticallScript is Script {
    address vaultAddress;
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // IERC20 asset = IERC20(assetAddress);

    // function setUp() public {
    // VmSafe.Wallet memory wallet = vm.createWallet(deployerPrivateKey);
    // uint64 nonce = vm.getNonce(wallet.addr);
    // vaultAddress = vm.computeCreateAddress(wallet.addr, nonce + 1);
    // uint256 balance = asset.balanceOf(wallet.addr);
    // console.log("balance ", balance);
    // }

    function run() public returns (Multicall3 cls) {
        vm.startBroadcast(deployerPrivateKey);
        // asset.approve(vaultAddress, 1 * 1e6);
        cls = new Multicall3();
        vm.stopBroadcast();
    }
}
