// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestBatchMatchOrders is Base {
    event MatchedOrder(bytes32 orderHash, address indexed bull, address indexed bear, BvbProtocol.Order order);

    function setUp() public {
        bvb.setAllowedAsset(address(weth), true);
        bvb.setAllowedCollection(address(doodles), true);

        deal(address(weth), bull, 0xffffffff);
        deal(address(weth), address(this), 0xffffffff);

        weth.approve(address(bvb), type(uint).max);

        vm.prank(bull);
        weth.approve(address(bvb), type(uint).max);
    }

    function testCannotMatchWithInvalidSignatureCount() public {
        BvbProtocol.Order memory order = defaultOrder();

        BvbProtocol.Order memory secondOrder = defaultOrder();
        secondOrder.isBull = false;

        bytes memory signature = signOrder(bullPrivateKey, order);

        BvbProtocol.Order[] memory orders = new BvbProtocol.Order[](2);
        orders[0] = order;
        orders[1] = secondOrder;
        bytes[] memory signatures = new bytes[](1);
        signatures[0] = signature;

        vm.expectRevert("INVALID_ORDERS_COUNT");
        bvb.batchMatchOrders(orders, signatures);
    }

    function testMatchSeveralOrders() public {
        BvbProtocol.Order memory order = defaultOrder();
        bytes32 orderHash = bvb.hashOrder(order);

        BvbProtocol.Order memory secondOrder = defaultOrder();
        secondOrder.isBull = false;
        bytes32 secondOrderHash = bvb.hashOrder(secondOrder);

        bytes memory signature = signOrder(bullPrivateKey, order);
        bytes memory secondSignature = signOrder(bullPrivateKey, secondOrder);

        BvbProtocol.Order[] memory orders = new BvbProtocol.Order[](2);
        orders[0] = order;
        orders[1] = secondOrder;
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = signature;
        signatures[1] = secondSignature;

        bvb.batchMatchOrders(orders, signatures);

        assertEq(bvb.bulls(uint(orderHash)), bull, "Bvb correctly saved the bull for the first order");
        assertEq(bvb.bears(uint(orderHash)), address(this), "Bvb correctly saved the bear for the first order");
        assertEq(bvb.bulls(uint(secondOrderHash)), address(this), "Bvb correctly saved the bull for the second order");
        assertEq(bvb.bears(uint(secondOrderHash)), bull, "Bvb correctly saved the bear for the second order");
    }
}