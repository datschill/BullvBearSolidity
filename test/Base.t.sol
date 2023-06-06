// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Test.sol";

import {BvbERC20} from "../mocks/BvbERC20.sol";
import {BvbERC721} from "../mocks/BvbERC721.sol";
import {BvbMaliciousBull} from "../mocks/BvbMaliciousBull.sol";

import {WETH} from "solmate/tokens/WETH.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

import {BvbProtocol} from "src/BvbProtocol.sol";

abstract contract Base is Test, ERC721TokenReceiver {
    BvbProtocol internal bvb;
    BvbERC20 internal usdc;
    BvbERC721 internal doodles;
    BvbMaliciousBull internal maliciousBull;
    WETH internal weth;

    uint internal bullPrivateKey;
    address internal bull;
    uint internal bearPrivateKey;
    address internal bear;

    uint16 internal fee = 20;

    constructor() {
        usdc = new BvbERC20("BvB USD Coin", "BVBUSDC", 6);
        doodles = new BvbERC721("BvB Doodles", "BVBDOODLE");
        weth = new WETH();

        bvb = new BvbProtocol(fee, address(weth));

        maliciousBull = new BvbMaliciousBull(address(bvb));

        bullPrivateKey = uint(0x1234);
        bull = vm.addr(bullPrivateKey);
        vm.label(bull, "Bull");

        bearPrivateKey = uint(0xabcd);
        bear = vm.addr(bearPrivateKey);
        vm.label(bear, "Bear");
    }

    function signOrder(uint privateKey, BvbProtocol.Order memory order) internal returns (bytes memory) {
        bytes32 orderHash = bvb.hashOrder(order);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, orderHash);
        return abi.encodePacked(r, s, v);
    }

    function signSellOrder(uint privateKey, BvbProtocol.SellOrder memory sellOrder) internal returns (bytes memory) {
        bytes32 sellOrderHash = bvb.hashSellOrder(sellOrder);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, sellOrderHash);
        return abi.encodePacked(r, s, v);
    }

    function signOrderHash(uint privateKey, bytes32 orderHash) internal returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, orderHash);
        return abi.encodePacked(r, s, v);
    }

    function signHash(uint privateKey, bytes32 _hash) internal returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, _hash);
        return abi.encodePacked(r, s, v);
    }

    function defaultOrder() internal view returns (BvbProtocol.Order memory) {
        return BvbProtocol.Order({
            premium: 0x9876,
            collateral: 0x9876abc,
            validity: block.timestamp + 1 hours,
            expiry: block.timestamp + 3 days,
            nonce: 10,
            fee: fee,
            maker: bull,
            asset: address(weth),
            collection: address(doodles),
            isBull: true
        });
    }

    function defaultSellOrder() internal view returns (BvbProtocol.SellOrder memory) {
        return BvbProtocol.SellOrder({
            orderHash: 0xb4d6a094d74d2efd2abcc2d04523cd48e2a9c1d4642155b7e6f6f62a1ddae44e,
            price: 0x12345,
            start: 0,
            end: block.timestamp + 3 days,
            nonce: 20,
            maker: bull,
            asset: address(weth),
            whitelist: new address[](0),
            isBull: true
        });
    }
}