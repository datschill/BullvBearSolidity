// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestBatchReclaimContracts is Base {
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

    function testReclaimSeveralOrders() public {
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

        vm.warp(order.expiry + 1);

        bvb.batchReclaimContracts(orders); // Tier reclaim

        assertEq(bvb.reclaimedContracts(uint(orderHash)), true, "First contract should be flagged as reclaimed");
        assertEq(bvb.reclaimedContracts(uint(secondOrderHash)), true, "Second contract should be flagged as reclaimed");
    }
}