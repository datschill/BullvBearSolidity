// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Base} from "../Base.t.sol";

contract TestOwner is Base {
    event AllowCollection(address collection, bool allowed);
    event AllowAsset(address asset, bool allowed);
    event UpdatedFee(uint16 fee);
    event WithdrawnFees(address asset, uint amount);

    // setAllowedCollection 
    function testAddAllowedCollection() public {
        bvb.setAllowedCollection(address(doodles), true);

        assertEq(bvb.allowedCollection(address(doodles)), true, "Should have allowed this collection");
    }

    function testCannotAddAllowedCollection() public {
        vm.prank(bull);
        vm.expectRevert("Ownable: caller is not the owner");
        bvb.setAllowedCollection(address(doodles), true);
    }

    function testEmitAllowCollection() public {
        vm.expectEmit(false, false, false, true);
        emit AllowCollection(address(doodles), true);
        bvb.setAllowedCollection(address(doodles), true);
    }

    // setAllowedAsset
    function testAddAllowedAsset() public {
        bvb.setAllowedAsset(address(usdc), true);

        assertEq(bvb.allowedAsset(address(usdc)), true, "Should have allowed this asset");
    }

    function testCannotAddAllowedAsset() public {
        vm.prank(bull);
        vm.expectRevert("Ownable: caller is not the owner");
        bvb.setAllowedAsset(address(usdc), true);
    }

    function testEmitAllowAsset() public {
        vm.expectEmit(false, false, false, true);
        emit AllowAsset(address(doodles), true);
        bvb.setAllowedAsset(address(doodles), true);
    }

    // setFee
    function testSetFee() public {
        bvb.setFee(30);

        assertEq(bvb.fee(), 30, "Should have changed fees");
    }

    function testCannotSetFee() public {
        vm.prank(bull);
        vm.expectRevert("Ownable: caller is not the owner");
        bvb.setFee(30);
    }
    function testCannotSetInvalidFeeRate() public {
        vm.expectRevert("INVALID_FEE_RATE");
        bvb.setFee(100);
    }

    function testEmitUpdatedFee() public {
        vm.expectEmit(false, false, false, true);
        emit UpdatedFee(30);
        bvb.setFee(30);
    }

    // withdrawFees
    function testWithdrawFees() public {
        uint balance = usdc.balanceOf(bear);
        uint withdrawableFees = bvb.withdrawableFees(address(usdc));

        bvb.withdrawFees(address(usdc), bear);

        assertEq(usdc.balanceOf(bear), balance + withdrawableFees, "Should withdraw accumulated fees");
    }

    function testCannotWithdrawFees() public {
        vm.prank(bull);
        vm.expectRevert("Ownable: caller is not the owner");
        bvb.withdrawFees(address(usdc), bull);
    }

    function testEmitWithdrawnFees() public {
        vm.expectEmit(false, false, false, true);
        emit WithdrawnFees(address(usdc), 0);
        bvb.withdrawFees(address(usdc), bull);
    }
}