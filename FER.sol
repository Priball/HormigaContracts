// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FERPool is ReentrancyGuard {
    address public owner;
    IERC20 public hormigaToken; // Tu token ERC20

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(address _hormigaToken) {
        owner = msg.sender;
        hormigaToken = IERC20(_hormigaToken);
    }

    // Permitir la retirada solo al dueño del contrato
    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        // Verificar si hay suficiente balance antes de retirar
        require(hormigaToken.balanceOf(address(this)) >= amount, "Insufficient balance");
        
        hormigaToken.transfer(owner, amount);
    }

    // Bloquear la capacidad de recibir ETH para evitar errores
    receive() external payable {
        revert("This contract does not accept ETH");
    }

    // Permitir el depósito solo de Hormiga Token
    function deposit(uint256 amount, address token) external nonReentrant {
        require(msg.sender != address(0), "Invalid address");
        require(token == address(hormigaToken), "Only Hormiga Token is accepted"); // Asegurando que solo se pueda depositar Hormiga Token
        require(hormigaToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }
}
