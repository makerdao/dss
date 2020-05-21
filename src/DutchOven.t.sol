pragma solidity ^0.5.12;

import "ds-test/test.sol";

import "./DutchOven.sol";

contract DutchOvenTest is DSTest {
    Oven oven;

    function setUp() public {
        oven = new Oven(address(0), bytes32("ilk"));
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
