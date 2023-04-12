// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NonFungibleToken is ERC721 {
    uint256 tokenId = 1;
    constructor() ERC721("Non Fungible Token", "NFT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "bmd.com/";
    }

    function safeMint(address to) public{
        _safeMint(to, tokenId);
        tokenId++;
    }
}