// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {RoleCounter} from "../src/RoleCounter.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract RoleCounterTest is Test {
    RoleCounter counter;

    address admin = makeAddr("admin");
    address operator = makeAddr("operator");
    address stranger = makeAddr("stranger");

    function setUp() public {
        vm.prank(admin);
        counter = new RoleCounter();
    }

    function test_InitialRoles() public view {
        assertTrue(counter.hasRole(counter.DEFAULT_ADMIN_ROLE(), admin));

        assertTrue(counter.hasRole(counter.OPERATOR_ROLE(), admin));

        assertFalse(counter.hasRole(counter.OPERATOR_ROLE(), operator));
    }

    function test_OperatorCanIncrement() public {
        vm.prank(admin);
        counter.addOperator(operator);

        vm.prank(operator);
        counter.increment();

        assertEq(counter.count(), 1);
    }

    function test_NonOperatorCannotIncrement() public {
        vm.expectRevert();

        vm.prank(stranger);
        counter.increment();

        assertEq(counter.count(), 0);
    }

    function test_AdminCanRemoveOperator() public {
        vm.prank(admin);
        counter.addOperator(operator);

        assertTrue(counter.isOperator(operator));

        vm.prank(admin);
        counter.removeOperator(operator);

        assertFalse(counter.isOperator(operator));
    }

    function test_NonOperatorCannotIncrementWithExactError() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                stranger,
                counter.OPERATOR_ROLE()
            )
        );

        vm.prank(stranger);
        counter.increment();
    }

    function test_OperatorCannotAddOperator() public {
        vm.prank(admin);
        counter.addOperator(operator);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                operator,
                counter.DEFAULT_ADMIN_ROLE()
            )
        );

        vm.prank(operator);
        counter.addOperator(stranger);
    }
}
