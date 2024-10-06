## Incorrect implementation of the `HalbornLoans.sol#returnLoan()`

#### Vulnerability Details
The `HalbornLoans.sol#returnLoan()` function is used by the user to repay his loan.

```solidity
    function returnLoan(uint256 amount) external {
        require(usedCollateral[msg.sender] >= amount, "Not enough collateral");
        require(token.balanceOf(msg.sender) >= amount);
71:     usedCollateral[msg.sender] += amount;
        token.burnToken(msg.sender, amount);
    }
```

However, as you can see in #L71, `usedCollateral`, which indicates the used collateral, is increased rather than decreased by the amount of collateral the user repaid.
Users attempt to withdraw their NFTs used as collateral using the `HalbornLoans.sol#withdrawCollateral()` function, but it always fails due to an incorrect calculation of `usedCollateral`.
Therefore, the user's NFT is permanently locked to the contract.

#### Proof of Concept

```solidity
    function test_returnLoansWithIncorrectImplementation() public {
        vm.deal(ALICE, 10 ether);
        vm.startPrank(ALICE);
        nft.mintBuyWithETH{value: 1 ether}();
        nft.approve(address(loans), uint256(1));
        loans.depositNFTCollateral(uint256(1));
        
        loans.getLoan(2 ether);

        loans.returnLoan(2 ether);

        loans.withdrawCollateral(uint256(1));
        vm.stopPrank();
    }
```

#### Recommendation
Modify the `HalbornLoans.sol#returnLoan()` function as follows:
```solidity
    function returnLoan(uint256 amount) external {
        require(usedCollateral[msg.sender] >= amount, "Not enough collateral");
        require(token.balanceOf(msg.sender) >= amount);
---     usedCollateral[msg.sender] += amount;
+++     usedCollateral[msg.sender] -= amount
        token.burnToken(msg.sender, amount);
    }
```