// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Script.sol";

import {Base} from "./Base.s.sol";

import {BvbProtocol} from "../src/BvbProtocol.sol";

import {BvbERC721} from "../mocks/BvbERC721.sol";

import {WETH} from "solmate/tokens/WETH.sol";

contract SettleContract is Base {
    // address internal bvbAddress = 0xC976c932092ECcD8f328FfD85066C0c05ED54044;

    function run() external {
        BvbProtocol bvb = BvbProtocol(bvbAddress);
        uint16 fee = bvb.fee();

        // Deposits
        vm.broadcast(bullPrivateKey);
        WETH(payable(weth)).deposit{value: 0xffffffffff}();
        vm.broadcast(bearPrivateKey);
        WETH(payable(weth)).deposit{value: 0xffffffffff}();

        // Approvals
        vm.broadcast(bullPrivateKey);
        WETH(payable(weth)).approve(bvbAddress, type(uint).max);
        vm.broadcast(bearPrivateKey);
        WETH(payable(weth)).approve(bvbAddress, type(uint).max);

        vm.startBroadcast(deployerPrivateKey);
        // NFT
        BvbERC721 mockNFT = new BvbERC721("Mock NFT", "MNFT");
        uint tokenId = 1234;
        mockNFT.mint(bear, tokenId);
        // Allow this collection on Bvb
        bvb.setAllowedCollection(address(mockNFT), true);
        vm.stopBroadcast();

        // Approve Bvb
        vm.broadcast(bearPrivateKey);
        mockNFT.setApprovalForAll(bvbAddress, true);
        

        uint bullNonce = bvb.minimumValidNonce(bull);

        BvbProtocol.Order memory order = defaultOrder(fee, bull, weth, doodles);
        order.validity = block.timestamp + 1 hours;
        order.collection = address(mockNFT);
        order.nonce = bullNonce;

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrderHash(bullPrivateKey, orderHash);

        vm.startBroadcast(bearPrivateKey);

        bvb.matchOrder(order, signature);

        bvb.settleContract(order, tokenId);

        vm.stopBroadcast();
    }
}