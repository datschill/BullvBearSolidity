// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Base} from "./Base.s.sol";

import {BvbProtocol} from "../../src/BvbProtocol.sol";

contract AllowBvbMainnet is Base {
    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        address collection = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

        // Allow asset and collection
        BvbProtocol(bvbAddress).setAllowedAsset(weth, true);
        BvbProtocol(bvbAddress).setAllowedCollection(collection, true);

        vm.stopBroadcast();
    }
}