// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestMatchOrder is Base {
    event MatchedOrder(bytes32 orderHash, address indexed bull, address indexed bear, BvbProtocol.Order order);
    event Deposit(address indexed dst, uint256 wad);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        bvb.setAllowedAsset(address(weth), true);
        bvb.setAllowedCollection(address(doodles), true);

        deal(address(weth), bull, 0xffffffff);
        deal(address(weth), address(this), 0xffffffff);

        weth.approve(address(bvb), type(uint).max);

        vm.prank(bull);
        weth.approve(address(bvb), type(uint).max);
    }

    function testCannotSendInvalidETHAmount() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        deal(address(this), 0xffffffff);
        uint fee = bvb.fee();
        uint takerPrice = (order.premium * fee) / 1000 + order.premium;

        vm.expectRevert("INVALID_ETH_VALUE");
        bvb.matchOrder{ value: takerPrice + 1 }(order, signature);
    }

    function testCannotSendETHIfAssetIsNotWETH() public {
        BvbProtocol.Order memory order = defaultOrder();

        order.asset = address(usdc);

        bytes memory signature = signOrder(bullPrivateKey, order);
        deal(address(this), 0xffffffff);
        uint fee = bvb.fee();
        uint takerPrice = (order.premium * fee) / 1000 + order.premium;

        // Allow and deal USDCs
        bvb.setAllowedAsset(address(usdc), true);
        deal(address(usdc), bull, 0xffffffff);
        deal(address(usdc), address(this), 0xffffffff);

        vm.expectRevert("INCOMPATIBLE_ASSET_ETH_VALUE");
        bvb.matchOrder{ value: takerPrice }(order, signature);
    }

    function testItDepositWETHWhenETHSent() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        uint fee = bvb.fee();
        uint bearPrice = (order.premium * fee) / 1000 + order.premium;

        vm.expectEmit(true, false, false, true);
        emit Deposit(address(bvb), bearPrice);
        bvb.matchOrder{ value: bearPrice }(order, signature);
    }

    function testItRetrieveWETHWhenETHNotSent() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        uint fee = bvb.fee();
        uint bearPrice = (order.premium * fee) / 1000 + order.premium;

        vm.expectEmit(true, false, false, true);
        emit Transfer(address(this), address(bvb), bearPrice);
        bvb.matchOrder(order, signature);
    }

    function testBvbHoldTheRightAmountOfAsset() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        uint fee = bvb.fee();
        uint bullPrice = (order.collateral * fee) / 1000 + order.collateral;
        uint bearPrice = (order.premium * fee) / 1000 + order.premium;
        uint balanceBvbBefore = IERC20(order.asset).balanceOf(address(bvb));

        bvb.matchOrder(order, signature);
        assertEq(IERC20(order.asset).balanceOf(address(bvb)), balanceBvbBefore + bullPrice + bearPrice, "Bvb received the correct amount of asset");
    }

    function testBvbHoldTheRightAmountOfAssetOnDeposit() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        uint fee = bvb.fee();
        uint bullPrice = (order.collateral * fee) / 1000 + order.collateral;
        uint bearPrice = (order.premium * fee) / 1000 + order.premium;
        uint balanceBvbBefore = IERC20(order.asset).balanceOf(address(bvb));

        bvb.matchOrder{ value: bearPrice }(order, signature);
        assertEq(IERC20(order.asset).balanceOf(address(bvb)), balanceBvbBefore + bullPrice + bearPrice, "Bvb received the correct amount of asset");
    }
    
    function testWithdrawableFeesAreCorrect() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        uint fee = bvb.fee();
        uint bullFees = (order.collateral * fee) / 1000;
        uint bearFees = (order.premium * fee) / 1000;
        uint withdrawableFeesBefore = bvb.withdrawableFees(order.asset);

        bvb.matchOrder(order, signature);
        assertEq(bvb.withdrawableFees(order.asset), withdrawableFeesBefore + bullFees + bearFees, "Bvb correctly saved withdrawable fees");
    }

    function testItCorrectlyStoreBullAndBear() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        assertEq(bvb.bulls(uint(orderHash)), bull, "Bvb correctly saved the bull");
        assertEq(bvb.bears(uint(orderHash)), address(this), "Bvb correctly saved the bear");
    }
    
    function testEmitMatchedOrder() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);

        vm.expectEmit(false, false, false, true);
        emit MatchedOrder(orderHash, bull, address(this), order);
        bvb.matchOrder(order, signature);
    }
}