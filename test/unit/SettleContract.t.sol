// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestSettleContract is Base {
    event SettledContract(bytes32 orderHash, uint tokenId, BvbProtocol.Order order);

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

    function testCannotSettleIfNotBear() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        vm.prank(bull);
        vm.expectRevert("ONLY_BEAR");
        bvb.settleContract(order, tokenIdBull);
    }

    function testCannotSettleIfContractExpired() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);
        vm.warp(order.expiry + 1);

        vm.expectRevert("EXPIRED_CONTRACT");
        bvb.settleContract(order, tokenIdBear);
    }

    function testCannotSettleIfAlreadySettled() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);
        bvb.settleContract(order, tokenIdBear);
        doodles.mint(address(this), 9876);

        vm.expectRevert("SETTLED_CONTRACT");
        bvb.settleContract(order, 9876);
    }

    function testItFlagsContractAsSettled() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);
        bvb.settleContract(order, tokenIdBear);

        assertEq(bvb.settledContracts(uint(orderHash)), true, "Contract should be flagged as settled");
    }

    function testItTransfersNFT() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);
        bvb.settleContract(order, tokenIdBear);

        assertEq(doodles.ownerOf(tokenIdBear), address(bvb), "NFT should have been transfered to BvbProtocol");
        assertEq(bvb.claimableTokenId(uint(orderHash)), tokenIdBear, "NFT token ID should be claimable");
    }

    function testItTransfersAsset() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);
        uint balanceBearBefore = weth.balanceOf(address(this));
        bvb.settleContract(order, tokenIdBear);

        assertEq(weth.balanceOf(address(this)), balanceBearBefore + order.premium + order.collateral, "Asset amount should have been transfered to bear");
    }

    function testEmitSettledContract() public {
        BvbProtocol.Order memory order = defaultOrder();

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrder(bullPrivateKey, order);
        bvb.matchOrder(order, signature);

        vm.expectEmit(false, false, false, true);
        emit SettledContract(orderHash, tokenIdBear, order);
        bvb.settleContract(order, tokenIdBear);
    }
}