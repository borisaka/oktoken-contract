// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC4626Fees} from "./ERC4626Fees.sol";
import {ERC5143} from "./ERC5143.sol";

error MinimumDeposit(uint256 deposit, uint256 minDeposit);
error MinimumMint(uint256 mint, uint256 minMint);
error MinimumWithdraw(uint256 withdraw, uint256 minWithdraw);
error MinimumRedeem(uint256 redeem, uint256 minRedeem);

contract OkTokenVault is ERC20, ERC4626, ERC5143, ERC4626Fees, ERC20Permit {
    using Math for uint256;

    uint8 private constant _OFFSET = 12; // 18 - 6
    uint256 private constant MINIMUM_DEPOSIT = 100 * 1e6; // 100 USDT
    uint256 private constant MINIMUM_WITHDRAW = 10 * 1e6; // 10 USDT

    struct WithdrawParams {
        uint256 assets;
        uint256 fee;
    }

    event ExchangeRateUpdated(uint256 rate, uint256 timestamp);

    constructor(address assetAddress, address feeRecipient)
        ERC20("OkToken", "OKT")
        ERC4626(IERC20(assetAddress))
        ERC4626Fees(feeRecipient, 1000) // 10%
        ERC20Permit("OkToken")
    {}

    function previewDeposit(uint256 assets) public view override(ERC4626Fees, ERC4626) returns (uint256 shares) {
        if (assets < MINIMUM_DEPOSIT) {
            revert MinimumDeposit(assets, MINIMUM_DEPOSIT);
        }
        return super.previewDeposit(assets);
    }

    function previewMint(uint256 shares) public view override(ERC4626Fees, ERC4626) returns (uint256 assets) {
        assets = super.previewMint(shares);
        if (assets < minDeposit()) {
            revert MinimumMint(shares, minMint());
        }
        return assets;
    }

    function previewWithdraw(uint256 assets) public view override(ERC4626Fees, ERC4626) returns (uint256 shares) {
        if (assets < minWithdraw()) {
            revert MinimumWithdraw(assets, minWithdraw());
        }
        return super.previewWithdraw(assets);
    }

    function previewRedeem(uint256 shares) public view override(ERC4626Fees, ERC4626) returns (uint256 assets) {
        assets = super.previewRedeem(shares);
        if (assets < MINIMUM_WITHDRAW) {
            revert MinimumRedeem(shares, minRedeem());
        }
        return assets;
    }

    function maxWithdraw(address owner) public view override(ERC4626Fees, ERC4626) returns (uint256) {
        return super.maxWithdraw(owner);
    }

    function maxRedeem(address owner) public view override(ERC4626Fees, ERC4626) returns (uint256) {
        return super.maxRedeem(owner);
    }

    function minWithdraw() public pure returns (uint256) {
        return MINIMUM_WITHDRAW;
    }

    function minDeposit() public pure returns (uint256) {
        return MINIMUM_DEPOSIT;
    }

    function minRedeem() public view returns (uint256) {
        return previewWithdraw(MINIMUM_WITHDRAW);
    }

    function minMint() public view returns (uint256) {
        return previewDeposit(MINIMUM_DEPOSIT);
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
        return convertToAssets(1 ether);
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
        internal
        override(ERC4626Fees, ERC4626)
    {
        super._deposit(caller, receiver, assets, shares);
        emit ExchangeRateUpdated(exchangeRate(), block.timestamp);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override(ERC4626Fees, ERC4626)
    {
        super._withdraw(caller, receiver, owner, assets, shares);
        emit ExchangeRateUpdated(exchangeRate(), block.timestamp);
    }

    function decimals() public view virtual override(ERC20, ERC4626) returns (uint8) {
        return super.decimals();
    }

    function _decimalsOffset() internal view virtual override(ERC4626) returns (uint8) {
        return _OFFSET;
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
        uint256 total = totalAssets();
        if (total > 0 && supply == 0) {
            return assets.mulDiv(1e18, totalAssets(), rounding);
        }
        return assets.mulDiv(supply + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
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
        uint256 assets = totalAssets();
        if (assets > 0 && supply == 0) {
            return shares.mulDiv(assets, 1e18, rounding);
        }
        return shares.mulDiv(assets + 1, supply + 10 ** _decimalsOffset(), rounding);
    }
}
