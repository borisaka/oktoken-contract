// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {OkTokenVault} from "../src/OkTokenVault.sol";
import {USDAsset} from "../test/USDAsset.sol";

address constant assetAddress = address(1);

contract OkTokenScript is Script {
    function setUp() public {}

    function run() public returns (OkTokenVault token, USDAsset asset) {
        vm.startBroadcast();
        asset = new USDAsset();
        token = new OkTokenVault(address(asset), assetAddress);
        vm.stopBroadcast();
    }
}
