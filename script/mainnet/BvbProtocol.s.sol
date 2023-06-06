// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Script.sol";

import {Base} from "./Base.s.sol";

import {BvbProtocol} from "../../src/BvbProtocol.sol";

contract DeployBvbMainnet is Base {
    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        new BvbProtocol(20, weth);

        vm.stopBroadcast();
    }
}