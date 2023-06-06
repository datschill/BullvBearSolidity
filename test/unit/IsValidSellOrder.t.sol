// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestIsValidSellOrder is Base {
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

    function testCannotSellBullPositionIfNotBull() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        sellOrder.maker = bear;
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);
        
        bytes memory signatureSell = signSellOrder(bearPrivateKey, sellOrder);

        vm.expectRevert("MAKER_NOT_BULL");
        bvb.checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signatureSell);
    }

    function testCannotSellBearPositionIfNotBear() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        sellOrder.isBull = false;
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        vm.expectRevert("MAKER_NOT_BEAR");
        bvb.checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signatureSell);
    }

    function testCannotSellAReclaimedContract() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);
        vm.warp(order.expiry + 1);

        vm.prank(bull);
        bvb.reclaimContract(order);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        vm.expectRevert("RECLAIMED_CONTRACT");
        bvb.checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signatureSell);
    }

    function testCannotSellASettledContract() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        uint tokenId = 1234;
        doodles.mint(address(this), tokenId);
        doodles.setApprovalForAll(address(bvb), true);
        bvb.settleContract(order, tokenId);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        vm.expectRevert("SETTLED_CONTRACT");
        bvb.checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signatureSell);
    }

    function testCannotSellBearPositionIfContractIsExpired() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);

        vm.prank(bear);
        bvb.matchOrder(order, signature);

        vm.warp(order.expiry + 1);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        sellOrder.maker = bear;
        sellOrder.isBull = false;
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);
        
        bytes memory signatureSell = signSellOrder(bearPrivateKey, sellOrder);

        vm.expectRevert("CONTRACT_EXPIRED");
        bvb.checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signatureSell);
    }

    function testCannotBuyAPositionAlreadyBought() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);
        bvb.buyPosition(sellOrder, signatureSell, 0);
        // Give back the position to Bull
        bvb.transferPosition(orderHash, sellOrder.isBull, bull);

        vm.expectRevert("SELL_ORDER_ALREADY_BOUGHT");
        bvb.checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signatureSell);
    }

    function testCannotUseACanceledSellOrder() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        vm.prank(bull);
        bvb.cancelSellOrder(sellOrder);

        vm.expectRevert("SELL_ORDER_CANCELED");
        bvb.checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signatureSell);
    }

    function testCannotUseASellOrderNotYetStarted() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        sellOrder.start = block.timestamp + 1;
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        vm.expectRevert("INVALID_START_TIME");
        bvb.checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signatureSell);
    }

    function testCannotUseAnExpiredSellOrder() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        sellOrder.end = block.timestamp - 1;
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        vm.expectRevert("SELL_ORDER_EXPIRED");
        bvb.checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signatureSell);
    }

    function testCannotUseSellOrderIfInvalidNonce() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        vm.prank(bull);
        bvb.setMinimumValidNonceSell(sellOrder.nonce + 1);

        vm.expectRevert("INVALID_NONCE");
        bvb.checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signatureSell);
    }

    function testCannotUseSellOrderIfAssetIsNotAllowed() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        bvb.setAllowedAsset(address(sellOrder.asset), false);

        vm.expectRevert("INVALID_ASSET");
        bvb.checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signatureSell);
    }
}