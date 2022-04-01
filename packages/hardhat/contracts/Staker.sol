// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  // Balances of the user's staked funds
  mapping ( address => uint256 ) public balances;

  // Staking threshold
  uint256 public constant threshold = 1 ether;

  // staking deadline
  uint256 public deadline = block.timestamp + 72 hours;
  
  // Contract's Events
  event Stake(address, uint256);
  
  // set withdraw for open
  bool openForWithdraw;

  bool executed = false;

  // check if deadline reached or not
  modifier deadlineReached(bool requireReached) {
    uint256 timeRemaining = timeLeft();
    if( requireReached ) {
      require(timeRemaining <= 0, "Deadline has not been passed yet");
    } else {
      require(timeRemaining > 0, "Deadline is already passed");
    }
    _;
  }


  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "staking process already completed");
    _;
  }

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    // update the user's balance
    balances[msg.sender] += msg.value;

    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public notCompleted  {
    require(block.timestamp >= deadline, "It's not yet time");
    
    uint256 contractBalance = balances[address(this)];

    // check the contract has enough eth to reach the treshold
    if (contractBalance >= threshold) {
        (bool sent,) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature("complete()"));
        require(sent, "exampleExternalContract.complete failed");
        openForWithdraw = false;
    } else {
        openForWithdraw = true;
    }
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public notCompleted {
    uint256 userBalance = balances[msg.sender];

    // check if the user has balance to withraw
    require(userBalance > 0, "You don't have balance to withdraw");

    // reset the balance of the user
    balances[msg.sender] = 0;

    // Transfer balance back to the user
    (bool sent,) = msg.sender.call{value: userBalance}("");
    require(sent, "Failed to send user balance back to the user");
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if(block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
   receive() external payable {
    stake();
  }

}
