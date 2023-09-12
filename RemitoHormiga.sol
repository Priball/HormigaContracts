// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RemitoHormiga is ERC721Enumerable, ReentrancyGuard {
    
    struct Remito {
        uint256 valorDeclarado;
        uint256 recompensa;
        uint256 tiempoLimite;
        address liberatingWallet;
        string imageURI;
        bool entregado;
    }

    mapping(uint256 => Remito) public remitos;
    mapping(uint256 => address) public originalMinters;

    IERC20 public hormigaToken;
    address public FEV;
    address public FER;

    event Created(uint256 tokenId);
    event Delivered(uint256 tokenId);
    event RefundClaimed(uint256 tokenId, address minter);

    constructor(address _hormigaToken, address _FEV, address _FER) ERC721("Remito Hormiga", "RHT") {
        hormigaToken = IERC20(_hormigaToken);
        FEV = _FEV;
        FER = _FER;
    }

    function mintRemito(
        uint256 _valorDeclarado,
        uint256 _recompensa,
        uint256 _tiempoLimite,
        address _liberatingWallet,
        string memory _imageURI
    ) external nonReentrant {
        uint256 tokenId = totalSupply() + 1;

        Remito memory newRemito = Remito({
            valorDeclarado: _valorDeclarado,
            recompensa: _recompensa,
            tiempoLimite: _tiempoLimite,
            liberatingWallet: _liberatingWallet,
            imageURI: _imageURI,
            entregado: false
        });

        remitos[tokenId] = newRemito;
        originalMinters[tokenId] = msg.sender;

        require(hormigaToken.transferFrom(msg.sender, FER, _recompensa), "Failed to transfer reward to FER");
        require(hormigaToken.transferFrom(msg.sender, FEV, _valorDeclarado), "Failed to transfer declared value to FEV");

        _safeMint(msg.sender, tokenId);

        emit Created(tokenId);
    }

    modifier onlyLiberatingWallet(uint256 tokenId) {
        require(msg.sender == remitos[tokenId].liberatingWallet, "You are not the liberating wallet");
        _;
    }

    function deliver(uint256 tokenId) external nonReentrant onlyLiberatingWallet(tokenId) {
        Remito storage remito = remitos[tokenId];

        require(!remito.entregado, "Already delivered");
        require(block.timestamp <= remito.tiempoLimite, "Time limit exceeded");

        address currentOwner = ownerOf(tokenId);

        require(hormigaToken.transferFrom(FER, currentOwner, remito.recompensa), "Failed to transfer reward from FER");
        require(hormigaToken.transferFrom(FEV, currentOwner, remito.valorDeclarado), "Failed to transfer declared value from FEV");

        remito.entregado = true;

        emit Delivered(tokenId);
    }

    modifier onlyOriginalMinter(uint256 tokenId) {
        require(msg.sender == originalMinters[tokenId], "Only the original minter can claim a refund");
        _;
    }

    function claimRefund(uint256 tokenId) external nonReentrant onlyOriginalMinter(tokenId) {
        Remito storage remito = remitos[tokenId];

        require(!remito.entregado, "Already delivered");
        require(block.timestamp > remito.tiempoLimite, "Time limit not yet exceeded");

        require(hormigaToken.transferFrom(FEV, msg.sender, remito.valorDeclarado), "Failed to transfer declared value from FEV");

        emit RefundClaimed(tokenId, msg.sender);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return remitos[tokenId].imageURI;
    }

    function getCompletedNFTsByHolder(address holder) external view returns (uint256[] memory) {
        uint256 total = balanceOf(holder);
        uint256[] memory completedNFTs = new uint256[](total);

        uint256 counter = 0;
        for (uint256 i = 0; i < total; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(holder, i);
            if (remitos[tokenId].entregado) {
                completedNFTs[counter] = tokenId;
                counter++;
            }
        }

        uint256[] memory result = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = completedNFTs[i];
        }

        return result;
    }
}
