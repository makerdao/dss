// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.11;

import { DSTest } from "ds-test/test.sol";
import { Vat } from "../vat.sol";
import { Dog } from "../dog.sol";

contract VowMock {
    function fess (uint256 due) public {}
}

contract ClipperMock {
    function kick(uint256 tab, uint256 lot, address usr, address kpr)
        external returns (uint256 id) {
        tab; lot; usr; kpr;
        id = 42;
    }
}

contract DogTest is DSTest {

    bytes32 constant ilk = "gold";
    address constant usr = address(1337);
    uint256 constant THOUSAND = 1E3;
    uint256 constant WAD = 1E18;
    uint256 constant RAY = 1E27;
    uint256 constant RAD = 1E45;
    Vat vat;
    VowMock vow;
    ClipperMock clip;
    Dog dog;

    function setUp() public {
        vat = new Vat();
        vat.init(ilk);
        vat.file(ilk, "spot", THOUSAND * RAY);
        vat.file(ilk, "dust", 100 * RAD);
        vow = new VowMock();
        clip = new ClipperMock();
        dog = new Dog(address(vat));
        vat.rely(address(dog));
        dog.file(ilk, "chop", 11 * WAD / 10);
        dog.file("vow", address(vow));
        dog.file(ilk, "clip", address(clip));
        dog.file("Hole", 10 * THOUSAND * RAD);
        dog.file(ilk, "hole", 10 * THOUSAND * RAD);
    }

    function setUrn(uint256 ink, uint256 art) internal {
        vat.slip(ilk, usr, int256(ink));
        vat.suck(address(vow), address(vow), art * RAY);
        vat.grab(ilk, usr, usr, address(vow), int256(ink), int256(art));
        (uint256 actualInk, uint256 actualArt) = vat.urns(ilk, usr);
        assertEq(ink, actualInk);
        assertEq(art, actualArt);
    }

    function isDusty() internal returns (bool dusty) {
        (, uint256 rate,,, uint256 dust) = vat.ilks(ilk);
        (, uint256 art) = vat.urns(ilk, usr);
        (, uint256 chop,,) = dog.ilks(ilk);
        uint256 due = art * rate;
        uint256 tab = due * chop / WAD;
        dusty = tab > 0 && tab < dust;
    }

    function test_bark_basic() public {
        setUrn(WAD, 2 * THOUSAND * WAD);
        dog.bark(ilk, usr, address(this));
        (uint256 ink, uint256 art) = vat.urns(ilk, usr);
        assertEq(ink, 0);
        assertEq(art, 0);
    }

    function testFail_bark_not_unsafe() public {
        setUrn(WAD, 500 * WAD);
        dog.bark(ilk, usr, address(this));
    }

    // currently, dog.bark doesn't check if a vault is unliquidatable
    function test_bark_unliquidatable_vault() public {
        uint256 dust = 200;
        vat.file(ilk, "dust", dust * RAD);
        setUrn(1, (dust / 2) * WAD);
        assertTrue(isDusty());
        dog.bark(ilk, usr, address(this));
    }

    function test_bark_over_ilk_hole_under_ilk_hole_plus_dust() public {
        uint256 dust = 200;
        vat.file(ilk, "dust", dust * RAD);
        uint256 hole = 5 * THOUSAND;
        dog.file(ilk, "hole", hole * RAD);
        setUrn(WAD, hole * WAD * WAD / dog.chop(ilk) + dust * WAD - 1);
        dog.bark(ilk, usr, address(this));
        assertTrue(!isDusty());
        (, uint256 art) = vat.urns(ilk, usr);
        assertEq(art, 0);
    }

    function test_bark_over_Hole_under_Hole_plus_dust() public {
        uint256 dust = 200;
        vat.file(ilk, "dust", dust * RAD);
        uint256 Hole = 5 * THOUSAND;
        dog.file("Hole", Hole * RAD);
        setUrn(WAD, Hole * WAD * WAD / dog.chop(ilk) + dust * WAD - 1);
        dog.bark(ilk, usr, address(this));
        assertTrue(!isDusty());
        (, uint256 art) = vat.urns(ilk, usr);
        assertEq(art, 0);
    }

    function test_bark_equals_ilk_hole_plus_dust() public {
        uint256 dust = 200;
        vat.file(ilk, "dust", dust * RAD);
        uint256 hole = 5 * THOUSAND;
        dog.file(ilk, "hole", hole * RAD);
        setUrn(WAD, hole * WAD * WAD / dog.chop(ilk) + dust * WAD);
        dog.bark(ilk, usr, address(this));
        assertTrue(!isDusty());
        (, uint256 art) = vat.urns(ilk, usr);
        assertEq(art, dust * WAD);
    }

    function test_bark_equals_Hole_plus_dust() public {
        uint256 dust = 200;
        vat.file(ilk, "dust", dust * RAD);
        uint256 Hole = 5 * THOUSAND;
        dog.file("Hole", Hole * RAD);
        setUrn(WAD, Hole * WAD * WAD / dog.chop(ilk) + dust * WAD);
        dog.bark(ilk, usr, address(this));
        assertTrue(!isDusty());
        (, uint256 art) = vat.urns(ilk, usr);
        assertEq(art, dust * WAD);
    }
}
