// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Roles} from "./Roles.sol";

contract Airdrop is AccessControl, Ownable {
    // bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct TokenDrop {
        address creator;
        bytes32 root;
        uint256 total;
        uint256 claimed;
        bool cancelled;
    }

    mapping(bytes32 nameHash => TokenDrop drop) public drops;
    mapping(bytes32 nameHash => mapping(address recipient => bool isClaimed))
        public isClaimed;

    IERC20 private immutable _token;
    uint256 public reservedBalance;

    event TokenDropCreated(
        string dropName,
        address indexed creator,
        bytes32 root,
        uint256 total
    );
    event TokenClaimed(
        string indexed dropName,
        address indexed recipient,
        uint256 amount
    );
    event TokenDropCancelled(string dropName);
    event TokensWithdrawn(uint256 amount);

    constructor(address tokenAddress, address admin) Ownable(admin) {
        _token = IERC20(tokenAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);

        // transferOwnership(admin);
        // _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // modifier onlyAdmin() {
    // bool isAdmin = checkRole(msg.sender, "admin");
    // require(isAdmin || msg.sender == owner(), "only admin");
    // _;
    // }

    function createTokenDrop(
        string calldata dropName,
        bytes32 root,
        uint256 total
    ) external onlyRole(MINTER_ROLE) {
        uint256 reservedTotal = reservedBalance + total;
        require(_getTokenBalance() >= reservedTotal, "insufficient balance");
        bytes32 nameHash = keccak256(bytes(dropName));
        require(drops[nameHash].creator == address(0), "name already exists");

        drops[nameHash] = TokenDrop({
            creator: msg.sender,
            root: root,
            total: total,
            claimed: 0,
            cancelled: false
        });
        reservedBalance = reservedTotal;

        emit TokenDropCreated(dropName, msg.sender, root, total);
    }

    function cancelTokenDrop(
        string calldata dropName
    ) external onlyRole(MINTER_ROLE) {
        bytes32 nameHash = keccak256(bytes(dropName));
        TokenDrop storage drop = drops[nameHash];
        require(drop.creator != address(0), "TokenDrop does not exist");
        require(!drop.cancelled, "TokenDrop is cancelled");

        reservedBalance -= drop.total - drop.claimed;
        drop.cancelled = true;

        emit TokenDropCancelled(dropName);
    }

    function claim(
        string memory dropName,
        address recipient,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        bytes32 nameHash = keccak256(bytes(dropName));
        require(
            drops[nameHash].creator != address(0),
            "TokenDrop does not exist"
        );

        TokenDrop storage drop = drops[nameHash];

        require(!drop.cancelled, "TokenDrop is cancelled");
        require(!isClaimed[nameHash][recipient], "already claimed");
        require(
            verifyClaim(proof, drop.root, recipient, amount),
            "invalid proof"
        );

        isClaimed[nameHash][recipient] = true;
        drop.claimed += amount;
        reservedBalance -= amount;
        require(_token.transfer(recipient, amount), "transfer failed");

        emit TokenClaimed(dropName, recipient, amount);
    }

    function withdrawTokens(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, "Invalid amount");
        require(
            _getTokenBalance() - reservedBalance >= amount,
            "Insufficient balance (reserved)"
        );
        require(_token.transfer(owner(), amount), "Transfer failed");

        emit TokensWithdrawn(amount);
    }

    function verifyClaim(
        bytes32[] memory proof,
        bytes32 root,
        address recipient,
        uint256 amount
    ) public pure returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(recipient, amount)))
        );

        return MerkleProof.verify(proof, root, leaf);
    }

    function _getTokenBalance() internal view returns (uint256) {
        return _token.balanceOf(address(this));
    }
}
