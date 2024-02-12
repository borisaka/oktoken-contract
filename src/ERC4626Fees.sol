// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ERC4626Fees is ERC4626 {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant _feeBasePoint = 111111111111111111111111111; // 11.11 % fee, business requirement.
    address private immutable _feeRecipient;
    uint256 private constant _BASIS_POINT_SCALE = 1e27; // 100%
    uint256 private constant _feeToTransfer = 3e26; // 30% to fee recipient, 70% hold on vault.

    constructor(address feeRecipient_) {
        require(feeRecipient_ != address(0), "ZERO_ADDRESS");
        _feeRecipient = feeRecipient_;
    }

    /**
     * @dev See {IERC4626-previewDeposit}.
     */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        uint256 fee = _feeOnTotal(assets);
        return super.previewDeposit(assets - fee);
    }

    /**
     * @dev See {IERC4626-previewMint}.
     */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        uint256 assets = super.previewMint(shares);
        return assets + _feeOnRaw(assets);
    }

    /**
     * @dev See {IERC4626-previewWithdraw}.
     */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        uint256 fee = _feeOnRaw(assets);
        return super.previewWithdraw(assets + fee);
    }

    /**
     * @dev See {IERC4626-previewRedeem}.
     */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        uint256 assets = super.previewRedeem(shares);
        return assets - _feeOnTotal(assets);
    }

    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        uint256 assets = super.maxWithdraw(owner);
        return assets - _feeOnRaw(assets);
    }

    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return super.maxRedeem(owner);
    }

    /**
     * @dev See {IERC4626-_deposit}.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual override {
        uint256 fee = _feeOnTotal(assets);
        super._deposit(caller, receiver, assets, shares);

        _transferFee(fee);
    }

    /**
     * @dev See {IERC4626-_deposit}.
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        virtual
        override
    {
        uint256 fee = _feeOnRaw(assets);
        super._withdraw(caller, receiver, owner, assets, shares);

        _transferFee(fee);
    }

    /// @dev Calculates the fees that should be added to an amount `assets` that does not already include fees.
    /// Used in {IERC4626-mint} and {IERC4626-withdraw} operations.
    function _feeOnRaw(uint256 assets) private pure returns (uint256) {
        return assets.mulDiv(_feeBasePoint, _BASIS_POINT_SCALE, Math.Rounding.Floor);
    }

    /// @dev Calculates the fee part of an amount `assets` that already includes fees.
    /// Used in {IERC4626-deposit} and {IERC4626-redeem} operations.
    function _feeOnTotal(uint256 assets) private pure returns (uint256) {
        uint256 feeBasePoint = _feeBasePoint;
        return assets.mulDiv(feeBasePoint, feeBasePoint + _BASIS_POINT_SCALE, Math.Rounding.Floor);
    }

    function _transferFee(uint256 fee) internal virtual {
        address recipient = _feeRecipient;
        if (fee > 0 && recipient != address(this)) {
            uint256 feeToTransfer = fee.mulDiv(_feeToTransfer, _BASIS_POINT_SCALE, Math.Rounding.Floor); // 30% to fee recipient, 70% hold on vault.
            IERC20(asset()).safeTransfer(recipient, feeToTransfer);
        }
    }
}
