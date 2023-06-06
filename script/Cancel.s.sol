// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Script.sol";

import {Base} from "./Base.s.sol";

import {BvbProtocol} from "../src/BvbProtocol.sol";

import {WETH} from "solmate/tokens/WETH.sol";

contract Cancel is Base {
    // address internal bvbAddress = 0xC976c932092ECcD8f328FfD85066C0c05ED54044;

    function run() external {
        BvbProtocol bvb = BvbProtocol(bvbAddress);
        uint16 fee = bvb.fee();

        BvbProtocol.Order memory order = defaultOrder(fee, bull, weth, doodles);

        uint bullNonce = bvb.minimumValidNonce(bull);

        vm.startBroadcast(bullPrivateKey);
        bvb.cancelOrder(order);

        bvb.setMinimumValidNonce(bullNonce + 1);
        vm.stopBroadcast();
    }
}