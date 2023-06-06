// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestIsValidOrder is Base {
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

    function testCannotUseInvalidSignature() public {
        BvbProtocol.Order memory order = defaultOrder();
        order.maker = bear;
        bytes32 orderHash = bvb.hashOrder(order);

        bytes memory signature = signOrder(bullPrivateKey, order);

        vm.expectRevert("INVALID_SIGNATURE");
        bvb.checkIsValidOrder(order, orderHash, signature);
    }

    function testCannotUseAnExpiredOrder() public {
        BvbProtocol.Order memory order = defaultOrder();
        order.validity = block.timestamp;
        bytes32 orderHash = bvb.hashOrder(order);

        bytes memory signature = signOrder(bullPrivateKey, order);

        vm.expectRevert("EXPIRED_VALIDITY_TIME");
        bvb.checkIsValidOrder(order, orderHash, signature);
    }

    function testCannotUseCanceledOrder() public {
        BvbProtocol.Order memory order = defaultOrder();
        bytes32 orderHash = bvb.hashOrder(order);

        bytes memory signature = signOrder(bullPrivateKey, order);
        vm.prank(bull);
        bvb.cancelOrder(order);

        vm.expectRevert("ORDER_CANCELED");
        bvb.checkIsValidOrder(order, orderHash, signature);
    }

    function testCannotUseIfInvalidNonce() public {
        BvbProtocol.Order memory order = defaultOrder();
        bytes32 orderHash = bvb.hashOrder(order);

        bytes memory signature = signOrder(bullPrivateKey, order);
        vm.prank(bull);
        bvb.setMinimumValidNonce(order.nonce + 1);

        vm.expectRevert("INVALID_NONCE");
        bvb.checkIsValidOrder(order, orderHash, signature);
    }

    function testCannotUseIfContractIsInvalid() public {
        BvbProtocol.Order memory order = defaultOrder();
        order.expiry = order.validity;
        bytes32 orderHash = bvb.hashOrder(order);

        bytes memory signature = signOrder(bullPrivateKey, order);

        vm.expectRevert("INVALID_EXPIRY_TIME");
        bvb.checkIsValidOrder(order, orderHash, signature);
    }

    function testCannotUseIfFeesTooHigh() public {
        BvbProtocol.Order memory order = defaultOrder();
        bytes32 orderHash = bvb.hashOrder(order);

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.setFee(order.fee + 1);

        vm.expectRevert("INVALID_FEE");
        bvb.checkIsValidOrder(order, orderHash, signature);
    }

    function testCannotUseIfAssetIsNotAllowed() public {
        BvbProtocol.Order memory order = defaultOrder();
        bytes32 orderHash = bvb.hashOrder(order);

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.setAllowedAsset(address(order.asset), false);

        vm.expectRevert("INVALID_ASSET");
        bvb.checkIsValidOrder(order, orderHash, signature);
    }

    function testCannotUseIfCollectionIsNotAllowed() public {
        BvbProtocol.Order memory order = defaultOrder();
        bytes32 orderHash = bvb.hashOrder(order);

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.setAllowedCollection(address(order.collection), false);

        vm.expectRevert("INVALID_COLLECTION");
        bvb.checkIsValidOrder(order, orderHash, signature);
    }

    function testCannotUseIfAlreadyMatched() public {
        BvbProtocol.Order memory order = defaultOrder();
        bytes32 orderHash = bvb.hashOrder(order);

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        vm.expectRevert("ORDER_ALREADY_MATCHED");
        bvb.checkIsValidOrder(order, orderHash, signature);
    }
}