// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestReclaimContract is Base {
    event ReclaimedContract(bytes32 orderHash, BvbProtocol.Order order);

    uint internal tokenIdBull = 1234;
    uint internal tokenIdBear = 5678;

    function setUp() public {
        bvb.setAllowedAsset(address(weth), true);
        bvb.setAllowedCollection(address(doodles), true);

        deal(address(weth), bull, 0xffffffff);
        deal(address(weth), address(this), 0xffffffff);

        doodles.mint(bull, tokenIdBull);
        doodles.mint(address(this), tokenIdBear);

        weth.approve(address(bvb), type(uint).max);
        doodles.setApprovalForAll(address(bvb), true);

        vm.startPrank(bull);
        weth.approve(address(bvb), type(uint).max);
        doodles.setApprovalForAll(address(bvb), true);
        vm.stopPrank();
    }

    function testCannotReclaimIfNotExpired() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        vm.prank(bull);
        vm.expectRevert("NOT_EXPIRED_CONTRACT");
        bvb.reclaimContract(order);
    }

    function testCannotReclaimIfAlreadyReclaimed() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);
        vm.warp(order.expiry + 1);

        vm.startPrank(bull);
        bvb.reclaimContract(order);
        vm.expectRevert("RECLAIMED_CONTRACT");
        bvb.reclaimContract(order);
        vm.stopPrank();
    }

    function testItFlagsContractAsReclaimed() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);
        vm.warp(order.expiry + 1);

        vm.prank(bull);
        bvb.reclaimContract(order);

        assertEq(bvb.reclaimedContracts(uint(orderHash)), true, "Contract should be flagged as reclaimed");
    }

    function testItTransfersAsset() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);
        vm.warp(order.expiry + 1);
        uint balanceBullBefore = weth.balanceOf(bull);
        
        vm.prank(bull);
        bvb.reclaimContract(order);

        assertEq(weth.balanceOf(bull), balanceBullBefore + order.premium + order.collateral, "Asset amount should have been transfered to bull");
    }

    function testAnybodyCanReclaimForBull() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);
        vm.warp(order.expiry + 1);
        uint balanceBullBefore = weth.balanceOf(bull);
        
        bvb.reclaimContract(order);

        assertEq(weth.balanceOf(bull), balanceBullBefore + order.premium + order.collateral, "Asset amount should have been transfered to bull");
    }

    function testBullCanReclaimNFT() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);
        bvb.settleContract(order, tokenIdBear);

        bvb.reclaimContract(order);

        assertEq(doodles.ownerOf(tokenIdBear), bull, "NFT should have been transfered to Bull");
    }

    function testEmitReclaimedContract() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);
        vm.warp(order.expiry + 1);

        vm.startPrank(bull);
        vm.expectEmit(false, false, false, true);
        emit ReclaimedContract(orderHash, order);
        bvb.reclaimContract(order);
        vm.stopPrank();
    }
}