// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StudyToken is ERC20 {
    constructor() ERC20("Study Token", "STUDY") {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
}
