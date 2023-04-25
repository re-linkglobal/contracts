// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "diamond-2/contracts/libraries/LibDiamond.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTCollectionFacet {
    // Struct to represent a collection of NFTs
    struct NFTCollection {
        IERC721[] nfts;
        mapping(address => mapping(uint256 => bool)) nftExists;
        mapping(IERC721 => uint256[]) nftTokenIds;
    }

    // Mapping from collection name to the collection struct
    mapping(bytes32 => NFTCollection) private collections;

    // Add an NFT to a collection
    function addToCollection(
        bytes32 collectionName,
        address nftAddress,
        uint256 tokenId
    ) external {
        // Make sure the NFT exists
        IERC721 nft = IERC721(nftAddress);
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "NFTCollectionFacet: Sender does not own NFT"
        );

        // Make sure the NFT is not already in the collection
        NFTCollection storage collection = collections[collectionName];
        require(
            !collection.nftExists[nftAddress][tokenId],
            "NFTCollectionFacet: NFT already in collection"
        );

        // Add the NFT to the collection
        collection.nfts.push(nft);
        collection.nftExists[nftAddress][tokenId] = true;
        collection.nftTokenIds[nft].push(tokenId);
    }

    // Remove an NFT from a collection
    function removeFromCollection(
        bytes32 collectionName,
        address nftAddress,
        uint256 tokenId
    ) external {
        // Make sure the NFT is in the collection
        NFTCollection storage collection = collections[collectionName];
        require(
            collection.nftExists[nftAddress][tokenId],
            "NFTCollectionFacet: NFT not in collection"
        );

        // Remove the NFT from the collection
        uint256[] storage tokenIds = collection.nftTokenIds[
            IERC721(nftAddress)
        ];
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                // Swap the element to remove to the end of the array and then pop it
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                break;
            }
        }
        collection.nftExists[nftAddress][tokenId] = false;
    }

    // Get the value of a collection (sum of all NFT values)
    function getCollectionValue(
        bytes32 collectionName
    ) external view returns (uint256) {
        NFTCollection storage collection = collections[collectionName];
        uint256 value = 0;
        for (uint i = 0; i < collection.nfts.length; i++) {
            IERC721 nft = collection.nfts[i];
            uint256[] storage tokenIds = collection.nftTokenIds[nft];
            for (uint j = 0; j < tokenIds.length; j++) {
                uint256 tokenId = tokenIds[j];
                value += nft.ownerOf(tokenId).balance;
            }
        }
        return value;
    }
}
