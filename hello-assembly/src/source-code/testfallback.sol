// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Creating a contract
contract GeeksForGeeks
{
	// Declaring the state variable
	uint x;
	
	// Mapping of addresses to their balances
	mapping(address => uint) balance;

	// Creating a constructor
	constructor() public
	{
		// Set x to default
		// value of 10
		x=10;

	}

	// Creating a function
	function SetX(uint _x) public returns(bool)
	{
		// Set x to the
		// value sent
		x=_x;
		return true;
	}
	
	// This fallback function
	// will keep all the Ether
    fallback() external payable
    {
        balance[msg.sender] += msg.value;
    }
}


