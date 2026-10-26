// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenVault {
    IERC20 public immutable token;
    using SafeERC20 for IERC20;

    mapping(address => uint256) public deposits;

    error ZeroAmount();
    error InsufficientDeposit(uint256 available, uint256 requested);

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    function deposit(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        deposits[msg.sender] += amount;
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (deposits[msg.sender] < amount) revert InsufficientDeposit(deposits[msg.sender], amount);
        deposits[msg.sender] -= amount;
        token.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }
}
