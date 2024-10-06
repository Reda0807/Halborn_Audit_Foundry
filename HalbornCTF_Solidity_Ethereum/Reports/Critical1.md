## Wrong Validation in the `HalbornNFT.sol#mintAirdrops()`

#### Vulnerability Details
The `HalbornNFT.sol#mintAirdrops()` function allows approved users to receive airdrops from the protocol.

```solidity
    function mintAirdrops(uint256 id, bytes32[] calldata merkleProof) external {
46:     require(_exists(id), "Token already minted");

        bytes32 node = keccak256(abi.encodePacked(msg.sender, id));
        bool isValidProof = MerkleProofUpgradeable.verifyCalldata(
            merkleProof,
            merkleRoot,
            node
        );
        require(isValidProof, "Invalid proof.");

        _safeMint(msg.sender, id, "");
    }
```

As you can see, the `mintAirdrops()` function uses the `_exists()` function of `ERC721Upgradeable` contract to check if the NFT has already been minted in #L46.

However, the `_exists()` function returns `true` if the NFT has already been minted.

```solidity
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
```

Therefore, #L46 will return `true` only if the NFT has already been minted, in which case the `_safeMint()` function will fail.
Conversely, if the NFT has not been minted, #L46 returns `false`.

As a result, the `mintAirdrops()` function will fail permanently, breaking the core functionality of the protocol.

#### Proof of Concept

```solidity
    function test_mintAirdropsWrongValidation() public {
        vm.startPrank(ALICE);
        nft.mintAirdrops(uint256(15), ALICE_PROOF_1);
        vm.stopPrank();
    }
```

#### Recommendation
Modify the `HalbornNFT.sol#mintAirdrops()` function as follows:

```solidity
    function mintAirdrops(uint256 id, bytes32[] calldata merkleProof) external {
---     require(_exists(id), "Token already minted");
+++     require(!_exists(id), "Token already minted");

        bytes32 node = keccak256(abi.encodePacked(msg.sender, id));
        bool isValidProof = MerkleProofUpgradeable.verifyCalldata(
            merkleProof,
            merkleRoot,
            node
        );
        require(isValidProof, "Invalid proof.");

        _safeMint(msg.sender, id, "");
    }
```