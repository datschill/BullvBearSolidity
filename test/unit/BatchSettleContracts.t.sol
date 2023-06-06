// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestBatchSettleContracts is Base {
    event MatchedOrder(bytes32 orderHash, address indexed bull, address indexed bear, BvbProtocol.Order order);

    function setUp() public {
        bvb.setAllowedAsset(address(weth), true);
        bvb.setAllowedCollection(address(doodles), true);

        deal(address(weth), bull, 0xffffffff);
        deal(address(weth), address(this), 0xffffffff);

        weth.approve(address(bvb), type(uint).max);
        doodles.setApprovalForAll(address(bvb), true);

        vm.prank(bull);
        weth.approve(address(bvb), type(uint).max);
    }

    function testCannotSettleWithInvalidTokenIDsCount() public {
        BvbProtocol.Order memory order = defaultOrder();

        BvbProtocol.Order memory secondOrder = defaultOrder();
        secondOrder.isBull = false;

        bytes memory signature = signOrder(bullPrivateKey, order);
        bytes memory secondSignature = signOrder(bullPrivateKey, secondOrder);

        BvbProtocol.Order[] memory orders = new BvbProtocol.Order[](2);
        orders[0] = order;
        orders[1] = secondOrder;
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = signature;
        signatures[1] = secondSignature;

        bvb.batchMatchOrders(orders, signatures);

        uint[] memory tokenIds = new uint[](1);
        tokenIds[0] = 1234;

        vm.expectRevert("INVALID_ORDERS_COUNT");
        bvb.batchSettleContracts(orders, tokenIds);
    }

    function testSettleSeveralOrders() public {
        BvbProtocol.Order memory order = defaultOrder();
        bytes32 orderHash = bvb.hashOrder(order);

        BvbProtocol.Order memory secondOrder = defaultOrder();
        secondOrder.nonce = order.nonce + 1;
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

        uint[] memory tokenIDs = new uint[](2);
        tokenIDs[0] = 1234;
        tokenIDs[1] = 5678;
        doodles.mint(address(this), tokenIDs[0]);
        doodles.mint(address(this), tokenIDs[1]);

        bvb.batchSettleContracts(orders, tokenIDs);

        assertEq(bvb.settledContracts(uint(orderHash)), true, "First contract should be flagged as settled");
        assertEq(bvb.settledContracts(uint(secondOrderHash)), true, "Second contract should be flagged as settled");
    }
}