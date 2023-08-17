// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./OkToken.sol";
import "forge-std/Console.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract OKVault is ReentrancyGuard {
    IERC20 public usdtContract;
    OkToken public okTokenContract;

    address public immutable creatorAddress;

    uint256 public constant feePercentage = 10;
    uint256 public exchangeRate = 1e6;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    using Strings for uint256;

    constructor(address _usdtAddress, address _okTokenAddress, address _creatorAddress) {
        usdtContract = IERC20(_usdtAddress);
        okTokenContract = OkToken(_okTokenAddress);
        creatorAddress = _creatorAddress;
        exchangeRate = getRate();
    }

    function getRate() public view returns (uint256 rate) {
        uint256 usdtBalance = usdtContract.balanceOf(address(this));
        uint256 totalSupply = okTokenContract.totalSupply();
        rate = 1e6;
        console.log("usdtBalance: %s", usdtBalance.toString());
        console.log("totalSupply: %s", totalSupply.toString());
        if (totalSupply != 0 || usdtBalance != 0) {
            rate = (usdtBalance * 1e18) / totalSupply;
        }
        console.log("rate: %s", rate.toString());
    }

    function deposit(uint256 amount) public nonReentrant {
        require(amount >= 5 * 1e6, "Amount must be greater than 5 usdt");

        uint256 fee = ((amount * feePercentage) / 100);
        uint256 userAmount = amount - fee;
        console.log("fee: %s", fee.toString());
        console.log("userAmount: %s", userAmount.toString());
        usdtContract.transferFrom(msg.sender, address(this), amount);
        usdtContract.transfer(creatorAddress, fee / 2);

        uint256 okTokensToMint = (userAmount * 1e18) / exchangeRate;
        okTokenContract.mint(msg.sender, okTokensToMint);
        // update exchange rate after minting
        exchangeRate = getRate();

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        require(amount >= 5 * 1e6, "Amount must be greater than 5 usdt");
        uint256 usdtAmount = (amount * exchangeRate) / 1e18;
        uint256 fee = (usdtAmount * feePercentage) / 100;
        uint256 usdtAmountToTransfer = usdtAmount - fee;

        usdtContract.transfer(creatorAddress, fee / 2);
        usdtContract.transfer(msg.sender, usdtAmountToTransfer);

        okTokenContract.burn(msg.sender, amount);

        exchangeRate = getRate();

        emit Withdraw(msg.sender, amount);
    }
}
