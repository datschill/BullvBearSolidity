// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestCancel is Base {
    event CanceledOrder(bytes32 orderHash, BvbProtocol.Order order);
    event UpdatedMinimumValidNonce(address indexed user, uint minimumValidNonce);
    event CanceledSellOrder(bytes32 sellOrderHash, BvbProtocol.SellOrder sellOrder);
    event UpdatedMinimumValidNonceSell(address indexed user, uint minimumValidNonceSell);

    function setUp() public {
        bvb.setAllowedAsset(address(weth), true);
        bvb.setAllowedCollection(address(doodles), true);

        deal(address(weth), bull, 0xffffffff);
        deal(address(weth), address(this), 0xffffffff);

        weth.approve(address(bvb), type(uint).max);

        vm.prank(bull);
        weth.approve(address(bvb), type(uint).max);
    }

    function testSetOrderAsCanceled() public {
        BvbProtocol.Order memory order = defaultOrder();

        vm.prank(bull);
        bvb.cancelOrder(order);

        assertEq(bvb.canceledOrders(bvb.hashOrder(order)), true, "Should have canceled order");
    }

    function testCannotCancelOrderIfAlreadyCanceled() public {
        BvbProtocol.Order memory order = defaultOrder();

        vm.prank(bull);
        bvb.cancelOrder(order);

        vm.startPrank(bull);
        vm.expectRevert("ALREADY_CANCELED");
        bvb.cancelOrder(order);
        vm.stopPrank();
    }

    function testCannotSetOrderAsCanceled() public {
        BvbProtocol.Order memory order = defaultOrder();
        
        vm.expectRevert("NOT_SIGNER");
        bvb.cancelOrder(order);
    }

    function testCannotCancelAnOrderMatched() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        vm.startPrank(bull);
        vm.expectRevert("ORDER_MATCHED");
        bvb.cancelOrder(order);
        vm.stopPrank();
    }

    function testEmitCanceledOrderEvent() public {
        BvbProtocol.Order memory order = defaultOrder();

        vm.startPrank(bull);
        vm.expectEmit(false, false, false, true);
        emit CanceledOrder(bvb.hashOrder(order), order);
        bvb.cancelOrder(order);
        vm.stopPrank();
    }

    function testSetSellOrderAsCanceled() public {
        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();

        vm.prank(bull);
        bvb.cancelSellOrder(sellOrder);

        assertEq(bvb.canceledSellOrders(bvb.hashSellOrder(sellOrder)), true, "Should have canceled sell order");
    }

    function testCannotCancelSellOrderIfAlreadyCanceled() public {
        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();

        vm.prank(bull);
        bvb.cancelSellOrder(sellOrder);

        vm.startPrank(bull);
        vm.expectRevert("ALREADY_CANCELED");
        bvb.cancelSellOrder(sellOrder);
        vm.stopPrank();
    }

    function testCannotSetSellOrderAsCanceled() public {
        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        
        vm.expectRevert("NOT_SIGNER");
        bvb.cancelSellOrder(sellOrder);
    }

    function testCannotCancelASellOrderBought() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;

        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);
        bvb.buyPosition(sellOrder, signatureSell, 0);

        vm.startPrank(bull);
        vm.expectRevert("POSITION_SOLD");
        bvb.cancelSellOrder(sellOrder);
        vm.stopPrank();
    }

    function testEmitCanceledSellOrderEvent() public {
        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();

        vm.startPrank(bull);
        vm.expectEmit(false, false, false, true);
        emit CanceledSellOrder(bvb.hashSellOrder(sellOrder), sellOrder);
        bvb.cancelSellOrder(sellOrder);
        vm.stopPrank();
    }

    function testSetMinimumValidNonce() public {
        bvb.setMinimumValidNonce(10);

        assertEq(bvb.minimumValidNonce(address(this)), 10, "Should have updated the minimum valid nonce");
    }

    function testCannotSetMinimumValidNonceBelow() public {
        bvb.setMinimumValidNonce(10);

        vm.expectRevert("NONCE_TOO_LOW");
        bvb.setMinimumValidNonce(9);
    }

    function testEmitUpdatedMinimumValidNonce() public {
        vm.expectEmit(true, false, false, true);
        emit UpdatedMinimumValidNonce(address(this), 10);
        bvb.setMinimumValidNonce(10);
    }

    function testSetMinimumValidNonceSell() public {
        bvb.setMinimumValidNonceSell(20);

        assertEq(bvb.minimumValidNonceSell(address(this)), 20, "Should have updated the sell minimum valid nonce");
    }

    function testCannotSetMinimumValidNonceSellBelow() public {
        bvb.setMinimumValidNonceSell(20);

        vm.expectRevert("NONCE_TOO_LOW");
        bvb.setMinimumValidNonceSell(15);
    }

    function testEmitUpdatedMinimumValidNonceSell() public {
        vm.expectEmit(true, false, false, true);
        emit UpdatedMinimumValidNonceSell(address(this), 20);
        bvb.setMinimumValidNonceSell(20);
    }
}