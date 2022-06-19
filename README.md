# Yul721

- ERC721 contract written entirely in assembly, with custom storage mappings.
- Why? For fun and learning -- NOT intended to be used in production.
- Saves ~150 gas on mints compared to solmate/erc721

### Assumptions

- Edition size is less than 268431360 and all tokenId's are between 0-268431359
- Token name and symbol are both less than 32 bytes/characters
- name() and symbol() will not be used except for display purposes since they're not memory safe
- No more than the first 4095 slots are used by inheriting contracts

### Custom storage layout

- name: 0xb4deace9b1788ce1b03518da303be35696899d14b9f97084f0acb409d7135d4f
- symbol: 0x7d69ccd04f2a4cdb55d8c11fc025a501f1d8824144c5020daba01cb5bd77c117
- ownerOf: 0x1000-0xFFFFFFF
  - tokenId must be bound to max size of 0xFFFEFFF to prevent slot overwrite attack
- getApproved: 0x10000000-0x1FFFEFFF
  - tokenId must be bound to max size of 0xFFFEFFF to prevent slot overwrite attack
- balanceOf: owner address << 96
- isApprovedForAll: keccak(address owner, address spender)

### Todo (feel free to submit a PR)

- [ ] safeMint/safeTransfer
- [ ] Further gas optimizations
