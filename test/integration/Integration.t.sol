// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Base} from "../Base.t.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

contract TestIntegration is Base {
    function setUp() public {
        // Allow USDC to be used as asset for contracts
        bvb.setAllowedAsset(address(usdc), true);
        // Allow Doodles to be used as NFT collection for contracts
        bvb.setAllowedCollection(address(doodles), true);
    }    

    function testMatchingAndContractSettlement(BvbProtocol.Order memory order) public {
        vm.assume(order.premium <= type(uint).max / 1000);
        vm.assume(order.collateral <= type(uint).max / 1000);
        // Build the order
        order.validity = block.timestamp + 1 hours;
        order.expiry = block.timestamp + 1 days;
        order.nonce = 10;
        order.fee = bvb.fee();
        order.maker = bear;
        order.asset = address(usdc);
        order.collection = address(doodles);
        order.isBull = false;

        bytes32 orderHash = bvb.hashOrder(order);

        // Sign the order
        bytes memory signature = signOrderHash(bearPrivateKey, orderHash);

        // Calculate fees
        uint owedFeesBull = (order.collateral * fee) / 1000;
        uint owedFeesBear = (order.premium * fee) / 1000;

        // Give Bull and Bear enough USDC
        deal(address(usdc), bull, order.collateral + owedFeesBull);
        deal(address(usdc), bear, order.premium + owedFeesBear);

        // Initial balances
        uint initialBalanceBull = usdc.balanceOf(bull);
        uint initialBalanceBear = usdc.balanceOf(bear);
        uint initialBalanceBvb = usdc.balanceOf(address(bvb));
        uint initialWithdrawableFees = bvb.withdrawableFees(address(usdc));

        // Approve Bvb to withdraw USDC from Bull and Bear
        vm.prank(bull);
        usdc.approve(address(bvb), type(uint).max);
        vm.prank(bear);
        usdc.approve(address(bvb), type(uint).max);

        // Taker (Bull) match with this order
        vm.prank(bull);
        bvb.matchOrder(order, signature);

        // Give a NFT to the Bear + approve
        uint tokenId = 1234;
        doodles.mint(bear, tokenId);
        vm.prank(bear);
        doodles.setApprovalForAll(address(bvb), true);

        // Settle the contract
        vm.prank(bear);
        bvb.settleContract(order, tokenId);

        // Checks USDC balances
        assertEq(usdc.balanceOf(bull), initialBalanceBull - order.collateral - owedFeesBull, "Should have paid collateral and fees");
        assertEq(usdc.balanceOf(bear), initialBalanceBear + order.collateral - owedFeesBear, "Should have earnt collateral and paid fees");
        assertEq(usdc.balanceOf(address(bvb)), initialBalanceBvb + owedFeesBull + owedFeesBear, "Should have earnt fees");

        // Withdrawable fees
        assertEq(bvb.withdrawableFees(address(usdc)), initialWithdrawableFees + owedFeesBull + owedFeesBear, "Should have accumulated bull and bear fees");

        // NFT
        assertEq(doodles.ownerOf(tokenId), address(bvb), "Should have transfered NFT to Bvb");

        // Settled Contract
        assertEq(bvb.settledContracts(uint(orderHash)), true, "Should have flagged the contract as settled");
    }

    function testMatchingAndContractReclaim(BvbProtocol.Order memory order) public {
        vm.assume(order.premium <= type(uint).max / 1000);
        vm.assume(order.collateral <= type(uint).max / 1000);
        // Build the order
        order.validity = block.timestamp + 1 hours;
        order.expiry = block.timestamp + 1 days;
        order.nonce = 10;
        order.fee = bvb.fee();
        order.maker = bear;
        order.asset = address(usdc);
        order.collection = address(doodles);
        order.isBull = false;

        bytes32 orderHash = bvb.hashOrder(order);

        // Sign the order
        bytes memory signature = signOrderHash(bearPrivateKey, orderHash);

        // Calculate fees
        uint owedFeesBull = (order.collateral * fee) / 1000;
        uint owedFeesBear = (order.premium * fee) / 1000;

        // Give Bull and Bear enough USDC
        deal(address(usdc), bull, order.collateral + owedFeesBull);
        deal(address(usdc), bear, order.premium + owedFeesBear);

        // Initial balances
        uint initialBalanceBull = usdc.balanceOf(bull);
        uint initialBalanceBear = usdc.balanceOf(bear);
        uint initialBalanceBvb = usdc.balanceOf(address(bvb));
        uint initialWithdrawableFees = bvb.withdrawableFees(address(usdc));

        // Approve Bvb to withdraw USDC from Bull and Bear
        vm.prank(bull);
        usdc.approve(address(bvb), type(uint).max);
        vm.prank(bear);
        usdc.approve(address(bvb), type(uint).max);

        // Taker (Bull) match with this order
        vm.prank(bull);
        bvb.matchOrder(order, signature);

        // Expire the contract
        vm.warp(order.expiry + 1 hours);

        // Bull reclaim the contract
        vm.prank(bull);
        bvb.reclaimContract(order);

        // Checks USDC balances
        assertEq(usdc.balanceOf(bull), initialBalanceBull + order.premium - owedFeesBull, "Should have earnt premium and paid fees");
        assertEq(usdc.balanceOf(bear), initialBalanceBear - order.premium - owedFeesBear, "Should have paid premium and fees");
        assertEq(usdc.balanceOf(address(bvb)), initialBalanceBvb + owedFeesBull + owedFeesBear, "Should have earnt fees");

        // Withdrawable fees
        assertEq(bvb.withdrawableFees(address(usdc)), initialWithdrawableFees + owedFeesBull + owedFeesBear, "Should have accumulated bull and bear fees");

        // Reclaimed Contract
        assertEq(bvb.reclaimedContracts(uint(orderHash)), true, "Should have flagged the contract as reclaimed");
    }
}