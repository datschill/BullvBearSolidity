// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Script.sol";

import {Base} from "./Base.s.sol";

import {BvbGateHelpers} from "../../src/helpers/BvbGateHelpers.sol";

contract BvbGateHelpersPolygon is Base {
    function run() external {
        vm.startBroadcast(polygonDeployerPrivateKey);

        address collection = 0x4f1610e5708A6E8C3D87D08ee61C12Ba84311A96;

        BvbGateHelpers(bvbGateHelpersAddress).addGateCollection(collection);

        vm.stopBroadcast();
    }
}