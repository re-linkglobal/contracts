pragma solidity ^0.8.0;

import "diamond-2/contracts/libraries/LibDiamond.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract NFTFactory {
    enum NFTType {
        ERC721,
        ERC1155
    }

    event NFTCreated(
        address indexed creator,
        uint256 indexed tokenId,
        NFTType nftType
    );

    function createNFT(
        NFTType nftType,
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 initialSupply
    ) external returns (uint256) {
        address nftAddress;
        uint256 tokenId;

        if (nftType == NFTType.ERC721) {
            // Create the ERC-721 token
            nftAddress = address(new ERC721Facet());
            ERC721Facet(nftAddress).initialize(name, symbol, uri);
            tokenId = ERC721Facet(nftAddress).mint(msg.sender);
        } else {
            // Create the ERC-1155 token
            nftAddress = address(new ERC1155Facet());
            ERC1155Facet(nftAddress).initialize(uri);
            ERC1155Facet(nftAddress).mint(msg.sender, 0, initialSupply, "");
            tokenId = 0;
        }

        emit NFTCreated(msg.sender, tokenId, nftType);

        return LibDiamond.contractID(nftAddress);
    }
}
