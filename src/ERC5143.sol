// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

abstract contract ERC5143 is ERC4626 {
    function deposit(uint256 assets, address receiver, uint256 minShares) public virtual returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);
        require(shares >= minShares, "ERC5143: deposit slippage protection");
        return shares;
    }

    function mint(uint256 shares, address receiver, uint256 maxAssets) public virtual returns (uint256) {
        uint256 assets = super.mint(shares, receiver);
        require(assets <= maxAssets, "ERC5143: mint slippage protection");
        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner, uint256 maxShares)
        public
        virtual
        returns (uint256)
    {
        uint256 shares = super.withdraw(assets, receiver, owner);
        require(shares <= maxShares, "ERC5143: withdraw slippage protection");
        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner, uint256 minAssets)
        public
        virtual
        returns (uint256)
    {
        uint256 assets = super.redeem(shares, receiver, owner);
        require(assets >= minAssets, "ERC5143: redeem slippage protection");
        return assets;
    }
}
