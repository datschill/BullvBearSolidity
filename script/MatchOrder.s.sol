// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Script.sol";

import {Base} from "./Base.s.sol";

import {BvbProtocol} from "../src/BvbProtocol.sol";

import {WETH} from "solmate/tokens/WETH.sol";

contract MatchOrder is Base {
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

        uint bullNonce = bvb.minimumValidNonce(bull);

        BvbProtocol.Order memory order = defaultOrder(fee, bull, weth, doodles);
        order.validity = block.timestamp + 1 hours;
        order.nonce = bullNonce;

        bytes32 orderHash = bvb.hashOrder(order);
        bytes memory signature = signOrderHash(bullPrivateKey, orderHash);

        vm.broadcast(bearPrivateKey);
        bvb.matchOrder(order, signature);
    }
}