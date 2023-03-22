// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "diamond-2/contracts/facets/DiamondCutFacet.sol";

contract NFTCollectionUpdater {
    address public immutable collection;

    constructor(address _collection) {
        collection = _collection;
    }

    function upgrade() external {
        // Deploy the new facet contract
        NewFunctionalityFacet newFacet = new NewFunctionalityFacet();

        // Encode the data for the diamond cut
        bytes[] memory diamondCutData = new bytes[](1);
        diamondCutData[0] = abi.encodePacked(
            newFacet,
            DiamondCut.FacetCutAction.Add,
            bytes4(keccak256("")),
            0
        );

        // Call the diamond cut function to add the new facet to the diamond
        DiamondCutFacet diamondCutFacet = DiamondCutFacet(payable(collection));
        diamondCutFacet.diamondCut(diamondCutData, address(this));
    }
}
