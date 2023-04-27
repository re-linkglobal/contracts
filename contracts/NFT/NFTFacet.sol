// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma abicoder v2;

import "diamond-2/contracts/interfaces/IDiamondCut.sol";
import "diamond-2/contracts/interfaces/IERC173.sol";
import "diamond-2/contracts/interfaces/IERC165.sol";
import "diamond-2/contracts/interfaces/IDiamondLoupe.sol";
import "diamond-2/contracts/libraries/LibDiamond.sol";

interface INFT {
    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTFacet {
    struct BuyNFTArgs {
        address nftAddress;
        uint256 tokenId;
        uint256 price;
    }

    struct SellNFTArgs {
        address nftAddress;
        uint256 tokenId;
        uint256 price;
    }

    // Define the price struct
    struct NFTPrice {
        uint256 price;
        bool exists;
        address nftAddress;
    }

    // Mapping of NFT IDs to prices
    mapping(uint256 => NFTPrice) private nftPrices;

    function buyNFT(BuyNFTArgs memory args) external payable {
        // get the owner of the NFT
        address owner = INFT(args.nftAddress).ownerOf(args.tokenId);

        // ensure the NFT is for sale and the correct price was paid
        require(msg.value == args.price, "NFTFacet: incorrect payment amount");
        require(args.price > 0, "NFTFacet: invalid price");

        // transfer the NFT to the buyer
        INFT(args.nftAddress).transferFrom(owner, msg.sender, args.tokenId);

        // transfer payment to the seller
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "NFTFacet: transfer failed");
    }

    // Function to set the price of an NFT
    function setNFTPrice(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external {
        address owner = INFT(nftAddress).ownerOf(tokenId);
        require(msg.sender == owner, "Only the owner can set NFT prices");
        require(tokenId > 0, "Invalid NFT ID");
        nftPrices[nftAddress][tokenId] = NFTPrice(price, true, nftAddress);
    }

    // Function to query the price of an NFT
    function getNFTPrice(
        uint256 tokenId,
        address nftAddress
    ) external view returns (uint256) {
        require(nftPrices[tokenId].exists, "NFT price not set");
        return nftPrices[nftAddress][tokenId].price;
    }

    // function setNftPrice(
    //     address nftAddress,
    //     uint256 tokenId,
    //     uint256 price
    // ) private {
    //     LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    //     ds.nftPrice[nftAddress][tokenId] = price;
    // }

    function sellNFT(SellNFTArgs memory args) external {
        // ensure the seller owns the NFT
        require(
            INFT(args.nftAddress).ownerOf(args.tokenId) == msg.sender,
            "NFTFacet: not NFT owner"
        );

        // transfer the NFT to the contract
        INFT(args.nftAddress).transferFrom(
            msg.sender,
            address(this),
            args.tokenId
        );

        // store the NFT price
        // LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // ds.nftPrice[args.nftAddress][args.tokenId] = args.price;

        setNFTPrice(args.nftAddress, args.tokenId, args.price);

        // emit event
        emit NFTForSale(args.nftAddress, args.tokenId, args.price);
    }

    // function getNFTPrice(
    //     address nftAddress,
    //     uint256 tokenId
    // ) external view returns (uint256) {
    //     LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    //     return ds.nftPrice[nftAddress][tokenId];
    // }

    event NFTForSale(address nftAddress, uint256 tokenId, uint256 price);
}
