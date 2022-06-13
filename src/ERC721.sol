// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    uint256 constant NAME_SLOT = 0x0;
    uint256 constant SYMBOL_SLOT = 0x1;

    function name() public view returns (string memory _name) {
        assembly {
            _name := sload(NAME_SLOT)
        }
    }

    function symbol() public view returns (string memory _symbol) {
        assembly {
            _symbol := sload(SYMBOL_SLOT)
        }
    }

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 constant OWNER_OF_START_SLOT = 0x1000;

    function _getOwnerOf(uint256 id) internal view returns (address result) {
        assembly {
            result := sload(add(OWNER_OF_START_SLOT, id))
        }
    }

    function _setOwnerOf(uint256 id, address owner) internal {
        assembly {
            sstore(add(OWNER_OF_START_SLOT, id), owner)
        }
    }

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _getOwnerOf(id)) != address(0), "NOT_MINTED");
    }

    uint256 constant BALANCE_OF_SLOT_POS = 0x100000000000000000000000;

    function _getBalanceOf(address addr) internal view returns (uint256 result) {
        assembly {
            result := sload(shl(BALANCE_OF_SLOT_POS, addr))
        }
    }

    function _setBalanceOf(address addr, uint256 bal) internal {
        assembly {
            sstore(shl(BALANCE_OF_SLOT_POS, addr), bal)
        }
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _getBalanceOf(owner);
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 constant GET_APPROVED_START_SLOT = 0x10000000;

    function _getApproved(uint256 id) internal view returns (address result) {
        assembly {
            result := sload(add(GET_APPROVED_START_SLOT, id))
        }
    }

    function _setApproved(uint256 id, address operator) internal {
        assembly {
            sstore(add(GET_APPROVED_START_SLOT, id), operator)
        }
    }

    function getApproved(uint256 id) public view returns (address) {
        return _getApproved(id);
    }

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        assembly {
            sstore(NAME_SLOT, _name)
            sstore(SYMBOL_SLOT, _symbol)
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _getOwnerOf(id);

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        _setApproved(id, spender);

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _getOwnerOf(id), "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == _getApproved(id),
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _setBalanceOf(from, _getBalanceOf(from) - 1);

            _setBalanceOf(to, _getBalanceOf(to) + 1);
        }

        _setOwnerOf(id, to);

        _setApproved(id, address(0));

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_getOwnerOf(id) == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _setBalanceOf(to, _getBalanceOf(to) + 1);
        }

        _setOwnerOf(id, to);

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _getOwnerOf(id);

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _setBalanceOf(owner, _getBalanceOf(owner) - 1);
        }

        _setOwnerOf(id, address(0));

        _setApproved(id, address(0));

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
