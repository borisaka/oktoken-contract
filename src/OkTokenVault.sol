// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ERC20Permit} from "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import {ERC4626} from "openzeppelin/token/ERC20/extensions/ERC4626.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";
import {ERC4626Fees} from "./ERC4626Fees.sol";

contract OkTokenVault is ERC20, ERC4626, ERC4626Fees, ERC20Permit, Ownable {
    using Math for uint256;

    address private immutable feeRecipientAddress;

    constructor(address _assetAddress, address _feeRecipientAddress)
        ERC20("OkToken", "OKT")
        ERC4626(IERC20(_assetAddress))
        ERC20Permit("OkToken")
        Ownable(msg.sender)
    {
        feeRecipientAddress = _feeRecipientAddress;
    }

    function previewDeposit(uint256 assets) public view override(ERC4626Fees, ERC4626) returns (uint256) {
        return super.previewDeposit(assets);
    }

    function previewMint(uint256 shares) public view override(ERC4626Fees, ERC4626) returns (uint256) {
        return super.previewMint(shares);
    }

    function previewWithdraw(uint256 assets) public view override(ERC4626Fees, ERC4626) returns (uint256) {
        return super.previewWithdraw(assets);
    }

    function previewRedeem(uint256 shares) public view override(ERC4626Fees, ERC4626) returns (uint256) {
        return super.previewRedeem(shares);
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
        internal
        override(ERC4626Fees, ERC4626)
    {
        return super._deposit(caller, receiver, assets, shares);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override(ERC4626Fees, ERC4626)
    {
        return super._withdraw(caller, receiver, owner, assets, shares);
    }

    function _feeBasePoint() internal pure override(ERC4626Fees) returns (uint256) {
        return 10_000;
    }

    function _feeRecipient() internal view override(ERC4626Fees) returns (address) {
        return feeRecipientAddress;
    }

    function decimals() public view virtual override(ERC20, ERC4626) returns (uint8) {
        return super.decimals();
    }

    function _decimalsOffset() internal view virtual override(ERC4626) returns (uint8) {
        return 12;
    }

    // function _convertToShares(uint256 assets, Math.Rounding rounding)
    //     internal
    //     view
    //     virtual
    //     override(ERC4626)
    //     returns (uint256)
    // {
    //     uint256 _totalAssets = totalAssets() == 0 ? totalAssets() : 1e6;
    //     return assets.mulDiv(_totalAssets * 10 ** 6, totalSupply() + 1, rounding);
    // }

    // function _convertToAssets(uint256 shares, Math.Rounding rounding)
    //     internal
    //     view
    //     virtual
    //     override(ERC4626)
    //     returns (uint256)
    // {
    //     uint256 _totalAssets = totalAssets() == 0 ? totalAssets() : 1e6;
    //     return shares.mulDiv(_totalAssets, totalSupply() + 10 ** _decimalsOffset(), rounding);
    // }
}
