// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {OkTokenVault} from "../src/OkTokenVault.sol";
import {TetherToken} from "../src/utils/USDT.sol";

address constant feeRecipient = 0xdb1F09794F45cdc2A1Fd877e1e46808ffC71F72E;
address constant assetAddress = 0x9fD9c17a844edE9A52F63D18a533d4eD3f60F8d4;

contract OkTokenScript is Script {
    function setUp() public {}

    function run() public returns (OkTokenVault token) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        token = new OkTokenVault(assetAddress, feeRecipient);
        vm.stopBroadcast();
    }
}
