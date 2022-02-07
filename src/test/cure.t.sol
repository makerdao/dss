// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.12;

import { DSTest } from "ds-test/test.sol";
import { Cure } from "../cure.sol";
import { Vat }  from '../vat.sol';

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
    Vat vat;

    function setUp() public {
        vat = new Vat();
        cure = new Cure(address(vat));
    }

    function test_relyDeny() public {
        assertEq(cure.wards(address(123)), 0);
        cure.rely(address(123));
        assertEq(cure.wards(address(123)), 1);
        cure.deny(address(123));
        assertEq(cure.wards(address(123)), 0);
    }

    function testFail_rely() public {
        cure.deny(address(this));
        cure.rely(address(123));
    }

    function testFail_deny() public {
        cure.deny(address(this));
        cure.deny(address(123));
    }

    function pos(address src) internal returns (uint256 pos_) {
        (pos_,) = cure.data(src);
    }

    function test_addSourceDelSource() public {
        assertEq(cure.numSources(), 0);

        address addr1 = address(new SourceMock(0));
        cure.addSource(addr1);
        assertEq(cure.numSources(), 1);

        address addr2 = address(new SourceMock(0));
        cure.addSource(addr2);
        assertEq(cure.numSources(), 2);

        address addr3 = address(new SourceMock(0));
        cure.addSource(addr3);
        assertEq(cure.numSources(), 3);

        assertEq(cure.sources(0), addr1);
        assertEq(pos(addr1), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(pos(addr2), 2);
        assertEq(cure.sources(2), addr3);
        assertEq(pos(addr3), 3);

        cure.delSource(addr3);
        assertEq(cure.numSources(), 2);
        assertEq(cure.sources(0), addr1);
        assertEq(pos(addr1), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(pos(addr2), 2);

        cure.addSource(addr3);
        assertEq(cure.numSources(), 3);
        assertEq(cure.sources(0), addr1);
        assertEq(pos(addr1), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(pos(addr2), 2);
        assertEq(cure.sources(2), addr3);
        assertEq(pos(addr3), 3);

        cure.delSource(addr1);
        assertEq(cure.numSources(), 2);
        assertEq(cure.sources(0), addr3);
        assertEq(pos(addr3), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(pos(addr2), 2);

        cure.addSource(addr1);
        assertEq(cure.numSources(), 3);
        assertEq(cure.sources(0), addr3);
        assertEq(pos(addr3), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(pos(addr2), 2);
        assertEq(cure.sources(2), addr1);
        assertEq(pos(addr1), 3);

        address addr4 = address(new SourceMock(0));
        cure.addSource(addr4);
        assertEq(cure.numSources(), 4);
        assertEq(cure.sources(0), addr3);
        assertEq(pos(addr3), 1);
        assertEq(cure.sources(1), addr2);
        assertEq(pos(addr2), 2);
        assertEq(cure.sources(2), addr1);
        assertEq(pos(addr1), 3);
        assertEq(cure.sources(3), addr4);
        assertEq(pos(addr4), 4);

        cure.delSource(addr2);
        assertEq(cure.numSources(), 3);
        assertEq(cure.sources(0), addr3);
        assertEq(pos(addr3), 1);
        assertEq(cure.sources(1), addr4);
        assertEq(pos(addr4), 2);
        assertEq(cure.sources(2), addr1);
        assertEq(pos(addr1), 3);
    }

    function testFail_addSourceAuth() public {
        cure.deny(address(this));
        address addr = address(new SourceMock(0));
        cure.addSource(addr);
    }

    function testFail_delSourceAuth() public {
        address addr = address(new SourceMock(0));
        cure.addSource(addr);
        cure.deny(address(this));
        cure.delSource(addr);
    }

    function testFail_delSourceNonExisting() public {
        address addr1 = address(new SourceMock(0));
        cure.addSource(addr1);
        address addr2 = address(new SourceMock(0));
        cure.delSource(addr2);
    }

    function test_debt() public {
        vat.suck(address(999), address(999), 500_000);
        assertEq(cure.debt(), 500_000);

        cure.addSource(address(new SourceMock(15_000)));
        assertEq(cure.debt(), 485_000);
        cure.addSource(address(new SourceMock(30_000)));
        assertEq(cure.debt(), 455_000);
        cure.addSource(address(new SourceMock(50_000)));
        assertEq(cure.debt(), 405_000);
    }

    function testFail_debtSub() public {
        vat.suck(address(999), address(999), 10_000);
        cure.addSource(address(new SourceMock(10_001)));
        cure.debt();
    }

    function testReset() public {
        vat.suck(address(999), address(999), 10_000);
        SourceMock source = new SourceMock(2_000);
        cure.addSource(address(source));
        assertEq(cure.debt(), 8_000);
        source.update(4_000);
        assertEq(cure.debt(), 8_000);
        cure.reset(address(source));
        assertEq(cure.debt(), 6_000);
    }

    function testResetNoChange() public {
        vat.suck(address(999), address(999), 10_000);
        SourceMock source = new SourceMock(2_000);
        cure.addSource(address(source));
        assertEq(cure.debt(), 8_000);
        cure.reset(address(source));
        assertEq(cure.debt(), 8_000);
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
