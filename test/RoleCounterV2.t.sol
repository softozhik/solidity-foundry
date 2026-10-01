// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {RoleCounterV2} from "../src/RoleCounterV2.sol";

contract RoleCounterV2Test is Test {
    RoleCounterV2 counter;

    address admin = makeAddr("admin");
    address operatorAdmin = makeAddr("operatorAdmin");
    address operator = makeAddr("operator");
    address stranger = makeAddr("stranger");

    function setUp() public {
        vm.prank(admin);
        counter = new RoleCounterV2();
    }

    function test_InitialRolesAndRoleAdmin() public view {
        assertTrue(counter.hasRole(counter.DEFAULT_ADMIN_ROLE(), admin));

        assertTrue(counter.hasRole(counter.OPERATOR_ADMIN_ROLE(), admin));

        assertTrue(counter.hasRole(counter.OPERATOR_ROLE(), admin));

        assertEq(
            counter.getRoleAdmin(counter.OPERATOR_ROLE()),
            counter.OPERATOR_ADMIN_ROLE()
        );
    }

    function test_OperatorAdminCanAddOperator() public {
        vm.prank(admin);
        counter.addOperator(operator);

        assertTrue(counter.isOperator(operator));

        vm.prank(operator);
        counter.increment();

        assertEq(counter.count(), 1);
    }

    function test_OperatorCannotAddOperator() public {
        vm.prank(admin);
        counter.addOperator(operator);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                operator,
                counter.OPERATOR_ADMIN_ROLE()
            )
        );

        vm.prank(operator);
        counter.addOperator(stranger);
    }

    function test_OperatorAdminCanRemoveOperator() public {
        vm.prank(admin);
        counter.addOperator(operator);

        assertTrue(counter.isOperator(operator));

        vm.prank(admin);
        counter.removeOperator(operator);

        assertFalse(counter.isOperator(operator));
    }
}
