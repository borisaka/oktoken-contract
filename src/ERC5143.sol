// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

error ERC5143DepositSlippageProtection(uint256 shares, uint256 minShares);
error ERC5143MintSlippageProtection(uint256 assets, uint256 maxAssets);
error ERC5143WithdrawSlippageProtection(uint256 shares, uint256 maxShares);
error ERC5143RedeemSlippageProtection(uint256 assets, uint256 minAssets);

abstract contract ERC5143 is ERC4626 {
    function deposit(uint256 assets, address receiver, uint256 minShares) public virtual returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);
        if (shares < minShares) {
            revert ERC5143DepositSlippageProtection(shares, minShares);
        }
        return shares;
    }

    function mint(uint256 shares, address receiver, uint256 maxAssets) public virtual returns (uint256) {
        uint256 assets = super.mint(shares, receiver);
        if (assets > maxAssets) {
            revert ERC5143MintSlippageProtection(assets, maxAssets);
        }
        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner, uint256 maxShares)
        public
        virtual
        returns (uint256)
    {
        uint256 shares = super.withdraw(assets, receiver, owner);
        if (shares > maxShares) {
            revert ERC5143WithdrawSlippageProtection(shares, maxShares);
        }
        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner, uint256 minAssets)
        public
        virtual
        returns (uint256)
    {
        uint256 assets = super.redeem(shares, receiver, owner);
        if (assets < minAssets) {
            revert ERC5143RedeemSlippageProtection(assets, minAssets);
        }
        return assets;
    }
}
