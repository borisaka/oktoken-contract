// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {OkToken} from "./OkToken.sol";

contract OkVault is ReentrancyGuard {
    IERC20 private immutable _usdtContract;
    OkToken private immutable _okTokenContract;

    address private immutable _creatorAddress;
    uint96 public constant FEE_PERCENTAGE = 10;

    uint256 public constant MINIMUM_AMOUNT = 5 * 1e6; // 5 USDT

    uint256 public exchangeRate = 1e6;

    event Deposit(address indexed user, uint256 amount, uint256 newRate);
    event Withdraw(address indexed user, uint256 amount, uint256 newRate);

    constructor(address _usdtAddress, address creatorAddress) {
        _okTokenContract = new OkToken();
        _usdtContract = IERC20(_usdtAddress);
        _creatorAddress = creatorAddress;
        exchangeRate = getRate();
    }

    // modifier that sender should have non 0 balance
    modifier nonZeroBalance() {
        require(_usdtContract.balanceOf(msg.sender) >= 0, "Insufficient balance");
        _;
    }

    modifier minimumAmount(uint256 amount) {
        require(amount >= MINIMUM_AMOUNT, "Amount must be greater than 5");
        _;
    }

    function getOkTokenAddress() public view returns (address) {
        return address(_okTokenContract);
    }

    function getRate() public view returns (uint256 rate) {
        uint256 usdtBalance = _usdtContract.balanceOf(address(this));
        uint256 totalSupply = _totalSupply();
        if (totalSupply == 0) {
            return 1e6;
        }
        rate = (usdtBalance * 1e18) / totalSupply;
    }

    function deposit(uint256 amount) external minimumAmount(amount) nonZeroBalance nonReentrant {
        uint256 fee = ((amount * FEE_PERCENTAGE) / 100);
        uint256 userAmount = amount - fee;
        // transfer usdt from user to vault
        require(_usdtContract.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        // transfer fee, 5% to creator and 5% to vault
        require(_usdtContract.transfer(_creatorAddress, fee / 2), "Transfer failed");
        // calculate okTokens to mint
        uint256 okTokensToMint = (userAmount * 1e18) / exchangeRate;
        // mint okTokens to user
        _okTokenContract.mint(msg.sender, okTokensToMint);
        // update exchange rate after minting
        exchangeRate = getRate();

        emit Deposit(msg.sender, amount, exchangeRate);
    }

    function withdraw(uint256 amount) external minimumAmount(amount) nonReentrant {
        require(_okTokenContract.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(_totalSupply() >= amount, "Insufficient total supply");

        uint256 usdtAmount = amount * exchangeRate / 1e18;
        uint256 fee = usdtAmount * FEE_PERCENTAGE / 100;
        uint256 usdtAmountToTransfer = usdtAmount - fee;

        require(_usdtContract.transfer(_creatorAddress, fee / 2), "Transfer failed");
        require(_usdtContract.transfer(msg.sender, usdtAmountToTransfer), "Transfer failed");
        _okTokenContract.burn(msg.sender, amount);
        exchangeRate = getRate();

        emit Withdraw(msg.sender, amount, exchangeRate);
    }

    function _totalSupply() internal view returns (uint256) {
        return _okTokenContract.totalSupply();
    }
}
