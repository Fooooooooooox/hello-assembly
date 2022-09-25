// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Tee {

    uint256 private c;

    function a() public returns (uint256) { return self(2); }

    function b() public { c++; }

    function self(uint n) internal returns (uint256) {

        if (n <= 1) { return 1; }

        return n * self(n - 1);
    }
}