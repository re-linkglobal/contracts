pragma solidity ^0.8.3;

import "diamond-2/contracts/interfaces/IERC165.sol";
import "diamond-2/contracts/interfaces/IERC721.sol";
import "diamond-2/contracts/libraries/LibDiamond.sol";

contract ERC721Facet is IERC721, IERC165 {
    struct Token {
        address owner;
        uint256 tokenId;
    }

    mapping(address => mapping(uint256 => Token)) private _tokens;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    string private _name;
    string private _symbol;

    function initialize(
        string memory name,
        string memory symbol,
        string memory uri
    ) external {
        _name = name;
        _symbol = symbol;
        _registerInterface(type(IERC721).interfaceId);
    }

    function balanceOf(address owner) external view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _operatorApprovals[owner][to] = true;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        require(
            _owners[tokenId] != address(0),
            "ERC721: approved query for nonexistent token"
        );
        return
            _operatorApprovals[_owners[tokenId]][msg.sender]
                ? msg.sender
                : address(0);
    }

    function setApprovalForAll(address operator, bool approved)
        external
        override
    {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        // solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) private {
        _operatorApprovals[_owners[tokenId]][to] = true;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC721Receiver(to).onERC721Received(
            msg.sender,
            from,
            tokenId,
            _data
        );
        return (retval == IERC721Receiver(to).onERC721Received.selector);
    }
}
