// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AddressUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/AddressUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {}

    function __Multicall_init_unchained() internal onlyInitializing {}

    function multicall(
        bytes[] calldata data
    ) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // Use the low-level `delegatecall`
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            
            // If delegatecall fails, revert with the error message
            require(success, "Delegatecall failed");

            // Store the result of the call in the results array
            results[i] = result;
        }
        return results;
    }
}
