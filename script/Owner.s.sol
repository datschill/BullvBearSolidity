// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Script.sol";

import {Base} from "./Base.s.sol";

import {BvbProtocol} from "../src/BvbProtocol.sol";

import {WETH} from "solmate/tokens/WETH.sol";

contract Owner is Base {
    // address internal bvbAddress = 0xC976c932092ECcD8f328FfD85066C0c05ED54044;

    function run() external {
        BvbProtocol bvb = BvbProtocol(bvbAddress);

        vm.startBroadcast(deployerPrivateKey);
        
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

        bvb.setAllowedAsset(usdc, true);
        bvb.setAllowedCollection(bayc, true);
        bvb.setFee(10);
        bvb.withdrawFees(usdc, deployer);

        vm.stopBroadcast();
    }
}