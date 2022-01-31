// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.12;

import { DSTest } from "ds-test/test.sol";
import { Cure } from "../cure.sol";
import { Vat }  from '../vat.sol';

contract SourceMock {
    uint256 public totalDebt;

    constructor(uint256 totalDebt_) public {
        totalDebt = totalDebt_;
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

    function test_file() public {
        assertEq(cure.totalDebt(), 0);
        cure.file("totalDebt", 123);
        assertEq(cure.totalDebt(), 123);
    }

    function testFail_file() public {
        cure.deny(address(this));
        cure.file("totalDebt", 123);
    }

    function test_addSourceDelSource() public {
        assertEq(cure.numSources(), 0);

        cure.addSource(address(123));
        assertEq(cure.numSources(), 1);

        cure.addSource(address(456));
        assertEq(cure.numSources(), 2);

        cure.addSource(address(789));
        assertEq(cure.numSources(), 3);

        assertEq(cure.sources(0), address(123));
        assertEq(cure.sources(1), address(456));
        assertEq(cure.sources(2), address(789));

        cure.delSource(2);
        assertEq(cure.numSources(), 2);
        assertEq(cure.sources(0), address(123));
        assertEq(cure.sources(1), address(456));

        cure.addSource(address(789));
        assertEq(cure.numSources(), 3);
        assertEq(cure.sources(0), address(123));
        assertEq(cure.sources(1), address(456));
        assertEq(cure.sources(2), address(789));

        cure.delSource(0);
        assertEq(cure.numSources(), 2);
        assertEq(cure.sources(0), address(789));
        assertEq(cure.sources(1), address(456));

        cure.addSource(address(123));
        assertEq(cure.numSources(), 3);
        assertEq(cure.sources(0), address(789));
        assertEq(cure.sources(1), address(456));
        assertEq(cure.sources(2), address(123));

        cure.addSource(address(555));
        assertEq(cure.numSources(), 4);
        assertEq(cure.sources(0), address(789));
        assertEq(cure.sources(1), address(456));
        assertEq(cure.sources(2), address(123));
        assertEq(cure.sources(3), address(555));

        cure.delSource(1);
        assertEq(cure.numSources(), 3);
        assertEq(cure.sources(0), address(789));
        assertEq(cure.sources(1), address(555));
        assertEq(cure.sources(2), address(123));
    }

    function testFail_addSourceAuth() public {
        cure.deny(address(this));
        cure.addSource(address(123));
    }

    function testFail_delSourceAuth() public {
        cure.addSource(address(123));
        cure.deny(address(this));
        cure.delSource(0);
    }

    function testFail_delSourceNonExisting() public {
        cure.addSource(address(123));
        cure.delSource(1);
    }

    function test_debt() public {
        vat.suck(address(999), address(999), 500_000);
        assertEq(cure.debt(), 500_000);

        cure.file("totalDebt", 10_000);
        assertEq(cure.debt(), 490_000);
        cure.addSource(address(new SourceMock(15_000)));
        assertEq(cure.debt(), 475_000);
        cure.addSource(address(new SourceMock(30_000)));
        assertEq(cure.debt(), 445_000);
        cure.addSource(address(new SourceMock(50_000)));
        assertEq(cure.debt(), 395_000);
    }

    function testFail_debtSub() public {
        vat.suck(address(999), address(999), 9_999);
        cure.file("totalDebt", 10_000);
        cure.debt();
    }

    function testFail_debtSub2() public {
        vat.suck(address(999), address(999), 10_000);
        cure.file("totalDebt", 10_000);
        cure.addSource(address(new SourceMock(1)));
        cure.debt();
    }
}
