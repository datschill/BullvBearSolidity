// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "forge-std/Script.sol";

import {Base} from "./Base.s.sol";

import {BvbProtocol} from "../src/BvbProtocol.sol";

import {WETH} from "solmate/tokens/WETH.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ReclaimContract is Base {
    using SafeERC20 for IERC20;
    // address internal bvbAddress = 0xC976c932092ECcD8f328FfD85066C0c05ED54044;

    function run() external {
        BvbProtocol bvb = BvbProtocol(bvbAddress);
        uint16 fee = bvb.fee();

        BvbProtocol.Order memory order = defaultOrder(fee, bull, weth, doodles);
        
        // /!\ MUST USE A VALID MATCHED ORDER /!\

        vm.broadcast(bullPrivateKey);
        bvb.reclaimContract(order);
    }
}