// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EtherToken is ERC20 {
    constructor() ERC20("Ether Token", "ET") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
}