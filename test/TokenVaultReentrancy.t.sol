// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {TokenVault} from "../src/TokenVault.sol";

// Только для теста: токен пытается вызвать Vault обратно.
contract CallbackToken is ERC20 {
    TokenVault public target;

    bool public armed;
    bool public attempted;
    bool public reentrySucceeded;
    bytes public reentryResult;

    constructor() ERC20("Callback Token", "CBT") {
        _mint(msg.sender, 20 ether);
    }

    function arm(TokenVault vault) external {
        target = vault;
        armed = true;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (armed) {
            armed = false;
            attempted = true;

            (bool success, bytes memory result) = address(target).call(abi.encodeCall(TokenVault.withdraw, (0)));

            reentrySucceeded = success;
            reentryResult = result;
        }

        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (armed) {
            armed = false;
            attempted = true;

            (bool success, bytes memory result) = address(target).call(abi.encodeCall(TokenVault.deposit, (0)));

            reentrySucceeded = success;
            reentryResult = result;
        }

        return super.transferFrom(from, to, amount);
    }
}

contract TokenVaultReentrancyTest is Test {
    function testWithdrawBlocksReentry() public {
        CallbackToken token = new CallbackToken();
        TokenVault vault = new TokenVault(address(token));

        token.approve(address(vault), 5 ether);
        vault.deposit(5 ether);

        // Включаем обратный вызов только перед выводом.
        token.arm(vault);

        vault.withdraw(2 ether);

        // Попытка действительно была и завершилась отказом.
        assertTrue(token.attempted());
        assertFalse(token.reentrySucceeded());

        // Отказ вызван именно ReentrancyGuard.
        assertEq(token.reentryResult(), abi.encodeWithSelector(ReentrancyGuard.ReentrancyGuardReentrantCall.selector));

        // Основной вывод успешно завершился.
        assertEq(vault.deposits(address(this)), 3 ether);
        assertEq(token.balanceOf(address(vault)), 3 ether);
        assertEq(token.balanceOf(address(this)), 17 ether);
    }

    function testDepositBlocksReentry() public {
        CallbackToken token = new CallbackToken();
        TokenVault vault = new TokenVault(address(token));

        token.approve(address(vault), 10 ether);
        vault.deposit(5 ether);

        // Включаем обратный вызов только перед депозитом.
        token.arm(vault);

        vault.deposit(5 ether);

        // Попытка действительно была и завершилась отказом.
        assertTrue(token.attempted());
        assertFalse(token.reentrySucceeded());
        assertEq(token.reentryResult(), abi.encodeWithSelector(ReentrancyGuard.ReentrancyGuardReentrantCall.selector));

        // Основной депозит успешно завершился.
        assertEq(vault.deposits(address(this)), 10 ether);
        assertEq(token.balanceOf(address(vault)), 10 ether);
        assertEq(token.balanceOf(address(this)), 10 ether);
        assertEq(token.allowance(address(this), address(vault)), 0);
    }
}
