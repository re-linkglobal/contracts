// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "diamond-2/contracts/libraries/LibDiamond.sol";
import "diamond-2/contracts/interfaces/IDiamondLoupe.sol";
import "diamond-2/contracts/interfaces/IDiamondCut.sol";
import "diamond-2/contracts/interfaces/IERC173.sol";
import "diamond-2/contracts/interfaces/IERC165.sol";
import "./NFTFacet.sol"; // import your new facet contract

contract NFTDiamond {
    // more arguments are added to this struct
    // this avoids stack too deep errors
    struct DiamondArgs {
        address owner;
    }

    constructor(
        IDiamondCut.FacetCut[] memory _diamondCut,
        DiamondArgs memory _args
    ) payable {
        LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));
        // LibDiamond.setContractOwner(_args.owner);
        if (LibDiamond.contractOwner() == address(0)) {
            LibDiamond.setContractOwner(_args.owner);
        }

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // define a new facet cut structure for the NFTFacet contract
        IDiamondCut.FacetCut memory NFTFacetCut = IDiamondCut.FacetCut({
            facetAddress: address(new NFTFacet()),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: new bytes4[](0) // leave empty if no functions to add
        });

        // create an array of facet cuts containing the new NFTFacet cut
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](1);
        facetCuts[0] = NFTFacetCut;

        // add the new NFTFacet as a new facet to the Diamond contract
        LibDiamond.diamondCut(facetCuts, address(0), new bytes(0));
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
