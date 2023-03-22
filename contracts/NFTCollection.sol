// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "diamond-2/contracts/libraries/LibDiamond.sol";
import "diamond-2/contracts/facets/DiamondCutFacet.sol";
import "diamond-2/contracts/facets/DiamondLoupeFacet.sol";
import "diamond-2/contracts/facets/OwnershipFacet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCollection is ERC721, ERC721Enumerable, Ownable {
    uint256 private _currentTokenId = 0;
    mapping(address => bool) private _authorizedMinters;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function mint(address to) external onlyAuthorizedMinter returns (uint256) {
        uint256 newTokenId = _getNextTokenId();
        _mint(to, newTokenId);
        _incrementTokenId();
        return newTokenId;
    }

    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId + 1;
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function addAuthorizedMinter(address minter) external onlyOwner {
        _authorizedMinters[minter] = true;
    }

    function removeAuthorizedMinter(address minter) external onlyOwner {
        _authorizedMinters[minter] = false;
    }

    function isAuthorizedMinter(address minter) external view returns (bool) {
        return _authorizedMinters[minter];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyAuthorizedMinter() {
        require(
            _authorizedMinters[msg.sender],
            "NFTCollection: caller is not an authorized minter"
        );
        _;
    }

    // The DiamondCutFacet allows us to add or remove functions from the contract
    function diamondCut(bytes[] calldata _data, address _facet) external {
        LibDiamond.enforceIsContractOwner();
        DiamondCutFacet diamondCutFacet = DiamondCutFacet(
            payable(address(this))
        );
        diamondCutFacet.diamondCut(_data, _facet);
    }

    // The DiamondLoupeFacet allows us to inspect the contract's diamond structure
    function facets() external view returns (address[] memory) {
        DiamondLoupeFacet diamondLoupeFacet = DiamondLoupeFacet(
            payable(address(this))
        );
        return diamondLoupeFacet.facets();
    }

    function upgrade() external onlyOwner {
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
        DiamondCutFacet diamondCutFacet = DiamondCutFacet(
            payable(address(this))
        );
        diamondCutFacet.diamondCut(diamondCutData, address(this));
    }

    // The OwnershipFacet allows us to transfer ownership of the contract
    function transferOwnership(address newOwner) external onlyOwner {
        OwnershipFacet ownershipFacet = OwnershipFacet(payable(address(this)));
        ownershipFacet.transferOwnership(newOwner);
    }
}
