// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {OkToken} from "./OkToken.sol";

contract OkVault is ReentrancyGuard {
    IERC20 private _usdtContract;
    OkToken private _okTokenContract;

    address private immutable _creatorAddress;

    uint256 public constant FEE_PERCENTAGE = 10;
    uint256 public exchangeRate = 1e6;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _usdtAddress, address creatorAddress) {
        _okTokenContract = new OkToken(address(this));
        _usdtContract = IERC20(_usdtAddress);
        _creatorAddress = creatorAddress;
        exchangeRate = getRate();
    }

    function getOkTokenAddress() public view returns (address) {
        return address(_okTokenContract);
    }

    function getRate() public view returns (uint256 rate) {
        uint256 usdtBalance = _usdtContract.balanceOf(address(this));
        uint256 totalSupply = _totalSupply();
        rate = 1e6;
        if (totalSupply != 0 || usdtBalance != 0) {
            rate = (usdtBalance * 1e18) / totalSupply;
        }
    }

    function deposit(uint256 amount) external nonReentrant {
        require(amount >= 5 * 1e6, "Amount must be greater than 5 usdt");
        require(_usdtContract.balanceOf(msg.sender) >= amount, "Insufficient balance");

        uint256 fee = ((amount * FEE_PERCENTAGE) / 100);
        uint256 userAmount = amount - fee;
        // transfer usdt from user to vault
        _usdtContract.transferFrom(msg.sender, address(this), amount);
        // transfer fee, 5% to creator and 5% to vault  
        _usdtContract.transfer(_creatorAddress, fee / 2);
        // calculate okTokens to mint
        uint256 okTokensToMint = (userAmount * 1e18) / exchangeRate;
        // mint okTokens to user
        _okTokenContract.mint(msg.sender, okTokensToMint);
        // update exchange rate after minting
        exchangeRate = getRate();

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount >= 5 * 1e6, "Amount must be greater than 5 usdt");
        require(_okTokenContract.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(_totalSupply() >= amount, "Insufficient total supply");

        uint256 usdtAmount = (amount * exchangeRate) / 1e18;
        uint256 fee = (usdtAmount * FEE_PERCENTAGE) / 100;
        uint256 usdtAmountToTransfer = usdtAmount - fee;

        _usdtContract.transfer(_creatorAddress, fee / 2);
        _usdtContract.transfer(msg.sender, usdtAmountToTransfer);

        _okTokenContract.burn(msg.sender, amount);

        exchangeRate = getRate();

        emit Withdraw(msg.sender, amount);
    }

    function _totalSupply() internal view returns (uint256) {
        return _okTokenContract.totalSupply();
    }
}
