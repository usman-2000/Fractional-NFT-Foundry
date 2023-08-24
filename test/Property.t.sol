// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../src/PropertyTokens.sol";
import "../src/PropertyNft.sol";

contract PropertyTest is Test {
    MyToken mytoken;
    PropertyNft propertynft;

    function setUp() public {
        propertynft = new PropertyNft();
        mytoken = new MyToken(address(propertynft));
    }
    // Minting an NFT to address(1)
    function testCreatingNft() public{
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
    }

    // listing the NFT to the marketplace
    function testingListingProperty() public{
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        assertEq(mytoken.totalSupply(), 1000);
    }

    //Different addresses buy shares in the property
    function testBuyingShares() public{
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        assertEq(mytoken.totalSupply(), 1000);
        vm.deal(address(2), 10 ether);
        vm.prank(address(2));
        mytoken.buyShare{value: 2.5 ether}(1, 25);
        assertEq(mytoken.balanceOf(address(2)), 250);
        vm.deal(address(5),4 ether);
        vm.prank(address(5));
        mytoken.buyShareFromShareholder(1, 1);
        assertEq(mytoken.balanceOf(address(2)), 0);
        assertEq(mytoken.balanceOf(address(5)), 250);
    }

    function testCreatingNftAndListing() public {
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(mytoken), true);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(propertynft), true);
        // checking nft listed is true for beforetokentransfer()
        assertEq(propertynft.getListNft(1), true);

        // listing property to the contract
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        assertEq(mytoken.totalSupply(), 1000);

        // address(2) buy 25% of share
        vm.deal(address(2), 10 ether);
        vm.prank(address(2));
        mytoken.buyShare{value: 2.5 ether}(1, 25);
        assertEq(mytoken.balanceOf(address(2)), 250);

        // voting to sell
        vm.prank(address(2));
        mytoken.voteForSale(1);
        assertEq(mytoken.voters(), 1);

        // buying whole property
        vm.deal(address(3), 11 ether);
        vm.prank(address(3));
        mytoken.buyWholeProperty{value: 10 ether}(1);
        assertEq(propertynft.balanceOf(address(1)), 0);
        assertEq(propertynft.balanceOf(address(3)), 1);
        assertEq(address(address(3)).balance, 1 ether);
        assertEq(address(address(mytoken)).balance, 12.5 ether);

        // redeem
        vm.prank(address(2));
        mytoken.redeem(250, 1);
    }

    function testFailTransferWithoutVoting() public {
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(mytoken), true);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(propertynft), true);
        // checking nft listed is true for beforetokentransfer()
        assertEq(propertynft.getListNft(1), true);

        // listing property to the contract
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        assertEq(mytoken.totalSupply(), 1000);

        // address(2) buy 25% of share
        vm.deal(address(2), 10 ether);
        vm.prank(address(2));
        mytoken.buyShare{value: 2.5 ether}(1, 25);
        assertEq(mytoken.balanceOf(address(2)), 250);

        // Before transfer function will not allowed this
        vm.prank(address(1));
        propertynft.safeTransferFrom(address(1), address(5), 1);
    }

    function testBuyShare_FromShareholder() public {
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(mytoken), true);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(propertynft), true);
        // checking nft listed is true for beforetokentransfer()
        assertEq(propertynft.getListNft(1), true);

        // listing property to the contract
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        assertEq(mytoken.totalSupply(), 1000);

        // address(2) buy 25% of share
        vm.deal(address(2), 10 ether);
        vm.prank(address(2));
        mytoken.buyShare{value: 2.5 ether}(1, 25);
        assertEq(mytoken.balanceOf(address(2)), 250);

        // buying share from address(2) who has 25% share and 250 tokens
        vm.deal(address(5),4 ether);
        vm.prank(address(5));
        mytoken.buyShareFromShareholder(1, 1);
        assertEq(mytoken.balanceOf(address(2)), 0);
        assertEq(mytoken.balanceOf(address(5)), 250);

    }

    function testFail_BuyingSharesMoreThan_100_percent() public{
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(mytoken), true);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(propertynft), true);
        // checking nft listed is true for beforetokentransfer()
        assertEq(propertynft.getListNft(1), true);

        // listing property to the contract
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        assertEq(mytoken.totalSupply(), 1000);

        // address(2) buy 25% of share
        vm.deal(address(2), 10 ether);
        vm.prank(address(2));
        mytoken.buyShare{value: 2.5 ether}(1, 25);
        assertEq(mytoken.balanceOf(address(2)), 250);

        // address(3) buy 80%
        vm.deal(address(3),10 ether);
        vm.prank(address(3));
        mytoken.buyShare{value: 8 ether}(1, 80);
    }

    function test_Buy_Less_Than_100_percentShare() public{
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(mytoken), true);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(propertynft), true);
        // checking nft listed is true for beforetokentransfer()
        assertEq(propertynft.getListNft(1), true);

        // listing property to the contract
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        assertEq(mytoken.totalSupply(), 1000);

        // address(2) buy 25% of share
        vm.deal(address(2), 10 ether);
        vm.prank(address(2));
        mytoken.buyShare{value: 2.5 ether}(1, 25);
        assertEq(mytoken.balanceOf(address(2)), 250);

        // address(3) buy 25%
        vm.deal(address(3),10 ether);
        vm.prank(address(3));
        mytoken.buyShare{value: 2.5 ether}(1, 25);
        assertEq(mytoken.balanceOf(address(3)), 250);

        // checking remaining balance of address(1) (owner of the token)
        vm.prank(address(1));
        assertEq(mytoken.balanceOf(address(1)), 500);

        // checking remaining percentage
        assertEq(mytoken.remainingPercentage(),50);

    }

    function testWithdraw() public{
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(mytoken), true);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(propertynft), true);
        // checking nft listed is true for beforetokentransfer()
        assertEq(propertynft.getListNft(1), true);

        // listing property to the contract
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        assertEq(mytoken.totalSupply(), 1000);

        // address(2) buy 25% of share
        vm.deal(address(2), 10 ether);
        vm.prank(address(2));
        mytoken.buyShare{value: 2.5 ether}(1, 25);
        assertEq(mytoken.balanceOf(address(2)), 250);

        // address(3) buy 25%
        vm.deal(address(3),10 ether);
        vm.prank(address(3));
        mytoken.buyShare{value: 2.5 ether}(1, 25);
        assertEq(mytoken.balanceOf(address(3)), 250);

        // address(1) owner will call this
        vm.prank(address(1));
        mytoken.withdraw(1);

    }
}
