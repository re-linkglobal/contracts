// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma abicoder v2;

import "diamond-2/contracts/interfaces/IERC165.sol";
import "diamond-2/contracts/interfaces/IDiamondCut.sol";
import "diamond-2/contracts/interfaces/IDiamondLoupe.sol";
import "diamond-2/contracts/interfaces/IERC173.sol";
import "diamond-2/contracts/libraries/LibDiamond.sol";

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol" as MyERC721;

contract MarketplaceFacet {
    // Marketplace storage
    struct NFTMarketplaceStorage {
        bool initialized;
        mapping(address => bool) collectionsForSale;
        mapping(uint256 => address) nftListing;
        uint256[] nftListings;
        address payable owner;
    }

    struct AddNFTToMarketplaceArgs {
        address nftAddress;
        uint256 tokenId;
        uint256 price;
    }

    struct AddCollectionToMarketplaceArgs {
        address collectionAddress;
        uint256 price;
    }

    // Store the Marketplace storage in the diamond storage
    bytes32 public constant MARKETPLACE_STORAGE_POSITION =
        keccak256("diamond.contract.NFTMarketplace.storage");

    function nftMarketplaceStorage()
        internal
        pure
        returns (NFTMarketplaceStorage storage ns)
    {
        bytes32 position = MARKETPLACE_STORAGE_POSITION;
        assembly {
            ns.slot := position
        }
    }

    // Events
    event NFTAddedToMarketplace(
        address indexed collectionAddress,
        uint256 indexed tokenId
    );
    event NFTRemovedFromMarketplace(
        address indexed collectionAddress,
        uint256 indexed tokenId
    );
    event CollectionAddedToMarketplace(address indexed collectionAddress);
    event CollectionRemovedFromMarketplace(address indexed collectionAddress);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == nftMarketplaceStorage().owner, "NOT_OWNER");
        _;
    }

    // Constructor
    constructor(address payable _owner) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        LibDiamond.enforceIsContractOwner();
        nftMarketplaceStorage().owner = _owner;
        nftMarketplaceStorage().initialized = true;
    }

    // Add a collection to the marketplace
    function addCollectionToMarketplace(
        address _collectionAddress
    ) external onlyOwner {
        require(
            !nftMarketplaceStorage().collectionsForSale[_collectionAddress],
            "ALREADY_FOR_SALE"
        );
        nftMarketplaceStorage().collectionsForSale[_collectionAddress] = true;
        emit CollectionAddedToMarketplace(_collectionAddress);
    }

    // Remove a collection from the marketplace
    function removeCollectionFromMarketplace(
        address _collectionAddress
    ) external onlyOwner {
        require(
            nftMarketplaceStorage().collectionsForSale[_collectionAddress],
            "NOT_FOR_SALE"
        );
        nftMarketplaceStorage().collectionsForSale[_collectionAddress] = false;
        emit CollectionRemovedFromMarketplace(_collectionAddress);
    }

    // Add an NFT to the marketplace
    // function addNFTToMarketplace(
    //     address _collectionAddress,
    //     uint256 _tokenId
    // ) external {
    //     require(
    //         nftMarketplaceStorage().collectionsForSale[_collectionAddress],
    //         "COLLECTION_NOT_FOR_SALE"
    //     );
    //     require(
    //         IERC165(_collectionAddress).supportsInterface(
    //             IERC721(_collectionAddress).interfaceId()
    //         ),
    //         "NOT_NFT_COLLECTION"
    //     );
    //     IERC721(_collectionAddress).safeTransferFrom(
    //         msg.sender,
    //         address(this),
    //         _tokenId
    //     );
    //     nftMarketplaceStorage().nftListing[_tokenId] = _collectionAddress;
    //     nftMarketplaceStorage().nftListings.push(_tokenId);
    //     emit NFTAddedToMarketplace(_collectionAddress, _tokenId);
    // }

    // // Remove an NFT from the marketplace
    // function removeNFTFromMarketplace(uint256 _tokenId) external {
    //     address collectionAddress = nftMarketplaceStorage().nftListing[
    //         _tokenId
    //     ];
    //     require(collectionAddress != address(0), "NOT_FOR_SALE");
    //     // require(IERC721(collectionAddress).ownerOf(_tokenId) == address(this
    // }

    //   function addNFTToMarketplace(AddNFTToMarketplaceArgs memory args) external {
    //     LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    //     require(ds.contractOwner == msg.sender, "NFTMarketplace: Only contract owner can add NFT to marketplace");

    //     ds.nftPrice[args.nftAddress][args.tokenId] = args.price;
    //     ds.nftOnMarketplace[args.nftAddress][args.tokenId] = true;

    //     emit NFTAddedToMarketplace(args.nftAddress, args.tokenId, args.price);
    // }

    // function removeNFTFromMarketplace(address nftAddress, uint256 tokenId) external {
    //     LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    //     require(ds.contractOwner == msg.sender, "NFTMarketplace: Only contract owner can remove NFT from marketplace");

    //     ds.nftOnMarketplace[nftAddress][tokenId] = false;

    //     emit NFTRemovedFromMarketplace(nftAddress, tokenId);
    // }

    // function addCollectionToMarketplace(AddCollectionToMarketplaceArgs memory args) external {
    //     LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    //     require(ds.contractOwner == msg.sender, "NFTMarketplace: Only contract owner can add collection to marketplace");

    //     ds.collectionPrice[args.collectionAddress] = args.price;
    //     ds.collectionOnMarketplace[args.collectionAddress] = true;

    //     emit CollectionAddedToMarketplace(args.collectionAddress, args.price);
    // }

    // function removeCollectionFromMarketplace(address collectionAddress) external {
    //     LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    //     require(ds.contractOwner == msg.sender, "NFTMarketplace: Only contract owner can remove collection from marketplace");

    //     ds.collectionOnMarketplace[collectionAddress] = false;

    //     emit CollectionRemovedFromMarketplace(collectionAddress);
    // }

    // event NFTAddedToMarketplace(address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    // event NFTRemovedFromMarketplace(address indexed nftAddress, uint256 indexed tokenId);
    // event CollectionAddedToMarketplace(address indexed collectionAddress, uint256 price);
    // event CollectionRemovedFromMarketplace(address indexed collectionAddress);
}
