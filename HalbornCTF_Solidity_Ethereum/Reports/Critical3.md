## The `HalbornLoans` contract is incompatible with the `safeTransferFrom()` function.

#### Vulnerability Details
The `HalbornLoans.sol#depositNFTCollateral()` function uses the `safeTransferFrom()` function to receive an NFT.

```solidity
    function depositNFTCollateral(uint256 id) external {
        require(
            nft.ownerOf(id) == msg.sender,
            "Caller is not the owner of the NFT"
        );

40:     nft.safeTransferFrom(msg.sender, address(this), id);

        totalCollateral[msg.sender] += collateralPrice;
        idsCollateral[id] = msg.sender;
    }
```

The `safeTransferFrom()` function In the ERC-721 standard, safeTransferFrom ensures that if the recipient is a contract, it checks if the contract implements ERC721Receiver.

However, since the `HalbornLoans` contract does not implement ERC721Receiver, the `safeTransferFrom()` function always fails.

#### Proof of Concept

```solidity
    function test_depositNFTCollateralDOS() public {
        vm.deal(ALICE, 10 ether);
        vm.startPrank(ALICE);
        nft.mintBuyWithETH{value: 1 ether}();
        nft.approve(address(loans), uint256(1));
        loans.depositNFTCollateral(uint256(1));
    }
```

Result:
```solidity
Failing tests:
Encountered 1 failing test in test/Halborn.t.sol:HalbornTest
[FAIL: revert: ERC721: transfer to non ERC721Receiver implementer] test_depositNFTCollateralDOS() (gas: 154042)

Encountered a total of 1 failing tests, 0 tests succeeded
```

#### Recommendation
It is recommended to implement ERC721Receiver in the `HalbornLoans` contract.

```solidity
--- contract HalbornLoans is Initializable, UUPSUpgradeable, MulticallUpgradeable {
+++ contract HalbornLoans is Initializable, UUPSUpgradeable, MulticallUpgradeable, IERC721ReceiverUpgradeable {
        ...SNIP

        // Implement the onERC721Received function
+++     function onERC721Received(
+++         address operator,
+++         address from,
+++         uint256 tokenId,
+++         bytes calldata data
+++     ) external override returns (bytes4) {
+++         return this.onERC721Received.selector;
+++     }
    }
```