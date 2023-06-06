// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Base} from "./Base.s.sol";

import {BvbProtocol} from "../../src/BvbProtocol.sol";

contract AllowBvbTestnet is Base {
    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        address collection = 0x6AE503d6e7446e33969BF54012EAe157ffDbBdD3;

        // Allow asset and collection
        BvbProtocol(bvbAddress).setAllowedAsset(weth, true);
        BvbProtocol(bvbAddress).setAllowedCollection(collection, true);

        vm.stopBroadcast();
    }
}

contract TransferOwnershipTestnet is Base {
    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        address newOwner = 0xb2729ffb78Aa67ABbE6C9583328b73664699a6eE;

        BvbProtocol(bvbAddress).transferOwnership(newOwner);

        vm.stopBroadcast();
    }
}