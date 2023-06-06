// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestView is Base {
    function setUp() public {
        bvb.setAllowedAsset(address(weth), true);
        bvb.setAllowedCollection(address(doodles), true);

        deal(address(weth), bull, 0xffffffff);
        deal(address(weth), address(this), 0xffffffff);

        weth.approve(address(bvb), type(uint).max);

        vm.prank(bull);
        weth.approve(address(bvb), type(uint).max);
    }

    function testItCorrectlyCheckTheSignature() public {
        BvbProtocol.Order memory order = defaultOrder();
        bytes32 orderHash = bvb.hashOrder(order);

        bytes memory signature = signOrder(bullPrivateKey, order);
        bool isValidSignature = ECDSA.recover(orderHash, signature) == bull;
        bool isInvalidSignature = ECDSA.recover(orderHash, signature) == bear;

        assertEq(bvb.isValidSignature(bull, orderHash, signature), isValidSignature, "Bvb correctly accepted the signature");
        assertEq(bvb.isValidSignature(bear, orderHash, signature), isInvalidSignature, "Bvb correctly rejected the signature");
    }

    function testDomainSeparatorIsCorrect() public {
        bytes32 domainSeparator = bvb.domainSeparatorV4();

        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 nameHash = keccak256(bytes("BullvBear"));
        bytes32 versionHash = keccak256(bytes("1"));

        bytes32 craftedDomainSeparator = keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(bvb)));

        assertEq(domainSeparator, craftedDomainSeparator, "Bvb returned the correct domain separator");
    }

    function testHashOrderIsCorrect() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderTypeHash = keccak256(
            "Order(uint256 premium,uint256 collateral,uint256 validity,uint256 expiry,uint256 nonce,uint16 fee,address maker,address asset,address collection,bool isBull)"
        );
        bytes32 domainSeparator = bvb.domainSeparatorV4();
        bytes32 orderHash = bvb.hashOrder(order);

        bytes32 structHash = keccak256(
            abi.encode(
                orderTypeHash,
                order.premium,
                order.collateral,
                order.validity,
                order.expiry,
                order.nonce,
                order.fee,
                order.maker,
                order.asset,
                order.collection,
                order.isBull
            )
        );

        bytes32 craftedOrderHash = ECDSA.toTypedDataHash(domainSeparator, structHash);

        assertEq(orderHash, craftedOrderHash, "Bvb correctly hashed Order");
    }

    function testHashSellOrderCorrectly() public {
        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();

        bytes32 sellOrderTypeHash = keccak256(
            "SellOrder(bytes32 orderHash,uint256 price,uint256 start,uint256 end,uint256 nonce,address maker,address asset,address[] whitelist,bool isBull)"
        );
        bytes32 domainSeparator = bvb.domainSeparatorV4();
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);

        bytes32 structHash = keccak256(
            abi.encode(
                sellOrderTypeHash,
                sellOrder.orderHash,
                sellOrder.price,
                sellOrder.start,
                sellOrder.end,
                sellOrder.nonce,
                sellOrder.maker,
                sellOrder.asset,
                keccak256(abi.encodePacked(sellOrder.whitelist)),
                sellOrder.isBull
            )
        );

        bytes32 craftedSellOrderHash = ECDSA.toTypedDataHash(domainSeparator, structHash);

        assertEq(sellOrderHash, craftedSellOrderHash, "Bvb correctly hashed Sell Order");
    }

    function testBuyerIsWhitelisted() public {
        address[] memory whitelist = new address[](2);
        whitelist[0] = bull;
        whitelist[1] = bear;

        assertEq(bvb.isWhitelisted(whitelist, bear), true, "Bear is whitelisted");
    }

    function testBuyerIsNotWhitelisted() public {
        address[] memory whitelist = new address[](2);
        whitelist[0] = bull;
        whitelist[1] = bear;

        assertEq(bvb.isWhitelisted(whitelist, address(this)), false, "Caller is not whitelisted");
    }
}