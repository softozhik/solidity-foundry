// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {StudyToken} from "../src/StudyToken.sol";

contract StudyTokenTest is Test {
    StudyToken token;

    address deployer = makeAddr("deployer");
    address alice = makeAddr("alice");

    uint256 constant INITIAL_SUPPLY = 1000 * 10 ** 18;

    function setUp() public {
        vm.prank(deployer);
        token = new StudyToken();
    }

    function test_Metadata() public view {
        assertEq(token.name(), "Study Token");
        assertEq(token.symbol(), "STUDY");
        assertEq(uint256(token.decimals()), 18);
    }

    function test_InitialSupply() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY);
        assertEq(token.balanceOf(alice), 0);
    }

    function test_Transfer() public {
        uint256 amount = 100 * 10 ** 18;

        vm.prank(deployer);
        bool success = token.transfer(alice, amount);

        assertTrue(success);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY - amount);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function test_CannotTransferMoreThanBalance() public {
        uint256 amount = INITIAL_SUPPLY + 1;

        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, deployer, INITIAL_SUPPLY, amount)
        );

        vm.prank(deployer);
        token.transfer(alice, amount);

        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY);
        assertEq(token.balanceOf(alice), 0);
    }
}
