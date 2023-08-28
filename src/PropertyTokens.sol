/**
 * @title MyToken
 * @dev ERC20 token contract for buying and selling shares of a property represented by an ERC721 token.
 * Allows listing a property for sale, buying and selling shares, voting for selling the entire property,
 * buying the entire property, withdrawing funds, and redeeming funds.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin-contracts/contracts/access/Ownable.sol";
import "@openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {PropertyNft} from "./PropertyNft.sol";

contract MyToken is ERC20, Ownable, ERC20Permit, IERC721Receiver {
    IERC721 public collection;
    PropertyNft public collectionContract;
    uint256 public remainingPercentage = 100e18;
    uint32 public oneTokenValue = 0.000000000000000001 ether;
    uint32 public sharers;
    uint32 public voters;
    // uint256 public remainingPercentage = 100 ;

    mapping(address => uint256) public stakeHoldersAndTheirPercentages; // address -> selling percentage
    mapping(address => uint256) public stockHoldersOfProperty; // address -> tokenId;
    mapping(uint256 => bool) public listed;
    mapping(uint256 => uint256) public TotalAmountOfTokensForNft; // tokenId -> total supply
    mapping(address => uint256) public shareholderShareSellingPrice; // address of shareholder->price
    mapping(uint256 => mapping(uint256 => address)) PropertySharers; // sharers -> tokenId -> address

    constructor(address _collection) ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        collection = IERC721(_collection);
        collectionContract = PropertyNft(_collection);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @dev Function to list a property for sale.
    /// @param _tokenId The ID of the property to be listed.
    /// @param _valueToken The value of the property in tokens.
    function listProperty(uint256 _tokenId, uint256 _valueToken) external payable {
        require(collection.ownerOf(_tokenId) == msg.sender, "Not the Owner of property");
        require(!listed[_tokenId], "Already Listed");
        _mint(msg.sender, _valueToken * (10 ** decimals()));
        TotalAmountOfTokensForNft[_tokenId] = _valueToken * (10 ** decimals());
        approve(address(this), _valueToken * (10 ** decimals()));
        listed[_tokenId] = true;
    }

    /// @dev Function to buy a share of a property.
    /// @param _tokenId The ID of the property for which the share is being bought.
    /// @param _share The percentage of the property's share being bought.
    function buyShare(uint256 _tokenId, uint256 _share) external payable {
        require(remainingPercentage / 1e18 >= _share / 10, "Can't buy this much share");
        // require(remainingPercentage>= _share/10, "You cannot buy this much share as the remaining share is less");

        // require((_share*1e18)/1e18 >= (minimumShareToBuy*1e18)/1e18, "Minimum shares to buy is 0.1%");
        uint256 NumberOfTokensToBuy = (TotalAmountOfTokensForNft[_tokenId] * _share / 10) / 100;
        uint256 totalPrice = NumberOfTokensToBuy * oneTokenValue;
        require(msg.value >= totalPrice, "Insufficient Balance");
        ERC20(address(this)).transferFrom(collection.ownerOf(_tokenId), msg.sender, NumberOfTokensToBuy);
        remainingPercentage -= 1e18 * _share / 10;
        // remainingPercentage -= _share/10;

        stakeHoldersAndTheirPercentages[msg.sender] = _share / 10;
        stockHoldersOfProperty[msg.sender] = _tokenId;
        sharers += 1;
        PropertySharers[sharers][_tokenId] = msg.sender;
        approve(address(this), NumberOfTokensToBuy);
    }

    /// @dev Function to sell a share of a property
    /// @param _tokenId The ID of the property for which the share is being sold
    /// @param _share The percentage of the property's share being sold
    /// @param _price The selling price for the share
    function sellShare(uint256 _tokenId, uint256 _share, uint256 _price) external payable {
        require(stakeHoldersAndTheirPercentages[msg.sender] == _share, "Don't have this much share");
        require(stockHoldersOfProperty[msg.sender] == _tokenId, "you didn't buy share in this Property");
        shareholderShareSellingPrice[msg.sender] = _price;
    }
    
    /// @dev Function to buy shares of a property from another shareholder.
    /// @param _tokenId The ID of the property for which the shares are being bought.
    /// @param _sharers The index of the shareholder from whom the shares are being bought.
    function buyShareFromShareholder(uint256 _tokenId, uint32 _sharers) external payable {
        require(msg.value >= shareholderShareSellingPrice[PropertySharers[_sharers][_tokenId]], "Insufficient balance");
        uint256 TokensToSend = (
            TotalAmountOfTokensForNft[_tokenId] * stakeHoldersAndTheirPercentages[PropertySharers[_sharers][_tokenId]]
        ) / 100;
        ERC20(address(this)).transferFrom(PropertySharers[_sharers][_tokenId], msg.sender, TokensToSend);
        (bool sent,) = payable(PropertySharers[_sharers][_tokenId]).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        stockHoldersOfProperty[msg.sender] == _tokenId;
        stockHoldersOfProperty[PropertySharers[_sharers][_tokenId]] = 0;
        stakeHoldersAndTheirPercentages[msg.sender] =
            stakeHoldersAndTheirPercentages[PropertySharers[_sharers][_tokenId]];
        stakeHoldersAndTheirPercentages[PropertySharers[_sharers][_tokenId]] = 0;
        PropertySharers[_sharers][_tokenId] = msg.sender;
    }

    
    /// @dev Function to allow a shareholder to vote for selling a specific property represented by a token.
    /// @param _tokenId The ID of the property token for which the shareholder wants to vote for selling.
    function voteForSale(uint256 _tokenId) public {
        require(stockHoldersOfProperty[msg.sender] == _tokenId, "You are not the shareholder");
        voters += 1;
    }
    

    function buyWholeProperty(uint256 _tokenId) public payable {
        require((voters / sharers) * 100 >= 50, "Majority don't want to sell");
        require(listed[_tokenId], "Not listed");
        uint256 totalPrice = totalSupply() * oneTokenValue;
        require(msg.value >= totalPrice, "Insufficient Balance");
        collectionContract.changeListing(false, _tokenId);

        collection.safeTransferFrom(collection.ownerOf(_tokenId), msg.sender, _tokenId);
    }

    function withdraw(uint256 _tokenId) public payable {
        require(collection.ownerOf(_tokenId) == msg.sender, "Caller is not the owner");
        (bool sent,) = payable(address(msg.sender)).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function redeem(uint256 _amount, uint256 _tokenId) external {
        require(stockHoldersOfProperty[msg.sender] == _tokenId, "You are not the shareholder");
        uint256 totalEther = address(this).balance;
        uint256 toRedeem = _amount * totalEther / totalSupply();
        _burn(msg.sender, _amount);
        (bool sent,) = payable(msg.sender).call{value: toRedeem}("");
        require(sent, "Failed to send Ether");
    }
}
