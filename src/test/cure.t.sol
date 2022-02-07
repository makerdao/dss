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

    function pos(address src) internal returns (uint256 pos_) {
        (pos_,) = cure.data(src);
    }

    function testAddSourceDelSource() public {
        assertEq(cure.sLength(), 0);

        address addr1 = address(new SourceMock(0));
        cure.addSource(addr1);
        assertEq(cure.sLength(), 1);

        address addr2 = address(new SourceMock(0));
        cure.addSource(addr2);
        assertEq(cure.sLength(), 2);

        address addr3 = address(new SourceMock(0));
        cure.addSource(addr3);
        assertEq(cure.sLength(), 3);

        assertEq(cure.sources(0), addr1);
        assertEq(pos(addr1), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(pos(addr2), 2);
        assertEq(cure.sources(2), addr3);
        assertEq(pos(addr3), 3);

        cure.delSource(addr3);
        assertEq(cure.sLength(), 2);
        assertEq(cure.sources(0), addr1);
        assertEq(pos(addr1), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(pos(addr2), 2);

        cure.addSource(addr3);
        assertEq(cure.sLength(), 3);
        assertEq(cure.sources(0), addr1);
        assertEq(pos(addr1), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(pos(addr2), 2);
        assertEq(cure.sources(2), addr3);
        assertEq(pos(addr3), 3);

        cure.delSource(addr1);
        assertEq(cure.sLength(), 2);
        assertEq(cure.sources(0), addr3);
        assertEq(pos(addr3), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(pos(addr2), 2);

        cure.addSource(addr1);
        assertEq(cure.sLength(), 3);
        assertEq(cure.sources(0), addr3);
        assertEq(pos(addr3), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(pos(addr2), 2);
        assertEq(cure.sources(2), addr1);
        assertEq(pos(addr1), 3);

        address addr4 = address(new SourceMock(0));
        cure.addSource(addr4);
        assertEq(cure.sLength(), 4);
        assertEq(cure.sources(0), addr3);
        assertEq(pos(addr3), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(pos(addr2), 2);
        assertEq(cure.sources(2), addr1);
        assertEq(pos(addr1), 3);
        assertEq(cure.sources(3), addr4);
        assertEq(pos(addr4), 4);

        cure.delSource(addr2);
        assertEq(cure.sLength(), 3);
        assertEq(cure.sources(0), addr3);
        assertEq(pos(addr3), 1);
        assertEq(cure.sources(1), addr4);
        assertEq(pos(addr4), 2);
        assertEq(cure.sources(2), addr1);
        assertEq(pos(addr1), 3);
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

    function testCure() public {
        cure.addSource(address(new SourceMock(15_000)));
        assertEq(cure.cure(), 15_000);
        cure.addSource(address(new SourceMock(30_000)));
        assertEq(cure.cure(), 45_000);
        cure.addSource(address(new SourceMock(50_000)));
        assertEq(cure.cure(), 95_000);
    }

    function testReset() public {
        SourceMock source = new SourceMock(2_000);
        cure.addSource(address(source));
        assertEq(cure.cure(), 2_000);
        source.update(4_000);
        assertEq(cure.cure(), 2_000);
        cure.reset(address(source));
        assertEq(cure.cure(), 4_000);
    }

    function testResetNoChange() public {
        SourceMock source = new SourceMock(2_000);
        cure.addSource(address(source));
        assertEq(cure.cure(), 2_000);
        cure.reset(address(source));
        assertEq(cure.cure(), 2_000);
    }

    function testCage() public {
        assertEq(cure.live(), 1);
        cure.cage();
        assertEq(cure.live(), 0);
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
        address addr = address(new SourceMock(0));
        cure.addSource(addr);
    }

    function testFailCagedDelSource() public {
        address addr = address(new SourceMock(0));
        cure.addSource(addr);
        cure.cage();
        cure.delSource(addr);
    }
}
