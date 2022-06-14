// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    // event Transfer(address indexed from, address indexed to, uint256 indexed id);

    // event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    // event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    uint256 constant NAME_SLOT = 0x00;
    uint256 constant SYMBOL_SLOT = 0x01;

    function name() public view returns (string memory) {
        assembly {
            mstore(0x20, 0x20)
            let nameBytes := sload(NAME_SLOT)
            let nameLength
            for { let i := 0 } lt(i, 32) { i := add(i, 1) }
            {
                if iszero(shl(mul(add(i, 1), 0x08), nameBytes)) { 
                    nameLength := add(i, 1)
                    break
                }
            }
            mstore(0x60, nameBytes)
            mstore8(0x5f, nameLength)
            return(0x20, 0x60)
        }
    }

    function symbol() public view returns (string memory) {
        assembly {
            mstore(0x20, 0x20)
            let symbolBytes := sload(SYMBOL_SLOT)
            let symbolLength
            for { let i := 0 } lt(i, 32) { i := add(i, 1) }
            {
                if iszero(shl(mul(add(i, 1), 0x08), symbolBytes)) { 
                    symbolLength := add(i, 1)
                    break
                }
            }
            mstore(0x60, symbolBytes)
            mstore8(0x5f, symbolLength)
            return(0x20, 0x60)
        }
    }

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 constant OWNER_OF_START_SLOT = 0x1000;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        assembly {
            owner := sload(add(OWNER_OF_START_SLOT, id))

            // require(owner != address(0), "NOT_MINTED");
            if iszero(owner) {
                // 0x4E4F545F4D494E544544: "NOT_MINTED"
                mstore(0x00, 0x4E4F545F4D494E544544)
                revert(0x16, 0x0a)
            }
        }
    }

    uint256 constant BALANCE_OF_SLOT_MUL = 0x100000000000000000000000;

    function balanceOf(address owner) public view virtual returns (uint256 _balance) {
        assembly {
            // require(owner != address(0), "ZERO_ADDRESS");
            if iszero(owner) {
                // 0x4E4F545F4D494E544544: "NOT_MINTED"
                mstore(0x00, 0x5A45524F5F41444452455353)
                revert(0x14, 0x0c)
            }

            _balance := sload(mul(BALANCE_OF_SLOT_MUL, owner))
        }
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 constant GET_APPROVED_START_SLOT = 0x10000000;

    function getApproved(uint256 id) public view returns (address approved) {
        assembly {
            approved := sload(add(GET_APPROVED_START_SLOT, id))
        }
    }

    function isApprovedForAll(address owner, address spender) public view returns (bool approvedForAll) {
        assembly {
            approvedForAll := sload(add(owner, spender))
        }
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    // Params must be: name, symbol
    constructor(string memory, string memory) {
        assembly {
            sstore(NAME_SLOT, mload(0xa0))
            sstore(SYMBOL_SLOT, mload(0xe0))
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        assembly {
            let owner := sload(add(OWNER_OF_START_SLOT, id))

            // require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");
            if iszero(or(eq(caller(), owner), sload(add(owner, caller())))) {
                // 0x4E4F545F415554484F52495A4544: "NOT_AUTHORIZED"
                mstore(0x00, 0x4E4F545F415554484F52495A4544)
                revert(0x12, 0x0E)
            }

            // Set approval
            sstore(add(GET_APPROVED_START_SLOT, id), spender)
            
            // emit Approval(owner, spender, id);
            log4(
                0,
                0,
                0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925,
                owner,
                spender,
                id
            )
        }
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        assembly {
            // Set approval for all
            sstore(add(caller(), operator), approved)

            // emit ApprovalForAll(msg.sender, operator, approved);
            log4(
                0,
                0,
                0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31,
                caller(),
                operator,
                approved
            )
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        assembly {
            // require(from == ownerOf[id], "WRONG_FROM");
            if iszero(eq(from, sload(add(OWNER_OF_START_SLOT, id)))) {
                // 0x57524F4E475F46524F4D: "WRONG_FROM"
                mstore(0x00, 0x57524F4E475F46524F4D)
                revert(0xB0, 0x0A)
            }

            // require(to != address(0), "INVALID_RECIPIENT");
            if iszero(to) {
                // 0x494E56414C49445F524543495049454E54: "INVALID_RECIPIENT"
                mstore(0x00, 0x494E56414C49445F524543495049454E54)
                revert(0x0F, 0x11)
            }

            // require(
            //     msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            //     "NOT_AUTHORIZED"
            // );
            if iszero(or(eq(caller(), from), or(sload(add(from, caller())), sload(add(GET_APPROVED_START_SLOT, id))))) {
                // 0x4E4F545F415554484F52495A4544: "NOT_AUTHORIZED"
                mstore(0x00, 0x4E4F545F415554484F52495A4544)
                revert(0x12, 0x0E)
            }

            // Underflow of the sender's balance is impossible because we check for
            // ownership above and the recipient's balance can't realistically overflow.

            // Decrement from balance
            sstore(mul(BALANCE_OF_SLOT_MUL, from), sub(sload(mul(BALANCE_OF_SLOT_MUL, from)), 1))
            // Increment to balance
            sstore(mul(BALANCE_OF_SLOT_MUL, to), add(sload(mul(BALANCE_OF_SLOT_MUL, to)), 1))

            // Set to address as owner
            sstore(add(OWNER_OF_START_SLOT, id), to)

            // Set approved to zero address
            sstore(add(GET_APPROVED_START_SLOT, id), 0)

            // emit Transfer(from, to, id);
            log4(
                0,
                0,
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                from,
                to,
                id
            )
        }
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

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool result) {
        assembly {
            result := or(
                // ERC165 Interface ID for ERC165
                eq(interfaceId, 0x01ffc9a7), 
                or(
                    // ERC165 Interface ID for ERC721
                    eq(interfaceId, 0x80ac58cd), 
                    // ERC165 Interface ID for ERC721Metadata
                    eq(interfaceId, 0x5b5e139f)
                )
            )
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        assembly {
            // require(to != address(0), "INVALID_RECIPIENT");
            if iszero(to) {
                // 0x494E56414C49445F524543495049454E54: "INVALID_RECIPIENT"
                mstore(0x00, 0x494E56414C49445F524543495049454E54)
                revert(0x0F, 0x11)
            }

            // require(ownerOf[id] == address(0), "ALREADY_MINTED");
            if iszero(iszero(sload(add(OWNER_OF_START_SLOT, id)))) {
                // 0x414C52454144595F4D494E544544: "ALREADY_MINTED"
                mstore(0x00, 0x414C52454144595F4D494E544544)
                revert(0x12, 0x0E)
            }

            // Increment balance of recipient
            // Counter overflow is incredibly unrealistic.
            sstore(mul(BALANCE_OF_SLOT_MUL, to), add(sload(mul(BALANCE_OF_SLOT_MUL, to)), 1))

            // Set ownerOf
            sstore(add(OWNER_OF_START_SLOT, id), to)

            // emit Transfer(address(0), to, id);
            log4(
                0,
                0,
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                0,
                to,
                id
            )
        }
    }

    function _burn(uint256 id) internal virtual {
        assembly {
            let owner := sload(add(OWNER_OF_START_SLOT, id))

            // require(owner != address(0), "NOT_MINTED");
            if iszero(owner) {
                // 0x4E4F545F4D494E544544: "NOT_MINTED"
                mstore(0x00, 0x4E4F545F4D494E544544)
                revert(0x16, 0x0a)
            }

            // Decrement balance of recipient
            // Ownership check above ensures no underflow.
            sstore(mul(BALANCE_OF_SLOT_MUL, owner), sub(sload(mul(BALANCE_OF_SLOT_MUL, owner)), 1))

            // Set owner to zero address
            sstore(add(OWNER_OF_START_SLOT, id), 0)

            // Clear approval
            sstore(add(GET_APPROVED_START_SLOT, id), 0)

            // emit Transfer(owner, address(0), id);
            log4(
                0,
                0,
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                owner,
                0,
                id
            )
        }
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
