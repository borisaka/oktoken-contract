// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Roles.sol";
import {TetherToken} from "./utils/USDT.sol";
import {console} from "forge-std/Script.sol";
import {SigUtils} from "./SigUtils.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ContractWithRoles is Roles {
    constructor(address owner) Ownable(owner) {
        // transferOwnership(owner);
    }
}

// beforeEach(async function () {
//     [owner, admin, user1, user2] = await ethers.getSigners();
//     const Roles = new TestLoveRoles__factory(owner);

//     rolesContract = await Roles.deploy();
//   });

//   it('should not allow admin to grant role', async () => {
//     await rolesContract.connect(owner).grantRole(admin.address, 'admin');
//     await expect(rolesContract.connect(admin).grantRole(user1.address, 'user')).to.be.revertedWith(
//       'Ownable: caller is not the owner'
//     );
//   });

//   it('should prevent non-owner from granting role', async () => {
//     await expect(rolesContract.connect(user1).grantRole(user2.address, 'user')).to.be.revertedWith(
//       'Ownable: caller is not the owner'
//     );

//     await expect(await rolesContract.checkRole(user2.address, 'user')).to.be.false;
//   });

//   it('should allow owner to revoke admin role', async () => {
//     await rolesContract.connect(owner).grantRole(admin.address, 'admin');

//     await expect(await rolesContract.checkRole(admin.address, 'admin')).to.be.true;

//     await rolesContract.connect(owner).revokeRole(admin.address, 'admin');

//     await expect(await rolesContract.checkRole(admin.address, 'admin')).to.be.false;
//   });

//   it('should prevent non-owner from revoking role', async () => {
//     await rolesContract.connect(owner).grantRole(user1.address, 'user');

//     await expect(await rolesContract.checkRole(user1.address, 'user')).to.be.true;

//     await expect(rolesContract.connect(user1).revokeRole(user1.address, 'user')).to.be.revertedWith(
//       'Ownable: caller is not the owner'
//     );

//     await expect(await rolesContract.checkRole(user1.address, 'user')).to.be.true;
//   });

contract RolesTest is Test {
    // address owner = vm.addr(0);
    // address admin = vm.addr(1);
    // address user1 = vm.addr(2);
    // address user2 = vm.addr(3);
    // uint256 alicePrivateKey = 0xA11CE;
    // uint256 bobPrivateKey = 0xB0B;
    uint256 ownerPk =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address internal owner = vm.addr(ownerPk);
    address internal admin = address(0x2);
    address internal user1 = address(0x3);
    address internal user2 = address(0x4);
    ContractWithRoles subject;

    function setUp() public {
        // owner = msg.sender;
        console.log("Msg.sender address: %s", msg.sender);
        console.log("owner: %s", owner);
        subject = new ContractWithRoles(owner);
        vm.startPrank(owner);
        // subject.checkRole(owner, "admin");
        // console.log("Is owner admin: %s", hasAdmin);
        vm.stopPrank();
        // subject.grantRole(admin, "admin");
    }

    //   it('should allow owner to grant admin role', async () => {
    //     await rolesContract.connect(owner).grantRole(admin.address, 'admin');

    //     await expect(await rolesContract.checkRole(admin.address, 'admin')).to.be.true;
    //   });
    function testGrantRole() public {
        assertTrue(true);
        bool hasAdmin = subject.checkRole(owner, "admin");
        console.log("Is owner admin: %s", hasAdmin);
        // vm.startPrank(owner);
        // subject.grantRole(admin, "admin");
        // assertTrue(subject.checkRole(admin, "admin"));
        // vm.stopPrank();
    }

    // function testFizz() public {
    //     assertTrue(true);
    //     console.log(msg.sender.balance);
    // }
}
