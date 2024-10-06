## Incorrect validation of `HalbornLoans.sol#getLoan()` function

#### Vulnerability Details
The `HalbornLoans.sol#getLoan()` function is used to allow users to receive Halborn tokens based on their NFT collateral.

```solidity
    function getLoan(uint256 amount) external {
60:     require(
61:         totalCollateral[msg.sender] - usedCollateral[msg.sender] < amount,
62:         "Not enough collateral"
63:     );
        usedCollateral[msg.sender] += amount;
        token.mintToken(msg.sender, amount);
    }
```

As you can see, #L60~#L63 check whether there is enough collateral to receive a loan from the protocol.
However, incorrect validation allows users to receive loans without collateral.

#### Proof of Concept

```solidity
function test_getLoansWithIncorrectValidation() public {
    vm.deal(ALICE, 10 ether);
    vm.startPrank(ALICE);

    loans.getLoan(100 ether);
    assertEq(token.balanceOf(address(ALICE)), 100 ether);
}
```

As you can see, Alice receives 100 ether Halborn tokens without collateral.

#### recommendation
Modity the `HalbornLoans.sol#getLoan()` function as follows:

```solidity
    function getLoan(uint256 amount) external {
        require(
---         totalCollateral[msg.sender] - usedCollateral[msg.sender] < amount,
+++         totalCollateral[msg.sender] - usedCollateral[msg.sender] >= amount
            "Not enough collateral"
        );
        usedCollateral[msg.sender] += amount;
        token.mintToken(msg.sender, amount);
    }
```