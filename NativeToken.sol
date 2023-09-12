// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HormigaTokenCoin is ERC20 {
    constructor() ERC20("Hormiga Token Coin", "HTC") {
        // Total supply: 7 billion
        uint256 totalSupply = 7 * (10**9) * (10**18); // 7 billion tokens with 18 decimals
        _mint(msg.sender, totalSupply);
    }
}
