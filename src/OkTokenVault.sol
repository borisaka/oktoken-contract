// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20Permit} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC4626} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {ERC4626Fees} from "./ERC4626Fees.sol";
import "forge-std/Test.sol";

contract OkTokenVault is ERC20, ERC4626, ERC4626Fees, ERC20Permit {
    using Math for uint256;

    uint8 private constant _offset = 12; // 18 - 6
    uint256 private constant MINIMUM_DEPOSIT = 100 * 1e6; // 100 USDT
    uint256 private constant MINIMUM_WITHDRAW = 10 * 1e6; // 10 USDT

    struct WithdrawParams {
        uint256 assets;
        uint256 fee;
    }

    constructor(address _assetAddress, address _feeRecipient)
        ERC20("OkToken", "OKT")
        ERC4626(IERC20(_assetAddress))
        ERC4626Fees(_feeRecipient, 1000) // 10%
        ERC20Permit("OkToken")
    {}

    function previewDeposit(uint256 assets) public view override(ERC4626Fees, ERC4626) returns (uint256) {
        require(assets >= MINIMUM_DEPOSIT, "minimum deposit");
        return super.previewDeposit(assets);
    }

    function previewMint(uint256 shares) public view override(ERC4626Fees, ERC4626) returns (uint256) {
        uint256 assets = super.previewMint(shares);
        require(assets >= MINIMUM_DEPOSIT, "minimum deposit");
        return assets;
    }

    function previewWithdraw(uint256 assets) public view override(ERC4626Fees, ERC4626) returns (uint256) {
        require(assets >= MINIMUM_WITHDRAW, "minimum withdraw");
        return super.previewWithdraw(assets);
    }

    function previewRedeem(uint256 shares) public view override(ERC4626Fees, ERC4626) returns (uint256) {
        require(shares >= MINIMUM_WITHDRAW, "minimum withdraw");
        return super.previewRedeem(shares);
    }

    function withdrawWithPermit(uint256 assets, address owner, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        returns (uint256)
    {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        console.log("shares", shares);
        permit(owner, address(this), shares, deadline, v, r, s);
        _withdraw(address(this), owner, owner, assets, shares);
        return shares;
    }

    function redeemWithPermit(uint256 shares, address owner, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        returns (uint256)
    {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);
        permit(owner, address(this), shares, deadline, v, r, s);
        _withdraw(address(this), owner, owner, assets, shares);

        return assets;
    }

    function exchangeRate() public view returns (uint256 rate) {
        return _convertToAssets(1e18, Math.Rounding.Floor);
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

    function decimals() public view virtual override(ERC20, ERC4626) returns (uint8) {
        return super.decimals();
    }

    function _decimalsOffset() internal view virtual override(ERC4626) returns (uint8) {
        return _offset;
    }
    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */

    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        virtual
        override(ERC4626)
        returns (uint256)
    {
        uint256 supply = totalSupply();
        uint256 _totalAssets = totalAssets();
        return (supply == 0 && _totalAssets > 0)
            ? _totalAssets * 10 ** _offset
            : assets.mulDiv(supply + 10 ** _offset, _totalAssets + 1, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        virtual
        override(ERC4626)
        returns (uint256)
    {
        uint256 supply = totalSupply();
        return supply == 0
            ? shares.mulDiv(1, 10 ** _offset, rounding)
            : shares.mulDiv(totalAssets() + 1, supply + 10 ** _offset, rounding);
    }
}
