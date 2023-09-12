// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HormigaMarketplace is ReentrancyGuard, Ownable {
    struct Listing {
        uint256 tokenId;
        address owner;
        string dataOrigen;
        string dataDestino;
        uint256 precio;
    }

    IERC721 public remitoHormiga;
    IERC20 public hormigaToken;

    mapping(uint256 => Listing) public listings;

    event Listed(uint256 indexed tokenId, address indexed owner, uint256 precio);
    event Unlisted(uint256 indexed tokenId);
    event Purchased(uint256 indexed tokenId, address indexed newOwner, address indexed previousOwner, uint256 precio);

    constructor(address _remitoHormiga, address _hormigaToken) {
        remitoHormiga = IERC721(_remitoHormiga);
        hormigaToken = IERC20(_hormigaToken);
    }

    function list(uint256 tokenId, string memory dataOrigen, string memory dataDestino, uint256 precio) external nonReentrant {
        address owner = remitoHormiga.ownerOf(tokenId);
        require(owner == msg.sender, "You do not own this NFT");

        remitoHormiga.transferFrom(owner, address(this), tokenId);
        
        listings[tokenId] = Listing({
            tokenId: tokenId,
            owner: owner,
            dataOrigen: dataOrigen,
            dataDestino: dataDestino,
            precio: precio
        });

        emit Listed(tokenId, owner, precio);
    }

    function unlist(uint256 tokenId) external nonReentrant {
        require(listings[tokenId].owner == msg.sender, "You do not own this listing");

        remitoHormiga.transferFrom(address(this), msg.sender, tokenId);
        
        delete listings[tokenId];

        emit Unlisted(tokenId);
    }

    function purchase(uint256 tokenId) external nonReentrant {
        Listing memory listing = listings[tokenId];

        require(listing.owner != address(0), "Listing does not exist");
        require(hormigaToken.transferFrom(msg.sender, listing.owner, listing.precio), "Purchase failed");

        remitoHormiga.transferFrom(address(this), msg.sender, tokenId);

        delete listings[tokenId];

        emit Purchased(tokenId, msg.sender, listing.owner, listing.precio);
    }
}
