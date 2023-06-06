// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestTransferPosition is Base {
    event Deposit(address indexed dst, uint256 wad);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event SoldPosition(bytes32 sellOrderHash, BvbProtocol.SellOrder sellOrder, bytes32 orderHash, BvbProtocol.Order order, address indexed buyer);

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

    function testCannotBuyIfNotWhitelisted() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        address[] memory whitelist = new address[](2);
        whitelist[0] = bull;
        whitelist[1] = bear;

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        sellOrder.whitelist = whitelist;
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        vm.expectRevert("INVALID_BUYER");
        bvb.buyPosition(sellOrder, signatureSell, 0);
    }

    function testCanBuyIfWhitelisted() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        address[] memory whitelist = new address[](3);
        whitelist[0] = bull;
        whitelist[1] = bear;
        whitelist[2] = address(this);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        sellOrder.whitelist = whitelist;
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        bvb.buyPosition(sellOrder, signatureSell, 0);

        assertEq(bvb.bulls(uint(orderHash)), address(this), "Should have bought the bull position from Bull");
    }

    function testCannotSendInvalidETHAmount() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        vm.expectRevert("INVALID_ETH_VALUE");
        bvb.buyPosition{value: sellOrder.price - 1}(sellOrder, signatureSell, 0);
    }

    function testCannotSendETHIfAssetIsNotWETH() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        bvb.setAllowedAsset(address(usdc), true);
        deal(address(usdc), address(this), 0xffffffff);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        sellOrder.asset = address(usdc);
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        vm.expectRevert("INCOMPATIBLE_ASSET_ETH_VALUE");
        bvb.buyPosition{value: sellOrder.price}(sellOrder, signatureSell, 0);
    }

    function testItDepositWETHWhenETHSent() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        uint tip = 10;
        uint price = sellOrder.price + tip;

        vm.expectEmit(true, false, false, true);
        emit Deposit(address(bvb), price);
        bvb.buyPosition{value: price}(sellOrder, signatureSell, tip);
    }

    function testBvbWETHBalanceIsUnchangedWhenETHSent() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;

        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);
        bvb.buyPosition{value: sellOrder.price}(sellOrder, signatureSell, 0);

        uint balanceBvbBefore = weth.balanceOf(address(bvb));

        assertEq(weth.balanceOf(address(bvb)), balanceBvbBefore, "Bvb WETH balance shouldn't have changed");
    }

    function testMakerReceiveWETHWhenETHSent() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;

        uint balanceMakerBefore = weth.balanceOf(sellOrder.maker);
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);
        bvb.buyPosition(sellOrder, signatureSell, 0);

        assertEq(weth.balanceOf(sellOrder.maker), balanceMakerBefore + sellOrder.price, "Maker should have received price amount of WETH");
    }

    function testBuyerSendTheRightAmountOfAssetToMaker() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;

        uint balanceMakerBefore = IERC20(sellOrder.asset).balanceOf(address(sellOrder.maker));
        uint balanceBuyerBefore = IERC20(sellOrder.asset).balanceOf(address(this));
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);
        bvb.buyPosition(sellOrder, signatureSell, 0);

        assertEq(IERC20(sellOrder.asset).balanceOf(sellOrder.maker), balanceMakerBefore + sellOrder.price, "Maker should have received price amount of asset");
        assertEq(IERC20(sellOrder.asset).balanceOf(address(this)), balanceBuyerBefore - sellOrder.price, "Buyer should have sent price amount of asset");
    }

    function testEmitSoldPosition() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);

        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);

        vm.expectEmit(true, false, false, true);
        emit SoldPosition(sellOrderHash, sellOrder, orderHash, order, address(this));
        bvb.buyPosition(sellOrder, signatureSell, 0);
    }

    function testItCorrectlyTransfersBullPosition() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        
        bytes memory signatureSell = signSellOrder(bullPrivateKey, sellOrder);
        bvb.buyPosition(sellOrder, signatureSell, 0);

        assertEq(bvb.bulls(uint(orderHash)), address(this), "Bull position should be transfered to caller");
    }

    function testItCorrectlyTransfersBearPosition() public {
        BvbProtocol.Order memory order = defaultOrder();
        order.maker = bear;
        order.isBull = false;

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bearPrivateKey, order);
        bvb.matchOrder(order, signature);

        BvbProtocol.SellOrder memory sellOrder = defaultSellOrder();
        sellOrder.orderHash = orderHash;
        sellOrder.maker = bear;
        sellOrder.isBull = false;
        
        bytes memory signatureSell = signSellOrder(bearPrivateKey, sellOrder);
        bvb.buyPosition(sellOrder, signatureSell, 0);

        assertEq(bvb.bears(uint(orderHash)), address(this), "Bear position should be transfered to caller");
    }
}