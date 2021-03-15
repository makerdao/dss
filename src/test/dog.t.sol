// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.12;

import { DSTest } from "ds-test/test.sol";
import { Vat } from "../vat.sol";
import { Dog } from "../dog.sol";

contract VowMock {
    function fess (uint256 due) public {}
}

contract ClipperMock {
    bytes32 public ilk;
    function setIlk(bytes32 wat) external {
        ilk = wat;
    }
    function kick(uint256, uint256, address, address)
        external pure returns (uint256 id) {
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
        clip.setIlk(ilk);
        dog = new Dog(address(vat));
        vat.rely(address(dog));
        dog.file(ilk, "chop", 11 * WAD / 10);
        dog.file("vow", address(vow));
        dog.file(ilk, "clip", address(clip));
        dog.file("Hole", 10 * THOUSAND * RAD);
        dog.file(ilk, "hole", 10 * THOUSAND * RAD);
    }

    function test_file_chop() public {
        dog.file(ilk, "chop", WAD);
        dog.file(ilk, "chop", WAD * 113 / 100);
    }

    function testFail_file_chop_lt_WAD() public {
        dog.file(ilk, "chop", WAD - 1);
    }

    function testFail_file_chop_eq_zero() public {
        dog.file(ilk, "chop", 0);
    }

    function testFail_file_clip_wrong_ilk() public {
        dog.file("mismatched_ilk", "clip", address(clip));
    }

    function setUrn(uint256 ink, uint256 art) internal {
        vat.slip(ilk, usr, int256(ink));
        (, uint256 rate,,,) = vat.ilks(ilk);
        vat.suck(address(vow), address(vow), art * rate);
        vat.grab(ilk, usr, usr, address(vow), int256(ink), int256(art));
        (uint256 actualInk, uint256 actualArt) = vat.urns(ilk, usr);
        assertEq(ink, actualInk);
        assertEq(art, actualArt);
    }

    function isDusty() internal view returns (bool dusty) {
        (, uint256 rate,,, uint256 dust) = vat.ilks(ilk);
        (, uint256 art) = vat.urns(ilk, usr);
        uint256 due = art * rate;
        dusty = due > 0 && due < dust;
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

    // dog.bark will liquidate vaults even if they are dusty
    function test_bark_dusty_vault() public {
        uint256 dust = 200;
        vat.file(ilk, "dust", dust * RAD);
        setUrn(1, (dust / 2) * WAD);
        assertTrue(isDusty());
        dog.bark(ilk, usr, address(this));
    }

    function test_bark_partial_liquidation_dirt_exceeds_hole_to_avoid_dusty_remnant() public {
        uint256 dust = 200;
        vat.file(ilk, "dust", dust * RAD);
        uint256 hole = 5 * THOUSAND;
        dog.file(ilk, "hole", hole * RAD);
        (, uint256 chop,,) = dog.ilks(ilk);
        uint256 artStart = hole * WAD * WAD / chop + dust * WAD - 1;
        setUrn(WAD, artStart);
        dog.bark(ilk, usr, address(this));
        assertTrue(!isDusty());
        (, uint256 art) = vat.urns(ilk, usr);

        // The full vault has been liquidated so as not to leave a dusty remnant,
        // at the expense of slightly exceeding hole.
        assertEq(art, 0);
        (,,, uint256 dirt) = dog.ilks(ilk);
        assertTrue(dirt > hole * RAD);
        assertEq(dirt, artStart * RAY * chop / WAD);
    }

    function test_bark_partial_liquidation_dirt_does_not_exceed_hole_if_remnant_is_nondusty() public {
        uint256 dust = 200;
        vat.file(ilk, "dust", dust * RAD);
        uint256 hole = 5 * THOUSAND;
        dog.file(ilk, "hole", hole * RAD);
        (, uint256 chop,,) = dog.ilks(ilk);
        setUrn(WAD, hole * WAD * WAD / chop + dust * WAD);
        dog.bark(ilk, usr, address(this));
        assertTrue(!isDusty());
        (, uint256 art) = vat.urns(ilk, usr);

        // The vault remnant respects the dust limit, so we don't exceed hole to liquidate it.
        assertEq(art, dust * WAD);
        (,,, uint256 dirt) = dog.ilks(ilk);
        assertTrue(dirt <= hole * RAD);
        assertEq(dirt, hole * RAD * WAD / RAY / chop * RAY * chop / WAD);
    }

    function test_bark_partial_liquidation_Dirt_exceeds_Hole_to_avoid_dusty_remnant() public {
        uint256 dust = 200;
        vat.file(ilk, "dust", dust * RAD);
        uint256 Hole = 5 * THOUSAND;
        dog.file("Hole", Hole * RAD);
        (, uint256 chop,,) = dog.ilks(ilk);
        uint256 artStart = Hole * WAD * WAD / chop + dust * WAD - 1;
        setUrn(WAD, artStart);
        dog.bark(ilk, usr, address(this));
        assertTrue(!isDusty());

        // The full vault has been liquidated so as not to leave a dusty remnant,
        // at the expense of slightly exceeding hole.
        (, uint256 art) = vat.urns(ilk, usr);
        assertEq(art, 0);
        assertTrue(dog.Dirt() > Hole * RAD);
        assertEq(dog.Dirt(), artStart * RAY * chop / WAD);
    }

    function test_bark_partial_liquidation_Dirt_does_not_exceed_Hole_if_remnant_is_nondusty() public {
        uint256 dust = 200;
        vat.file(ilk, "dust", dust * RAD);
        uint256 Hole = 5 * THOUSAND;
        dog.file("Hole", Hole * RAD);
        (, uint256 chop,,) = dog.ilks(ilk);
        setUrn(WAD, Hole * WAD * WAD / chop + dust * WAD);
        dog.bark(ilk, usr, address(this));
        assertTrue(!isDusty());

        // The full vault has been liquidated so as not to leave a dusty remnant,
        // at the expense of slightly exceeding hole.
        (, uint256 art) = vat.urns(ilk, usr);
        assertEq(art, dust * WAD);
        assertTrue(dog.Dirt() <= Hole * RAD);
        assertEq(dog.Dirt(), Hole * RAD * WAD / RAY / chop * RAY * chop / WAD);
    }

    // A previous version reverted if room was dusty, even if the Vault being liquidated
    // was also dusty and would fit in the remaining hole/Hole room.
    function test_bark_dusty_vault_dusty_room() public {
        // Use a chop that will give nice round numbers
        uint256 CHOP = 110 * WAD / 100;  // 10%
        dog.file(ilk, "chop", CHOP);

        // set both hole_i and Hole to the same value for this test
        uint256 ROOM = 200;
        uint256 HOLE = 33 * THOUSAND + ROOM;
        dog.file(     "Hole", HOLE * RAD);
        dog.file(ilk, "hole", HOLE * RAD);

        // Test using a non-zero rate to ensure the code is handling stability fees correctly.
        vat.fold(ilk, address(vow), (5 * int256(RAY)) / 10);
        (, uint256 rate,,,) = vat.ilks(ilk);
        assertEq(rate, (15 * RAY) / 10);

        // First, make both holes nearly full.
        setUrn(WAD, (HOLE - ROOM) * RAD / rate * WAD / CHOP);
        dog.bark(ilk, usr, address(this));
        assertEq(HOLE * RAD - dog.Dirt(), ROOM * RAD);
        (,,, uint256 dirt) = dog.ilks(ilk);
        assertEq(HOLE * RAD - dirt, ROOM * RAD);

        // Create a small vault
        uint256 DUST_1 = 30;
        vat.file(ilk, "dust", DUST_1 * RAD);
        setUrn(WAD / 10**4, DUST_1 * RAD / rate);

        // Dust limit goes up!
        uint256 DUST_2 = 1500;
        vat.file(ilk, "dust", DUST_2 * RAD);

        // The testing vault is now dusty
        assertTrue(isDusty());

        // In fact, there is only room to create dusty auctions at this point.
        assertTrue(dog.Hole() - dog.Dirt() < DUST_2 * RAD * CHOP / WAD);
        uint256 hole;
        (,, hole, dirt) = dog.ilks(ilk);
        assertTrue(hole - dirt < DUST_2 * RAD * CHOP / WAD);

        // But...our Vault is small enough to fit in ROOM
        assertTrue(DUST_1 * RAD * CHOP / WAD < ROOM * RAD);

        // bark should still succeed
        dog.bark(ilk, usr, address(this));
    }

    function try_bark(bytes32 ilk_, address usr_, address kpr_) internal returns (bool ok) {
        string memory sig = "bark(bytes32,address,address)";
        (ok,) = address(dog).call(abi.encodeWithSignature(sig, ilk_, usr_, kpr_));
    }

    function test_bark_do_not_create_dusty_auction_hole() public {
        uint256 dust = 300;
        vat.file(ilk, "dust", dust * RAD);
        uint256 hole = 3 * THOUSAND;
        dog.file(ilk, "hole", hole * RAD);

        // Test using a non-zero rate to ensure the code is handling stability fees correctly.
        vat.fold(ilk, address(vow), (5 * int256(RAY)) / 10);
        (, uint256 rate,,,) = vat.ilks(ilk);
        assertEq(rate, (15 * RAY) / 10);

        (, uint256 chop,,) = dog.ilks(ilk);
        setUrn(WAD, (hole - dust / 2) * RAD / rate * WAD / chop);
        dog.bark(ilk, usr, address(this));

        // Make sure any partial liquidation would be dusty (assuming non-dusty remnant)
        (,,, uint256 dirt) = dog.ilks(ilk);
        uint256 room = hole * RAD - dirt;
        uint256 dart = room * WAD / rate / chop;
        assertTrue(dart * rate < dust * RAD);

        // This will need to be partially liquidated
        setUrn(WAD, hole * WAD * WAD / chop);
        assertTrue(!try_bark(ilk, usr, address(this)));  // should revert, as the auction would be dusty
    }

    function test_bark_do_not_create_dusty_auction_Hole() public {
        uint256 dust = 300;
        vat.file(ilk, "dust", dust * RAD);
        uint256 Hole = 3 * THOUSAND;
        dog.file("Hole", Hole * RAD);

        // Test using a non-zero rate to ensure the code is handling stability fees correctly.
        vat.fold(ilk, address(vow), (5 * int256(RAY)) / 10);
        (, uint256 rate,,,) = vat.ilks(ilk);
        assertEq(rate, (15 * RAY) / 10);

        (, uint256 chop,,) = dog.ilks(ilk);
        setUrn(WAD, (Hole - dust / 2) * RAD / rate * WAD / chop);
        dog.bark(ilk, usr, address(this));

        // Make sure any partial liquidation would be dusty (assuming non-dusty remnant)
        uint256 room = Hole * RAD - dog.Dirt();
        uint256 dart = room * WAD / rate / chop;
        assertTrue(dart * rate < dust * RAD);

        // This will need to be partially liquidated
        setUrn(WAD, Hole * WAD * WAD / chop);
        assertTrue(!try_bark(ilk, usr, address(this)));  // should revert, as the auction would be dusty
    }
}
