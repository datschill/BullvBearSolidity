// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Script.sol";

import {Base} from "./Base.s.sol";

import {BvbProtocolHelpers} from "../../src/helpers/BvbProtocolHelpers.sol";

contract DeployBvbHelpersTestnet is Base {
    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        new BvbProtocolHelpers(bvbAddress);

        vm.stopBroadcast();
    }
}