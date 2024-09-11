// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";
abstract contract ERC4626Fees is ERC4626 {
    using Math for uint256;
    using SafeERC20 for IERC20;
    // 12,359 550 561 797 751 911 %
    // uint256 private constant _feeBasePoint = 123595505617977519910000000; // 12.36 % fee, business requirement.
    // uint256 private constant _feeBasePoint = 120000000001797751990000000; // 12.36 % fee, business requirement.
    uint256 private constant _feeBasePoint = 111111111111111111111111111; // 11.00 % fee, business requirement.
    uint256 private constant _feePercents = 11; // 11.00 % fee, business requirement.
    uint256 private constant _profitPercents = 1; // 1.00 % profit, business requirement.

    address private immutable _feeRecipient;
    uint256 private constant _BASIS_POINT_SCALE = 1e27; // 100%
    uint256 private constant _feeToTransfer = 1e26; // 30% to fee recipient, 70% hold on vault.

    constructor(address feeRecipient_) {
        require(feeRecipient_ != address(0), "ZERO_ADDRESS");
        _feeRecipient = feeRecipient_;
    }

    /**
     * @dev See {IERC4626-previewDeposit}.
     */
    function previewDeposit(
        uint256 assets
    ) public view virtual override returns (uint256) {
        // uint256 fee = _feeOnTotal(assets);
        uint256 fee = _calculateFee(assets);
        return super.previewDeposit(assets - fee);
    }

    /**
     * @dev See {IERC4626-previewMint}.
     */
    // function previewMint(
    //     uint256 shares
    // ) public view virtual override returns (uint256) {
    //     uint256 assets = super.previewMint(shares);
    //     uint256 fee = assets.ceilDiv(100) * _feePercents;
    //     // return assets + _feeOnRaw(assets);
    // }

    /**
     * @dev See {IERC4626-previewWithdraw}.
     */
    function previewWithdraw(
        uint256 assets
    ) public view virtual override returns (uint256) {
        uint256 fee = _calculateFee(assets);
        return super.previewWithdraw(assets + fee);
    }

    /**
     * @dev See {IERC4626-previewRedeem}.
     */
    function previewRedeem(
        uint256 shares
    ) public view virtual override returns (uint256) {
        uint256 assets = super.previewRedeem(shares);
        // console.log("%s", assets.mulDiv(_feePercents, 100, Math.Rounding.Ceil));
        console.log("assets %s, fee %s", assets, _calculateFee(assets));
        return assets - _calculateFee(assets);
    }

    function maxWithdraw(
        address owner
    ) public view virtual override returns (uint256) {
        uint256 assets = super.maxWithdraw(owner);
        return assets - _calculateFee(assets);
    }

    function maxRedeem(
        address owner
    ) public view virtual override returns (uint256) {
        return super.maxRedeem(owner);
    }

    /**
     * @dev See {IERC4626-_deposit}.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        // uint256 fee = _feeOnTotal(assets);
        super._deposit(caller, receiver, assets, shares);
        //  SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        // _mint(receiver, shares);

        // emit Deposit(caller, receiver, assets, shares);
        _transferFee(assets);
    }

    /**
     * @dev See {IERC4626-_deposit}.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        uint256 fee = _calculateFee(assets);
        console.log("WD %s %s", assets, fee);
        super._withdraw(caller, receiver, owner, assets, shares);

        _transferFee(fee);
    }

    // function _redeem()

    function _calculateFee(
        uint256 assets
    ) internal view virtual returns (uint256) {
        return assets.mulDiv(_feePercents, 100, Math.Rounding.Ceil);
        // return assets.ceilDiv(100) * _feePercents;
    }

    /// @dev Calculates the fees that should be added to an amount `assets` that does not already include fees.
    /// Used in {IERC4626-mint} and {IERC4626-withdraw} operations.
    // function _feeOnRaw(uint256 assets) private pure returns (uint256) {
    //     // return
    //     //     assets.mulDiv(
    //     //         _feeBasePoint,
    //     //         _BASIS_POINT_SCALE,
    //     //         Math.Rounding.Ceil
    //     //     );
    //     // return asыsets * (_feeBasePoint.ceilDiv(100));
    //     return
    //         assets.mulDiv(
    //             _feeBasePoint,
    //             _BASIS_POINT_SCALE,
    //             Math.Rounding.Ceil
    //         );
    // }

    /// @dev Calculates the fee part of an amount `assets` that already includes fees.
    /// Used in {IERC4626-deposit} and {IERC4626-redeem} operations.
    // function _feeOnTotal(uint256 assets) private pure returns (uint256) {
    //     // return
    //     //     assets.mulDiv(
    //     //         _feeBasePoint,
    //     //         _BASIS_POINT_SCALE,
    //     //         Math.Rounding.Ceil
    //     // );
    //     // return assets * (_feeBasePoint.ceilDiv(100));
    //     uint256 feeBasePoint = _feeBasePoint;
    //     return
    //         assets.mulDiv(feeBasePoint, _BASIS_POINT_SCALE, Math.Rounding.Ceil);
    // }

    function _transferFee(uint256 assets) internal virtual {
        // uint256 feeToTransfer = assets.ceilDiv(100) * _profitPercents;
        uint256 feeToTransfer = assets.mulDiv(
            _profitPercents,
            100,
            Math.Rounding.Ceil
        );
        console.log("feeToTransfer", feeToTransfer);
        IERC20(asset()).safeTransfer(_feeRecipient, feeToTransfer);
    }

    // function _transferFee(uint256 fee) internal virtual {
    //     address recipient = _feeRecipient;
    //     if (fee > 0 && recipient != address(this)) {
    //         uint256 feeToTransfer = fee.mulDiv(
    //             _feeToTransfer,
    //             _BASIS_POINT_SCALE,
    //             Math.Rounding.Ceil
    //         ); // 30% to fee recipient, 70% hold on vault.
    //         IERC20(asset()).safeTransfer(recipient, feeToTransfer);
    //     }
    // }
}
