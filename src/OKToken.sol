// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
// import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20, IERC20Metadata, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract OKToken is ERC20 {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint8 private constant _ORDER_STATUS_PENDING = 0;
    uint8 private constant _ORDER_STATUS_CLOSED = 1;
    uint8 private constant _ORDER_STATUS_LIQUIDATED = 2;

    uint256 private constant _MIN_DEPOSIT = 10e6; // 10 USDT
    uint256 private constant _MAX_DEPOSIT = 200_000e6; // 200k USDT
    uint256 private constant _LIQUIDATION_POINT = 145; //145% of deposit amount

    uint256 private constant _feePercents = 11; // 11.00 % fee, business requirement.
    uint256 private constant _profitPercents = 1; // 1.00 % profit, business requirement.

    struct OKDeposit {
        uint256 startWithAssets;
        uint256 shares;
        uint8 status;
        address owner;
    }

    event Deposit(
        bytes32 id,
        address indexed owner,
        uint256 assets,
        uint256 shares,
        uint256 maxAssets
    );
    event Withdraw(
        bytes32 id,
        address indexed owner,
        uint256 assets,
        uint256 shares,
        uint8 status
    );

    event ExchangeRateUpdated(uint256 rate, uint256 timestamp);

    address private immutable _assetAddress;
    uint8 private immutable _assetDecimals;
    uint8 private immutable _assetDecimalsOffset;

    address private immutable _feeRecipient;

    // Only asset known as deposit will influence of course and whole contract economy
    uint256 private _totalAssets = 0;

    mapping(bytes32 => OKDeposit) private _deposits;

    /**
     * @dev Constructor function
     */
    constructor(
        address assetAddress,
        uint8 assetDecimals,
        address feeRecipient
    ) ERC20("OKToken", "OKT") {
        require(assetAddress != address(0), "ZERO_ADDRESS");
        require(feeRecipient != address(0), "ZERO_ADDRESS");
        _assetAddress = assetAddress;
        _assetDecimals = assetDecimals;
        _assetDecimalsOffset = decimals() - assetDecimals;
        _feeRecipient = feeRecipient;
        uint256 inititalDeposit = 1;
        // mint 1 OKT to contract address
        _mint(address(this), inititalDeposit * 1e18);
        // transfer 1 USDT from msg.sender to contract address
        // ensure msg.sender has enough USDT and approved this contract to spend 1 USDT
        IERC20(assetAddress).safeTransferFrom(
            msg.sender,
            address(this),
            inititalDeposit * 1e6
        );
        _totalAssets = inititalDeposit * 1e6;
    }

    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        revert("TRANSFER_FORBIDDEN");
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        revert("TRANSFER_FORBIDDEN");
    }

    function asset() external view returns (address assetTokenAddress) {
        return _assetAddress;
    }

    function exchangeRate() public view returns (uint256 rate) {
        return convertToAssets(1 ether);
    }

    function convertToShares(
        uint256 assets
    ) public view returns (uint256 shares) {
        uint256 totalSupply = totalSupply();
        if (totalSupply > 1 ether) {
            totalSupply -= 1 ether;
        }
        return
            assets.mulDiv(
                totalSupply + 10 ** _assetDecimalsOffset,
                _totalAssets + 1
            );
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (totalSupply > 1 ether) {
            totalSupply -= 1 ether;
        }
        return
            shares.mulDiv(
                _totalAssets + 1,
                totalSupply + 10 ** _assetDecimalsOffset
            );
    }

    function totalAssets() external view returns (uint256) {
        return _totalAssets;
    }

    function maxDeposit() external view returns (uint256) {
        if (_totalAssets >= _MAX_DEPOSIT) {
            return _MAX_DEPOSIT;
        }
        if (_totalAssets <= _MIN_DEPOSIT) {
            return _MIN_DEPOSIT;
        }
        return _totalAssets;
    }

    function showDeposit(bytes32 id) external view returns (OKDeposit memory) {
        return _deposits[id];
    }

    function previewDeposit(uint256 assets) external view returns (uint256) {
        uint256 fee = _calculateFee(assets);
        return this.convertToShares(assets - fee);
    }

    // revert if shares less than minShares
    function deposit(
        uint256 assets,
        uint256 minShares
    ) external returns (uint256, bytes32) {
        uint256 shares = this.convertToShares(assets);
        require(shares >= minShares, "MIN_SHARES");
        return this.deposit(assets);
    }

    function deposit(uint256 assets) external returns (uint256, bytes32) {
        // Validate deposit amount
        require(assets >= _MIN_DEPOSIT, "MIN_DEPOSIT");
        require(assets <= this.maxDeposit(), "MAX_DEPOSIT");
        // Total fee - Shares will minted by rate excluding this value
        uint256 totalFee = _calculateFee(assets);
        // Fee to transfer contract owner
        uint256 ownerFee = assets.mulDiv(_profitPercents, 100);
        // Determining amount of shares to mint
        uint256 shares = this.convertToShares(assets - totalFee);
        // Transfer assets from caller to owner
        IERC20(_assetAddress).safeTransferFrom(
            msg.sender,
            address(this),
            assets
        );
        // Transfer assets to contract owner
        IERC20(_assetAddress).safeTransfer(_feeRecipient, ownerFee);
        // Increment total assets managed by contract
        _totalAssets += assets - ownerFee;
        // SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(msg.sender, shares);
        bytes32 id = _openDeposit(msg.sender, assets, shares);
        // Calculate when deposit should be liquidated
        uint256 maxAssets = shares.mulDiv(_LIQUIDATION_POINT, 100);
        emit Deposit(id, msg.sender, assets, shares, maxAssets);
        emit ExchangeRateUpdated(this.exchangeRate(), block.timestamp);
        return (shares, id);
    }

    function previewWithdraw(bytes32 id) external view returns (uint256) {
        OKDeposit storage _deposit = _deposits[id];
        require(_deposit.status == _ORDER_STATUS_PENDING, "DEPOSIT_CLOSED");
        // uint256 fee = _calculateFee(deposit.startWithAssets);
        uint256 _assets = convertToAssets(_deposit.shares);
        uint256 fee = _calculateFee(_assets);
        return _assets - fee;
    }

    function withdraw(bytes32 id) external returns (uint256 assets) {
        require(_deposits[id].owner == msg.sender, "NOT_OWNER");
        return _withdraw(id, _ORDER_STATUS_CLOSED);
    }

    function canLiquidate(bytes32 id) external view returns (bool) {
        // Check if deposit is pending
        OKDeposit storage _deposit = _deposits[id];
        if (_deposit.status != _ORDER_STATUS_PENDING) {
            return false;
        }
        uint256 amount = convertToAssets(_deposit.shares);
        // Calculate amount with fee
        uint256 amountWithFee = amount - _calculateFee(amount);
        return
            amountWithFee >=
            _deposit.startWithAssets.mulDiv(_LIQUIDATION_POINT, 100);
    }

    // Anyone can call liquidate if profit is above liquidation point
    function liquidate(bytes32 id) external returns (uint256) {
        OKDeposit storage _deposit = _deposits[id];
        require(_deposit.status == _ORDER_STATUS_PENDING, "DEPOSIT_CLOSED");
        uint256 amount = convertToAssets(_deposit.shares);
        uint256 amountWithFee = amount - _calculateFee(amount);
        require(
            amountWithFee >=
                _deposit.startWithAssets.mulDiv(_LIQUIDATION_POINT, 100),
            "NOT_LIQUIDABLE"
        );
        return _withdraw(id, _ORDER_STATUS_LIQUIDATED);
    }

    function _calculateFee(uint256 assets) private pure returns (uint256) {
        return assets.mulDiv(_feePercents, 100);
    }

    function _withdraw(bytes32 id, uint8 status) private returns (uint256) {
        OKDeposit storage _deposit = _deposits[id];
        require(_deposit.status == _ORDER_STATUS_PENDING, "DEPOSIT_CLOSED");
        _deposit.status = status;
        uint256 amount = convertToAssets(_deposit.shares);
        uint256 returnAssets = amount - _calculateFee(amount);
        uint256 ownerFee = amount.mulDiv(_profitPercents, 100);
        IERC20(_assetAddress).safeTransfer(_deposit.owner, returnAssets);
        IERC20(_assetAddress).safeTransfer(_feeRecipient, ownerFee);
        _burn(_deposit.owner, _deposit.shares);
        _totalAssets -= (returnAssets + ownerFee);

        emit Withdraw(
            id,
            _deposit.owner,
            returnAssets,
            _deposit.shares,
            _deposit.status
        );
        emit ExchangeRateUpdated(this.exchangeRate(), block.timestamp);
        return returnAssets;
    }

    function _openDeposit(
        address owner,
        uint256 startWithAssets,
        uint256 shares
    ) private returns (bytes32) {
        bytes32 id = keccak256(
            abi.encodePacked(
                msg.sender,
                block.timestamp,
                startWithAssets,
                shares
            )
        );
        _deposits[id] = OKDeposit({
            owner: owner,
            startWithAssets: startWithAssets,
            shares: shares,
            status: _ORDER_STATUS_PENDING
        });
        return id;
    }

    function _closeDeposit(bytes32 id, uint8 newStatus) private {
        _deposits[id].status = newStatus;
    }
}
