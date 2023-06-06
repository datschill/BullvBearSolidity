// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Script.sol";

import {BvbProtocol} from "../src/BvbProtocol.sol";

import {WETH} from "solmate/tokens/WETH.sol";

contract Base is Script {
    address internal weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal doodles = 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e;
    address internal bull;
    address internal bear;
    address internal deployer;
    uint bullPrivateKey;
    uint bearPrivateKey;
    uint deployerPrivateKey;
    address internal bvbAddress = 0x2e8880cAdC08E9B438c6052F5ce3869FBd6cE513;

    constructor() {
        bullPrivateKey = vm.envUint("PRIVATE_KEY_BULL");
        bearPrivateKey = vm.envUint("PRIVATE_KEY_BEAR");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bull = vm.addr(bullPrivateKey);
        bear = vm.addr(bearPrivateKey);
        deployer = vm.addr(deployerPrivateKey);
    }
    
    function signOrderHash(uint privateKey, bytes32 orderHash) internal returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, orderHash);
        return abi.encodePacked(r, s, v);
    }

    function defaultOrder(uint16 _fee, address _maker, address _asset, address _collection) internal view returns (BvbProtocol.Order memory) {
        return BvbProtocol.Order({
            premium: 0x9876,
            collateral: 0x9876abc,
            validity: block.timestamp + 1 hours,
            expiry: block.timestamp + 3 days,
            nonce: 10,
            fee: _fee,
            maker: _maker,
            asset: _asset,
            collection: _collection,
            isBull: true
        });
    }
}