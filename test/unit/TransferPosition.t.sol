// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestTransferPosition is Base {
    function setUp() public {
        bvb.setAllowedAsset(address(weth), true);
        bvb.setAllowedCollection(address(doodles), true);

        deal(address(weth), bull, 0xffffffff);
        deal(address(weth), bear, 0xffffffff);
        deal(address(weth), address(this), 0xffffffff);

        weth.approve(address(bvb), type(uint).max);

        vm.prank(bull);
        weth.approve(address(bvb), type(uint).max);

        vm.prank(bear);
        weth.approve(address(bvb), type(uint).max);
    }

    function testCannotTransferBullPositionIfNotBull() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        vm.expectRevert("SENDER_NOT_BULL");
        bvb.transferPosition(orderHash, true, bear);
    }

    function testCannotTransferBearPositionIfNotBear() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        vm.startPrank(bull);
        vm.expectRevert("SENDER_NOT_BEAR");
        bvb.transferPosition(orderHash, false, bull);
        vm.stopPrank();
    }

    function testBullPositionShouldBeTransferedToBear() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        vm.prank(bull);
        bvb.transferPosition(orderHash, true, bear);

        assertEq(bvb.bulls(uint(orderHash)), bear, "Should have transfered the bull position to Bear");
    }

    function testBearPositionShouldBeTransferedToBear() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        bvb.transferPosition(orderHash, false, bear);

        assertEq(bvb.bears(uint(orderHash)), bear, "Should have transfered the bear position to Bear");
    }
}