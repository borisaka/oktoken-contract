// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {OKToken} from "../src/OKToken.sol";
// Mainnet
address constant feeRecipient = 0x2396F951f87B5B2D9e591270567eeC3593DECECC;
address constant assetAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

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
        uint64 nonce = vm.getNonce(wallet);
        console.log("balance ", wallet.addr.balance);
        vaultAddress = vm.computeCreateAddress(wallet.addr, nonce + 1);
    }

    function run() public returns (OKToken token) {
        vm.startBroadcast(deployerPrivateKey);
        asset.approve(vaultAddress, 1 * 1e6);
        token = new OKToken(assetAddress, 6, feeRecipient);
        vm.stopBroadcast();
    }
}
