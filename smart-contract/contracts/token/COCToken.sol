// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract COC is ERC20, Ownable {
    constructor() ERC20("Coc Coc", "CCC") {
        _mint(msg.sender, 100 * 10**uint(decimals()));
    }

    function mint(address receiver, uint256 amount) external onlyOwner {
        _mint(receiver, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(owner(), amount);
    }

}