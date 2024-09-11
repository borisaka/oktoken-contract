// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {TestUSDT} from "../src/test_utils/TestUSDT.sol";

contract OkTokenScript is Script {
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

    function run() public returns (TestUSDT token) {
        vm.startBroadcast(deployerPrivateKey);
        // asset.approve(vaultAddress, 1 * 1e6);
        token = new TestUSDT();
        vm.stopBroadcast();
    }
}
