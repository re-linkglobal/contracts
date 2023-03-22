// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

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
        override(ERC721)
    // override(ERC721, ERC721Enumerable)
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
}
