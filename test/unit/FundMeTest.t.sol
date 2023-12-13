// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 10000000000000000  -> 1e17
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughETH() public {
        // we are testing the fundMe fails without enough eth being sent
        vm.expectRevert();
        // it allows us to say hey the next line, should revert
        fundMe.fund(); //send 0 value , but we should send min $5 , this line will fail but we using vm.expectRevert() so it's not
        //gonna fail
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        // msg.sender isn't the one who called fund
        /* 
            knowing who's doing what it can be a little bit confusing, spesialy in our test 
            so in our test we wanna be carefull about who's sending what transaction
            that's where we can use another Foundry cheatcode called pranking
            this prank code sets the msg.sender to the specified address for the next call,
            so we can use prank to always know exactly who's sending what call, 
            and remember this only works in our tests and this only works with foundry.
            there's another cheatcode called makeAddr , where we can pass in a name and it'll give 
            us back a new address.
            then we should use another cheatcode to send money to this new user that we made,
            a cheatcode called  deal  , that allows us to set the balance of an address to new 
            balance, and this is a cheatcode not a forge standard cheat
        */
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        uint256 startingFundMeBalance = address(fundMe).balance;
        // the actual balance of fundMe contract -> SEND_VALUE
        // if you write an address and then .balance you will get the balance of that address

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    // there's a new cheatcode like prank and deal  but the name is hoax and is combine
    // of both of them , and it's forge standard
    // you can make an address by address(0) or address(1) or address(2) or ...
    // but it must be uint160 not uint256, because as of solidity v0.8, you can no longer cast
    // explicitly from address to uint256 and the reason for this is uint160 has the same of the
    // bytes as an address
    // just know, if you want to use numbers to use addresses those numbers

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i <= numberOfFunders; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i <= numberOfFunders; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    // how do we know how much gas will cost for each function to execute?
    // we should use    forge snapshot --mt functionName
    // what this is gonna do, is it's gonna create a new file named  .gas-snapshot
    // and it's gonna tell us exactly how much this single test is going to cost in gas

    // gas
    // when you working with anvil the gas price actually defaults to 0
    // so for us to simulate this transaction with actual gas price, we need to actually
    // tell our test to pretend to use a real gas price, and this is where , there's another
    // cheat code that we can use called txGasPrice which sets the gas price for the rest of the
    // transaction
    // inorder for us to see how much gas this is gonna actually spend , we need to calculate
    // the gas left in this function call befor and after
    // so we say   uint256 gasStart = gasLeft();
    // this gasLeft() function is built in function in solidity, it tells you how much gas is left
    // in your transaction call
    // remember how on etherscan there was a gas Limit and gas usage ,
    // when ever you send a transaction you send a little more gas than your expected to use
    // and you can see how much gas you have left by calling this function
    // tx.gasprice is another built in code in solidity, that tells you the current gas price
    // we use this strategy to see how much gas a specific part of a function use
    // we have a example below
    // ----------------------------------
    // uint256 gasStart = gasleft();
    // vm.txGasPrice(GAS_PRICE);
    // vm.prank(fundMe.getOwner());
    // fundMe.withdraw();
    // uint256 gasEnd = gasleft();
    // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
    // console.log("this is how much gas used : ", gasUsed);
    // ----------------------------------
}
// ----- storage ------
// you can go to FundMe.sol file and write  forge inspect FundMe storageLayout
// you can see the storage layout
// in the storage part you can easily see where stuf is being stored
// and we can see  the constant and immutable variables didnt show up in the storage
// the other way we can see the storage is using  cast storage
// first run anvil with
// forge script script/DeployFundMe.s.sol --rpc-url http://127.0.0.1:8545
// --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
// --broadcast
// now we car run  *********** cast storage contractAddress storageSlot
// its gonna give me whats in that storage slot
// to see storage layout use this code *********** forge inspect contractName storageLayout
// ---------------------
// why storage is important?
// because reading and writing from storage is so expensive operation
// any time we do it , we spend a lot of gas
