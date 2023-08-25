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
    // // Minting an NFT to address(1)
    function testCreatingNft() public{
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
    }

    // // listing the NFT to the marketplace
    function testingListingProperty() public{
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        assertEq(mytoken.totalSupply(), 1000* (10** mytoken.decimals()));
    }

    // //Different addresses buy shares in the property
    function testBuyingShares() public{
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        vm.deal(address(2), 10 ether);
        vm.prank(address(2));
        mytoken.buyShare{value: 2 ether}(1, 1); // 0.1%
        assertEq(mytoken.remainingPercentage(),99900000000000000000); // isko agr 1e18 sy divide krengy to 99.9 answer aa jayega ... or wo divisin frontend py krayengy
        assertEq(mytoken.balanceOf(address(2)), 1000000000000000000);
        assertEq(mytoken.balanceOf(address(1)),999000000000000000000);

        vm.deal(address(3), 10 ether);
        vm.prank(address(3));
        mytoken.buyShare{value: 2 ether}(1, 1); // 0.1%
        assertEq(mytoken.remainingPercentage(),99800000000000000000); // 998e18 / 1e18 = 99.8%
        assertEq(mytoken.balanceOf(address(3)), 1000000000000000000);
        assertEq(mytoken.balanceOf(address(1)),998000000000000000000);


        vm.deal(address(4), 10 ether);
        vm.prank(address(4));
        mytoken.buyShare{value: 10 ether}(1, 10); // 1%
        assertEq(mytoken.remainingPercentage(),98800000000000000000);
        assertEq(mytoken.balanceOf(address(4)), 10000000000000000000);
    }

    // // Voting for sale so that owner can sell the Property to any other address
    function testVotingForSale() public{
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        vm.deal(address(2), 10 ether);
        vm.prank(address(2));
        mytoken.buyShare{value: 2 ether}(1, 1); // 0.1%
        assertEq(mytoken.remainingPercentage(),99900000000000000000);
        assertEq(mytoken.balanceOf(address(2)), 1000000000000000000);
        assertEq(mytoken.balanceOf(address(1)),999000000000000000000);

        // voting to sell
        vm.prank(address(2));
        mytoken.voteForSale(1);
        assertEq(mytoken.voters(), 1);
    }

    // // Buying whole property even if any address buy some shares from this
    function testBuyingWholeProperty() public{
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        vm.deal(address(2), 10 ether);
        vm.prank(address(2));
        mytoken.buyShare{value: 2 ether}(1, 1); // 0.1%
        assertEq(mytoken.remainingPercentage(),99900000000000000000);
        assertEq(mytoken.balanceOf(address(2)), 1000000000000000000);
        assertEq(mytoken.balanceOf(address(1)),999000000000000000000);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(mytoken), true);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(propertynft), true);

        // voting to sell
        vm.prank(address(2));
        mytoken.voteForSale(1);
        assertEq(mytoken.voters(), 1);

        // buying whole property
        vm.deal(address(3), 1000 ether);
        vm.prank(address(3));
        mytoken.buyWholeProperty{value: 1000 ether}(1);
        assertEq(propertynft.balanceOf(address(1)), 0);
        assertEq(propertynft.balanceOf(address(3)), 1);
        assertEq(address(address(mytoken)).balance, 1002 ether);
    }

    // // Shareholders can redeem their amount
    function testCreatingNftAndListingAndRedeem() public {
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        vm.deal(address(2), 10 ether);
        vm.prank(address(2));
        mytoken.buyShare{value: 2 ether}(1, 1); // 0.1%
        assertEq(mytoken.remainingPercentage(),99900000000000000000);
        assertEq(mytoken.balanceOf(address(2)), 1000000000000000000);
        assertEq(mytoken.balanceOf(address(1)),999000000000000000000);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(mytoken), true);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(propertynft), true);

        // voting to sell
        vm.prank(address(2));
        mytoken.voteForSale(1);
        assertEq(mytoken.voters(), 1);

        // buying whole property
        vm.deal(address(3), 1000 ether);
        vm.prank(address(3));
        mytoken.buyWholeProperty{value: 1000 ether}(1);
        assertEq(propertynft.balanceOf(address(1)), 0);
        assertEq(propertynft.balanceOf(address(3)), 1);
        assertEq(address(address(mytoken)).balance, 1002 ether);

        // redeem
        vm.prank(address(2));
        mytoken.redeem(1000000000000000000, 1);
    }

    // // Owner of the nft want to sell the whole property without voting for sale
    function testFailTransferWithoutVoting() public {
        propertynft.safeMint(address(1), 1);
        assertEq(propertynft.balanceOf(address(1)), 1);
        vm.prank(address(1));
        mytoken.listProperty(1, 1000);
        vm.deal(address(2), 10 ether);
        vm.prank(address(2));
        mytoken.buyShare{value: 2 ether}(1, 1); // 0.1%
        assertEq(mytoken.remainingPercentage(),99900000000000000000);
        assertEq(mytoken.balanceOf(address(2)), 1000000000000000000);
        assertEq(mytoken.balanceOf(address(1)),999000000000000000000);

        vm.deal(address(3), 10 ether);
        vm.prank(address(3));
        mytoken.buyShare{value: 2 ether}(1, 1); // 0.1%
        assertEq(mytoken.remainingPercentage(),99800000000000000000); // 998e18 / 1e18 = 99.8%
        assertEq(mytoken.balanceOf(address(3)), 1000000000000000000);
        assertEq(mytoken.balanceOf(address(1)),998000000000000000000);

        vm.prank(address(1));
        propertynft.setApprovalForAll(address(mytoken), true);
        vm.prank(address(1));
        propertynft.setApprovalForAll(address(propertynft), true);

        // Before transfer function will not allowed this
        vm.prank(address(1));
        propertynft.safeTransferFrom(address(1), address(5), 1);
    }

    // // Buying share from another share holder
    // function testBuyShare_FromShareholder() public {
    //     propertynft.safeMint(address(1), 1);
    //     assertEq(propertynft.balanceOf(address(1)), 1);
    //     vm.prank(address(1));
    //     propertynft.setApprovalForAll(address(mytoken), true);
    //     vm.prank(address(1));
    //     propertynft.setApprovalForAll(address(propertynft), true);
    //     // checking nft listed is true for beforetokentransfer()
    //     assertEq(propertynft.getListNft(1), true);

    //     // listing property to the contract
    //     vm.prank(address(1));
    //     mytoken.listProperty(1, 1000);
    //     assertEq(mytoken.totalSupply(), 1000);

    //     // address(2) buy 25% of share
    //     vm.deal(address(2), 10 ether);
    //     vm.prank(address(2));
    //     mytoken.buyShare{value: 2.5 ether}(1, 25);
    //     assertEq(mytoken.balanceOf(address(2)), 250);

    //     // buying share from address(2) who has 25% share and 250 tokens
    //     vm.deal(address(5),4 ether);
    //     vm.prank(address(5));
    //     mytoken.buyShareFromShareholder(1, 1);
    //     assertEq(mytoken.balanceOf(address(2)), 0);
    //     assertEq(mytoken.balanceOf(address(5)), 250);

    // }

    // // This test will fail because property has only 100% share 
    // function testFail_BuyingSharesMoreThan_100_percent() public{
    //     propertynft.safeMint(address(1), 1);
    //     assertEq(propertynft.balanceOf(address(1)), 1);
    //     vm.prank(address(1));
    //     propertynft.setApprovalForAll(address(mytoken), true);
    //     vm.prank(address(1));
    //     propertynft.setApprovalForAll(address(propertynft), true);
    //     // checking nft listed is true for beforetokentransfer()
    //     assertEq(propertynft.getListNft(1), true);

    //     // listing property to the contract
    //     vm.prank(address(1));
    //     mytoken.listProperty(1, 1000);
    //     assertEq(mytoken.totalSupply(), 1000);

    //     // address(2) buy 25% of share
    //     vm.deal(address(2), 10 ether);
    //     vm.prank(address(2));
    //     mytoken.buyShare{value: 2.5 ether}(1, 25);
    //     assertEq(mytoken.balanceOf(address(2)), 250);

    //     // address(3) buy 80%
    //     vm.deal(address(3),10 ether);
    //     vm.prank(address(3));
    //     mytoken.buyShare{value: 8 ether}(1, 80);
    // }

    // // Any address can buy shares before exceeding to 100%
    // function test_Buy_Less_Than_100_percentShare() public{
    //     propertynft.safeMint(address(1), 1);
    //     assertEq(propertynft.balanceOf(address(1)), 1);
    //     vm.prank(address(1));
    //     propertynft.setApprovalForAll(address(mytoken), true);
    //     vm.prank(address(1));
    //     propertynft.setApprovalForAll(address(propertynft), true);
    //     // checking nft listed is true for beforetokentransfer()
    //     assertEq(propertynft.getListNft(1), true);

    //     // listing property to the contract
    //     vm.prank(address(1));
    //     mytoken.listProperty(1, 1000);
    //     assertEq(mytoken.totalSupply(), 1000);

    //     // address(2) buy 25% of share
    //     vm.deal(address(2), 10 ether);
    //     vm.prank(address(2));
    //     mytoken.buyShare{value: 2.5 ether}(1, 25);
    //     assertEq(mytoken.balanceOf(address(2)), 250);

    //     // address(3) buy 25%
    //     vm.deal(address(3),10 ether);
    //     vm.prank(address(3));
    //     mytoken.buyShare{value: 2.5 ether}(1, 25);
    //     assertEq(mytoken.balanceOf(address(3)), 250);

    //     // checking remaining balance of address(1) (owner of the token)
    //     vm.prank(address(1));
    //     assertEq(mytoken.balanceOf(address(1)), 500);

    //     // checking remaining percentage
    //     assertEq(mytoken.remainingPercentage(),50);

    // }

    // // This function should fail because shares can't be buy more than 100%
    // function testFail_BuyMoreThan100PercentShare() public{
    //     propertynft.safeMint(address(1), 1);
    //     assertEq(propertynft.balanceOf(address(1)), 1);
    //     vm.prank(address(1));
    //     propertynft.setApprovalForAll(address(mytoken), true);
    //     vm.prank(address(1));
    //     propertynft.setApprovalForAll(address(propertynft), true);
    //     // checking nft listed is true for beforetokentransfer()
    //     assertEq(propertynft.getListNft(1), true);

    //     // listing property to the contract
    //     vm.prank(address(1));
    //     mytoken.listProperty(1, 1000);
    //     assertEq(mytoken.totalSupply(), 1000);

    //     // address(2) buy 25% of share
    //     vm.deal(address(2), 10 ether);
    //     vm.prank(address(2));
    //     mytoken.buyShare{value: 2.5 ether}(1, 25);
    //     assertEq(mytoken.balanceOf(address(2)), 250);

    //     // address(3) buy 25%
    //     vm.deal(address(3),10 ether);
    //     vm.prank(address(3));
    //     mytoken.buyShare{value: 2.5 ether}(1, 25);
    //     assertEq(mytoken.balanceOf(address(3)), 250);

    //     // checking remaining balance of address(1) (owner of the token)
    //     vm.prank(address(1));
    //     assertEq(mytoken.balanceOf(address(1)), 500);

    //     // checking remaining percentage
    //     assertEq(mytoken.remainingPercentage(),50);

    //     // Address(4) will buy 50% share
    //     vm.deal(address(4),10 ether);
    //     vm.prank(address(4));
    //     mytoken.buyShare{value: 5 ether}(1, 50);
    //     assertEq(mytoken.balanceOf(address(4)), 500);

    //     // Address(5) trying to buy 25% share
    //     vm.deal(address(5),10 ether);
    //     vm.prank(address(5));
    //     mytoken.buyShare{value: 2.5 ether}(1, 25);
    //     assertEq(mytoken.balanceOf(address(4)), 250);
    // }

    // // Withdrawing funds
    // function testWithdraw() public{
    //     propertynft.safeMint(address(1), 1);
    //     assertEq(propertynft.balanceOf(address(1)), 1);
    //     vm.prank(address(1));
    //     propertynft.setApprovalForAll(address(mytoken), true);
    //     vm.prank(address(1));
    //     propertynft.setApprovalForAll(address(propertynft), true);
    //     // checking nft listed is true for beforetokentransfer()
    //     assertEq(propertynft.getListNft(1), true);

    //     // listing property to the contract
    //     vm.prank(address(1));
    //     mytoken.listProperty(1, 1000);
    //     assertEq(mytoken.totalSupply(), 1000);

    //     // address(2) buy 25% of share
    //     vm.deal(address(2), 10 ether);
    //     vm.prank(address(2));
    //     mytoken.buyShare{value: 2.5 ether}(1, 25);
    //     assertEq(mytoken.balanceOf(address(2)), 250);

    //     // address(3) buy 25%
    //     vm.deal(address(3),10 ether);
    //     vm.prank(address(3));
    //     mytoken.buyShare{value: 2.5 ether}(1, 25);
    //     assertEq(mytoken.balanceOf(address(3)), 250);

    //     // address(1) owner will call this
    //     vm.prank(address(1));
    //     mytoken.withdraw(1);

    // }

    // Checking the minimum shares to buy
    // function testMinimumShares() public{
    //     propertynft.safeMint(address(1), 1);
    //     assertEq(propertynft.balanceOf(address(1)), 1);
    //     vm.prank(address(1));
    //     mytoken.listProperty(1, 1000);
    //     assertEq(mytoken.totalSupply(), 1000);
    //     vm.deal(address(2), 10 ether);
    //     vm.prank(address(2));
    //     mytoken.buyShare{value: 1 ether}(1, 1); // On frontend : 0.1 * 10 = 1--- Input mn 1 bhj dyga
    //     assertEq(mytoken.balanceOf(address(2)), 1);
    //     assertEq(mytoken.balanceOf(address(1)),999);
    // }

}
