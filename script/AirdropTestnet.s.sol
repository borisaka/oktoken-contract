// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Airdrop} from "../src/Airdrop.sol";
// import {TestUSDT} from "../src/test_utils/TestUSDT.sol";

address constant admin = 0x5809D78c0F1F010D2793ae484A20ABFba916D6F2;
address constant asset = 0x369Adbf389FC155F961C1Ff8470AD3576B58c6D7;
// address constant assetAddress = 0x0fba5f964d91A9DE6237011bDd55aeDd575b3502;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address spender, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
}

contract AirdropTestnetScript is Script {
    address vaultAddress;
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // TestUSDT asset;

    // function setUp() public {
    //     VmSafe.Wallet memory wallet = vm.createWallet(deployerPrivateKey);
    //     uint64 nonce = vm.getNonce(wallet.addr);
    //     vaultAddress = vm.computeCreateAddress(wallet.addr, nonce + 1);
    //     // uint256 balance = asset.balanceOf(wallet.addr);
    //     // console.log("balance ", balance);
    // }

    function run() public returns (Airdrop airdrop) {
        vm.startBroadcast(deployerPrivateKey);
        // asset = new TestUSDT();
        // VmSafe.Wallet memory wallet = vm.createWallet(deployerPrivateKey);
        // uint64 nonce = vm.getNonce(wallet.addr);
        // vaultAddress = vm.computeCreateAddress(wallet.addr, nonce + 1);
        // asset.approve(vaultAddress, 1 * 1e6);
        // token = new OkTokenVault(address(asset), feeRecipient);
        airdrop = new Airdrop(asset, admin);
        vm.stopBroadcast();
    }
}
