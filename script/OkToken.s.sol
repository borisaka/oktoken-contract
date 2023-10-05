// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {OkTokenVault} from "../src/OkTokenVault.sol";
import {TetherToken} from "../src/utils/USDT.sol";

address constant feeRecipient = 0xdb1F09794F45cdc2A1Fd877e1e46808ffC71F72E;
address constant assetAddress = 0x96a29905AeBa57B5E8516C6d21411802dAeA84f2;

contract OkTokenScript is Script {
    function setUp() public {}

    function run() public returns (OkTokenVault token) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        token = new OkTokenVault(assetAddress, feeRecipient);
        vm.stopBroadcast();
    }
}
