pragma solidity ^0.5.15;

import "ds-test/test.sol";

import "./DutchOven.sol";

contract DutchOvenTest is DSTest {
    DutchOven oven;

    function setUp() public {
        oven = new DutchOven();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
