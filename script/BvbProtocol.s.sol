// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Script.sol";

import {Base} from "./Base.s.sol";

import {BvbProtocol} from "../src/BvbProtocol.sol";

contract DeployBvb is Base {
    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        BvbProtocol bvb = new BvbProtocol(20, weth);

        bvb.setAllowedAsset(weth, true);
        bvb.setAllowedCollection(doodles, true);

        vm.stopBroadcast();
    }
}