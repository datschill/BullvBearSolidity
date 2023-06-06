// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Script.sol";

import {BvbProtocol} from "../../src/BvbProtocol.sol";

import {WETH} from "solmate/tokens/WETH.sol";

contract Base is Script {
    address internal weth;
    address internal bvbAddress;
    address internal deployer;
    uint deployerPrivateKey;


    constructor() {
        weth = vm.envAddress("WETH_GOERLI");
        bvbAddress = vm.envAddress("BVB_GOERLI");
        deployerPrivateKey = vm.envUint("DEPLOYER_PK_GOERLI");
        deployer = vm.addr(deployerPrivateKey);
    }
}