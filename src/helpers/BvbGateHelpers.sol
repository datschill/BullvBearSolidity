// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BvbGateHelpers is Ownable {
    address[] public gateCollections;

    constructor() {}

    function hasAccess(address wallet) public view returns (bool) {
        for (uint256 i; i<gateCollections.length; i++) {
            address collection = gateCollections[i];
            if (IERC721(collection).balanceOf(wallet) > 0) {
                return true;
            }
        }
        return false;
    }

    function addGateCollection(address collection) external onlyOwner {
        gateCollections.push(collection);
    }

    function removeGateCollection(uint256 indexCollection) external onlyOwner {
        gateCollections[indexCollection] = gateCollections[gateCollections.length - 1];
        gateCollections.pop();
    }

    function getGateCollections() external view returns (address[] memory) {
        return gateCollections;
    }
}