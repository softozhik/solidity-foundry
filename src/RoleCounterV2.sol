// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleCounterV2 is AccessControl {
    bytes32 public constant OPERATOR_ADMIN_ROLE =
        keccak256("OPERATOR_ADMIN_ROLE");

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public count;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ADMIN_ROLE, msg.sender);

        _setRoleAdmin(OPERATOR_ROLE, OPERATOR_ADMIN_ROLE);

        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    function increment() external onlyRole(OPERATOR_ROLE) {
        count += 1;
    }

    function addOperator(
        address account
    ) external onlyRole(OPERATOR_ADMIN_ROLE) {
        _grantRole(OPERATOR_ROLE, account);
    }

    function removeOperator(
        address account
    ) external onlyRole(OPERATOR_ADMIN_ROLE) {
        _revokeRole(OPERATOR_ROLE, account);
    }

    function isOperator(address account) external view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }
}
