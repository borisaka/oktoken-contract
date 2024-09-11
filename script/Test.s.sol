// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;
import {Script, console} from "forge-std/Script.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract Test is Script {
    using Math for uint256;
    function md(uint256 assets, uint256 supply) public view returns (uint256) {
        uint256 result = Math.mulDiv(1, assets, 1);
        console.log(result);
        return result;
    }
    function run() public {
        md(1, 1);
        // md(10, );
        // console.log1.mulDiv(1, 1);
        // console.log(Math.mulDiv(1, 1, 1));
        // console.log(Math.mulDiv(2, 1, 1));
        // console.log(Math.mulDiv(2, 2, 1));
        // console.log(Math.mulDiv(4, 2, 1));
    }
}
