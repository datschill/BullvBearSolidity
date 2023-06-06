// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {BvbProtocol} from "../src/BvbProtocol.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

contract BvbMaliciousBull {

    address public immutable bvb;

    bool public shouldBlockTransfer;

    constructor(address _bvb) {
        bvb = _bvb;
        shouldBlockTransfer = true;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        if (shouldBlockTransfer) {
            // Do not accept a transfer from the BvbProtocol
            return bytes4(0);
        }
        return BvbMaliciousBull.onERC721Received.selector;
    }
    
    function setShouldBlockTransfer(bool shouldBlock) public {
        shouldBlockTransfer = shouldBlock;
    }
}