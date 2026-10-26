// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StudyToken} from "../src/StudyToken.sol";
import {TokenVault} from "../src/TokenVault.sol";

contract TokenVaultTest is Test {
    StudyToken token;
    TokenVault vault;

    address alice = makeAddr("alice");

    function setUp() public {
        token = new StudyToken();
        vault = new TokenVault(address(token));

        // Начальный выпуск получил этот тестовый контракт.
        // Передаём Алисе 20 STUDY для упражнений.
        token.transfer(alice, 20 ether);
    }

    function testDepositWithoutApprovalReverts() public {
        vm.startPrank(alice);

        // Любой revert достаточен для этой первой проверки.
        vm.expectRevert();
        vault.deposit(5 ether);

        vm.stopPrank();

        // Неудачное внесение ничего не изменило.
        assertEq(vault.deposits(alice), 0);
        assertEq(token.balanceOf(alice), 20 ether);
        assertEq(token.balanceOf(address(vault)), 0);
    }

    function testDepositAndPartialWithdraw() public {
        vm.startPrank(alice);

        token.approve(address(vault), 10 ether);
        vault.deposit(5 ether);

        assertEq(token.allowance(alice, address(vault)), 5 ether);
        assertEq(vault.deposits(alice), 5 ether);
        assertEq(token.balanceOf(alice), 15 ether);
        assertEq(token.balanceOf(address(vault)), 5 ether);

        vault.withdraw(2 ether);

        assertEq(vault.deposits(alice), 3 ether);
        assertEq(token.balanceOf(alice), 17 ether);
        assertEq(token.balanceOf(address(vault)), 3 ether);

        // Вывод не восстанавливает и не расходует allowance.
        assertEq(token.allowance(alice, address(vault)), 5 ether);

        vm.stopPrank();
    }

    function testWithdrawAboveDepositReverts() public {
        vm.startPrank(alice);

        token.approve(address(vault), 5 ether);
        vault.deposit(5 ether);

        vm.expectRevert(abi.encodeWithSelector(TokenVault.InsufficientDeposit.selector, 5 ether, 6 ether));
        vault.withdraw(6 ether);

        vm.stopPrank();

        assertEq(vault.deposits(alice), 5 ether);
        assertEq(token.balanceOf(address(vault)), 5 ether);
    }

    function testZeroDepositReverts() public {
        vm.startPrank(alice);

        vm.expectRevert(TokenVault.ZeroAmount.selector);
        vault.deposit(0);

        vm.stopPrank();
    }

    function testZeroWithdrawReverts() public {
        vm.startPrank(alice);

        vm.expectRevert(TokenVault.ZeroAmount.selector);
        vault.withdraw(0);

        vm.stopPrank();
    }

    function testUsersHaveSeparateDeposits() public {
        address bob = makeAddr("bob");
        token.transfer(bob, 10 ether);

        vm.startPrank(alice);
        token.approve(address(vault), 5 ether);
        vault.deposit(5 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(vault), 3 ether);
        vault.deposit(3 ether);

        // Борис не может вывести 4, хотя в Vault всего 8 STUDY.
        vm.expectRevert(abi.encodeWithSelector(TokenVault.InsufficientDeposit.selector, 3 ether, 4 ether));
        vault.withdraw(4 ether);

        // Свой вклад Борис может вывести полностью.
        vault.withdraw(3 ether);
        vm.stopPrank();

        assertEq(vault.deposits(alice), 5 ether);
        assertEq(vault.deposits(bob), 0);
        assertEq(token.balanceOf(address(vault)), 5 ether);
        assertEq(token.balanceOf(bob), 10 ether);
    }
}
