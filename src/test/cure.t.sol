// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.12;

import { DSTest } from "ds-test/test.sol";
import { Cure } from "../cure.sol";

contract SourceMock {
    uint256 public cure;

    constructor(uint256 cure_) public {
        cure = cure_;
    }

    function update(uint256 cure_) external {
        cure = cure_;
    }
}

contract CureTest is DSTest {
    Cure cure;

    function setUp() public {
        cure = new Cure();
    }

    function testRelyDeny() public {
        assertEq(cure.wards(address(123)), 0);
        cure.rely(address(123));
        assertEq(cure.wards(address(123)), 1);
        cure.deny(address(123));
        assertEq(cure.wards(address(123)), 0);
    }

    function testFailRely() public {
        cure.deny(address(this));
        cure.rely(address(123));
    }

    function testFailDeny() public {
        cure.deny(address(this));
        cure.deny(address(123));
    }

    function testAddSourceDelSource() public {
        assertEq(cure.count(), 0);

        address addr1 = address(new SourceMock(0));
        cure.addSource(addr1);
        assertEq(cure.count(), 1);

        address addr2 = address(new SourceMock(0));
        cure.addSource(addr2);
        assertEq(cure.count(), 2);

        address addr3 = address(new SourceMock(0));
        cure.addSource(addr3);
        assertEq(cure.count(), 3);

        assertEq(cure.sources(0), addr1);
        assertEq(cure.pos(addr1), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(cure.pos(addr2), 2);
        assertEq(cure.sources(2), addr3);
        assertEq(cure.pos(addr3), 3);

        cure.delSource(addr3);
        assertEq(cure.count(), 2);
        assertEq(cure.sources(0), addr1);
        assertEq(cure.pos(addr1), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(cure.pos(addr2), 2);

        cure.addSource(addr3);
        assertEq(cure.count(), 3);
        assertEq(cure.sources(0), addr1);
        assertEq(cure.pos(addr1), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(cure.pos(addr2), 2);
        assertEq(cure.sources(2), addr3);
        assertEq(cure.pos(addr3), 3);

        cure.delSource(addr1);
        assertEq(cure.count(), 2);
        assertEq(cure.sources(0), addr3);
        assertEq(cure.pos(addr3), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(cure.pos(addr2), 2);

        cure.addSource(addr1);
        assertEq(cure.count(), 3);
        assertEq(cure.sources(0), addr3);
        assertEq(cure.pos(addr3), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(cure.pos(addr2), 2);
        assertEq(cure.sources(2), addr1);
        assertEq(cure.pos(addr1), 3);

        address addr4 = address(new SourceMock(0));
        cure.addSource(addr4);
        assertEq(cure.count(), 4);
        assertEq(cure.sources(0), addr3);
        assertEq(cure.pos(addr3), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(cure.pos(addr2), 2);
        assertEq(cure.sources(2), addr1);
        assertEq(cure.pos(addr1), 3);
        assertEq(cure.sources(3), addr4);
        assertEq(cure.pos(addr4), 4);

        cure.delSource(addr2);
        assertEq(cure.count(), 3);
        assertEq(cure.sources(0), addr3);
        assertEq(cure.pos(addr3), 1);
        assertEq(cure.sources(1), addr4);
        assertEq(cure.pos(addr4), 2);
        assertEq(cure.sources(2), addr1);
        assertEq(cure.pos(addr1), 3);
    }

    function testFailAddSourceAuth() public {
        cure.deny(address(this));
        address addr = address(new SourceMock(0));
        cure.addSource(addr);
    }

    function testFailDelSourceAuth() public {
        address addr = address(new SourceMock(0));
        cure.addSource(addr);
        cure.deny(address(this));
        cure.delSource(addr);
    }

    function testFailDelSourceNonExisting() public {
        address addr1 = address(new SourceMock(0));
        cure.addSource(addr1);
        address addr2 = address(new SourceMock(0));
        cure.delSource(addr2);
    }

    function testCage() public {
        assertEq(cure.live(), 1);
        cure.cage();
        assertEq(cure.live(), 0);
    }

    function testCure() public {
        address source1 = address(new SourceMock(15_000));
        address source2 = address(new SourceMock(30_000));
        address source3 = address(new SourceMock(50_000));
        cure.addSource(source1);
        cure.addSource(source2);
        cure.addSource(source3);

        cure.cage();

        cure.set(source1);
        assertEq(cure.total(), 15_000);
        cure.set(source2);
        assertEq(cure.total(), 45_000);
        cure.set(source3);
        assertEq(cure.total(), 95_000);
    }

    function testSetMultipleTimes() public {
        address source1 = address(new SourceMock(2_000));
        address source2 = address(new SourceMock(3_000));
        cure.addSource(source1);
        cure.addSource(source2);

        cure.cage();

        cure.set(source1);
        cure.set(source2);
        assertEq(cure.total(), 5_000);

        SourceMock(source1).update(4_000);
        assertEq(cure.total(), 5_000);

        cure.set(source1);
        assertEq(cure.total(), 7_000);

        SourceMock(source2).update(6_000);
        assertEq(cure.total(), 7_000);

        cure.set(source2);
        assertEq(cure.total(), 10_000);
    }

    function testSetNoChange() public {
        address source = address(new SourceMock(2_000));
        cure.addSource(source);

        cure.cage();

        cure.set(source);
        assertEq(cure.total(), 2_000);

        cure.set(source);
        assertEq(cure.total(), 2_000);
    }

    function testFailSetNotCaged() public {
        address source = address(new SourceMock(2_000));
        cure.addSource(source);

        cure.set(source);
    }

    function testFailSetNotAdded() public {
        address source = address(new SourceMock(2_000));

        cure.cage();

        cure.set(source);
    }

    function testFailCagedRely() public {
        cure.cage();
        cure.rely(address(123));
    }

    function testFailCagedDeny() public {
        cure.cage();
        cure.deny(address(123));
    }

    function testFailCagedAddSource() public {
        cure.cage();
        address source = address(new SourceMock(0));
        cure.addSource(source);
    }

    function testFailCagedDelSource() public {
        address source = address(new SourceMock(0));
        cure.addSource(source);
        cure.cage();
        cure.delSource(source);
    }
}
