pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IERC1155InventoryCreator {
    function mint(
        address creator,
        address owner,
        string memory uri,
        bytes calldata data
    ) external returns (uint256 id, address token);
}

contract MyNFT1155Facet is
    ContextUpgradeable,
    AccessControlUpgradeable,
    IERC165Upgradeable,
    IERC1155Upgradeable,
    IERC1155ReceiverUpgradeable
{
    using AddressUpgradeable for address;

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC1155_RECEIVER = 0x4e2312e0;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IERC1155InventoryCreator public inventoryCreator;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _creators;

    function initialize(IERC1155InventoryCreator _inventoryCreator)
        public
        initializer
    {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ERC165_init_unchained();
        __MyNFT1155Facet_init_unchained(_inventoryCreator);
    }

    function __MyNFT1155Facet_init_unchained(
        IERC1155InventoryCreator _inventoryCreator
    ) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        inventoryCreator = _inventoryCreator;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC165 ||
            interfaceId == _INTERFACE_ID_ERC1155 ||
            interfaceId == _INTERFACE_ID_ERC1155_RECEIVER;
    }

    function setInventoryCreator(IERC1155InventoryCreator _inventoryCreator)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        inventoryCreator = _inventoryCreator;
    }

    function mint(
        address owner,
        string memory uri,
        bytes calldata data
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        (uint256 id, address token) = inventoryCreator.mint(
            address(this),
            owner,
            uri,
            data
        );
        _balances[owner] += 1;
        _creators[id] = _msgSender();
        emit TransferSingle(_msgSender(), address(0), owner, id, 1);
        emit URI(uri, id);
        return id;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            (uint256 id, address token) = inventoryCreator.mint(
                address(this),
                to,
                "",
                data
            );
            _balances[to] += 1;
            _creators[id] = _msgSender();
            emit TransferSingle(_msgSender(), address(0), to, id, amounts[i]);
            emit URI("", id);
        }
    }

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            _isSupportedInterface(type(IERC1155).interfaceId),
            "ERC1155: invalid interface"
        );
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );
        require(
            _isSupportedInterface(type(IERC1155).interfaceId),
            "ERC1155: invalid interface"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    function setURI(string memory newuri, uint256 id) public virtual {
        require(_msgSender() == _creators[id], "ERC1155: unauthorized");
        _setURI(newuri, id);
    }

    function setURI(string memory newuri) public virtual {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC1155: must have admin role to change uri"
        );
        _setURI(newuri);
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _uris[id];
    }

    function _setURI(string memory newuri, uint256 id) internal virtual {
        _uris[id] = newuri;
        emit URI(newuri, id);
    }

    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
        emit URI(newuri);
    }
}
