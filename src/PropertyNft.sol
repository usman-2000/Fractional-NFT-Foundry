
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin-contracts/contracts/access/Ownable.sol";
import "@openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @title PropertyNft
/// @dev This contract represents a non-fungible token (NFT) contract for properties.
contract PropertyNft is ERC721, Ownable, ERC721Enumerable {
    mapping(uint256 => bool) public listNft;

    constructor() ERC721("PropertyNft", "P-NFT") {}

    /// @notice Mints a new token and assigns it to the specified address.
    /// @param to The address to which the token will be assigned.
    /// @param tokenId The ID of the token being minted.
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
        listNft[tokenId] = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        /// @dev Checks if the token is listed and prevents its transfer if it is listed.
        if (listNft[tokenId]) {
            require(false, "Transfer not allowed");
        }
    }

    /// @notice Changes the listing status of a token.
    /// @param _val The new listing status (true or false).
    /// @param _tokenId The ID of the token to change the listing status for.
    function changeListing(bool _val, uint256 _tokenId) public {
        listNft[_tokenId] = _val;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Gets the listing status of a token.
    /// @param _tokenId The ID of the token to get the listing status for.
    /// @return The listing status of the token.
    function getListNft(uint256 _tokenId) public view returns (bool) {
        return listNft[_tokenId];
    }
}