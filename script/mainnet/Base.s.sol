// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Script.sol";

import {BvbProtocol} from "../../src/BvbProtocol.sol";

import {WETH} from "solmate/tokens/WETH.sol";

contract Base is Script {
    address internal weth;
    address internal bvbAddress;
    address internal deployer;
    address internal bvbGateHelpersAddress;
    uint polygonDeployerPrivateKey;
    uint deployerPrivateKey;


    constructor() {
        weth = vm.envAddress("WETH_MAINNET");
        bvbAddress = vm.envAddress("BVB_MAINNET");
        bvbGateHelpersAddress = vm.envAddress("BVB_GATE_HELPERS_POLYGON");
        deployerPrivateKey = vm.envUint("DEPLOYER_PK_MAINNET");
        polygonDeployerPrivateKey = vm.envUint("DEPLOYER_PK_POLYGON");
        deployer = vm.addr(deployerPrivateKey);
    }
}