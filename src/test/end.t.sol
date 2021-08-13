// SPDX-License-Identifier: AGPL-3.0-or-later

// end.t.sol -- global settlement tests

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
// Copyright (C) 2018 Lev Livnev <lev@liv.nev.org.uk>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.6.12;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import {Vat}  from '../vat.sol';
import {Cat}  from '../cat.sol';
import {Dog}  from '../dog.sol';
import {Vow}  from '../vow.sol';
import {Pot}  from '../pot.sol';
import {Flipper} from '../flip.sol';
import {Clipper} from '../clip.sol';
import {Flapper} from '../flap.sol';
import {Flopper} from '../flop.sol';
import {GemJoin} from '../join.sol';
import {End}  from '../end.sol';
import {Spotter} from '../spot.sol';

interface Hevm {
    function warp(uint256) external;
}

contract Usr {
    Vat public vat;
    End public end;

    constructor(Vat vat_, End end_) public {
        vat  = vat_;
        end  = end_;
    }
    function frob(bytes32 ilk, address u, address v, address w, int dink, int dart) public {
        vat.frob(ilk, u, v, w, dink, dart);
    }
    function flux(bytes32 ilk, address src, address dst, uint256 wad) public {
        vat.flux(ilk, src, dst, wad);
    }
    function move(address src, address dst, uint256 rad) public {
        vat.move(src, dst, rad);
    }
    function hope(address usr) public {
        vat.hope(usr);
    }
    function exit(GemJoin gemA, address usr, uint wad) public {
        gemA.exit(usr, wad);
    }
    function free(bytes32 ilk) public {
        end.free(ilk);
    }
    function pack(uint256 rad) public {
        end.pack(rad);
    }
    function cash(bytes32 ilk, uint wad) public {
        end.cash(ilk, wad);
    }
}

contract EndTest is DSTest {
    Hevm hevm;

    Vat   vat;
    End   end;
    Vow   vow;
    Pot   pot;
    Cat   cat;
    Dog   dog;

    Spotter spot;

    struct Ilk {
        DSValue pip;
        DSToken gem;
        GemJoin gemA;
        Flipper flip;
        Clipper clip;
    }

    mapping (bytes32 => Ilk) ilks;

    Flapper flap;
    Flopper flop;

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;
    uint constant MLN = 10 ** 6;

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * RAY;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / RAY;
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        (x >= y) ? z = y : z = x;
    }
    function dai(address urn) internal view returns (uint) {
        return vat.dai(urn) / RAY;
    }
    function gem(bytes32 ilk, address urn) internal view returns (uint) {
        return vat.gem(ilk, urn);
    }
    function ink(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, urn); art_;
        return ink_;
    }
    function art(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, urn); ink_;
        return art_;
    }
    function Art(bytes32 ilk) internal view returns (uint) {
        (uint Art_, uint rate_, uint spot_, uint line_, uint dust_) = vat.ilks(ilk);
        rate_; spot_; line_; dust_;
        return Art_;
    }
    function balanceOf(bytes32 ilk, address usr) internal view returns (uint) {
        return ilks[ilk].gem.balanceOf(usr);
    }

    function try_pot_file(bytes32 what, uint data) public returns(bool ok) {
        string memory sig = "file(bytes32, uint)";
        (ok,) = address(pot).call(abi.encodeWithSignature(sig, what, data));
    }

    function init_collateral(bytes32 name) internal returns (Ilk memory) {
        DSToken coin = new DSToken("");
        coin.mint(500_000 ether);

        DSValue pip = new DSValue();
        spot.file(name, "pip", address(pip));
        spot.file(name, "mat", ray(2 ether));
        // initial collateral price of 6
        pip.poke(bytes32(6 * WAD));
        spot.poke(name);

        vat.init(name);
        vat.file(name, "line", rad(1_000_000 ether));

        GemJoin gemA = new GemJoin(address(vat), name, address(coin));

        coin.approve(address(gemA));
        coin.approve(address(vat));

        vat.rely(address(gemA));

        Flipper flip = new Flipper(address(vat), address(cat), name);
        vat.hope(address(flip));
        flip.rely(address(end));
        flip.rely(address(cat));
        cat.rely(address(flip));
        cat.file(name, "flip", address(flip));
        cat.file(name, "chop", 1 ether);
        cat.file(name, "dunk", rad(25000 ether));
        cat.file("box", rad((10 ether) * MLN));

        Clipper clip = new Clipper(address(vat), address(spot), address(dog), name);
        vat.rely(address(clip));
        vat.hope(address(clip));
        clip.rely(address(end));
        clip.rely(address(dog));
        dog.rely(address(clip));
        dog.file(name, "clip", address(clip));
        dog.file(name, "chop", 1.1 ether);
        dog.file(name, "hole", rad(25000 ether));
        dog.file("Hole", rad((25000 ether)));

        ilks[name].pip = pip;
        ilks[name].gem = coin;
        ilks[name].gemA = gemA;
        ilks[name].flip = flip;
        ilks[name].clip = clip;

        return ilks[name];
    }

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        vat = new Vat();
        DSToken gov = new DSToken('GOV');

        flap = new Flapper(address(vat), address(gov));
        flop = new Flopper(address(vat), address(gov));
        gov.setOwner(address(flop));

        vow = new Vow(address(vat), address(flap), address(flop));

        pot = new Pot(address(vat));
        vat.rely(address(pot));
        pot.file("vow", address(vow));

        cat = new Cat(address(vat));
        cat.file("vow", address(vow));
        vat.rely(address(cat));
        vow.rely(address(cat));

        dog = new Dog(address(vat));
        dog.file("vow", address(vow));
        vat.rely(address(dog));
        vow.rely(address(dog));

        spot = new Spotter(address(vat));
        vat.file("Line",         rad(1_000_000 ether));
        vat.rely(address(spot));

        end = new End();
        end.file("vat", address(vat));
        end.file("cat", address(cat));
        end.file("dog", address(dog));
        end.file("vow", address(vow));
        end.file("pot", address(pot));
        end.file("spot", address(spot));
        end.file("wait", 1 hours);
        vat.rely(address(end));
        vow.rely(address(end));
        spot.rely(address(end));
        pot.rely(address(end));
        cat.rely(address(end));
        dog.rely(address(end));
        flap.rely(address(vow));
        flop.rely(address(vow));
    }

    function test_cage_basic() public {
        assertEq(end.live(), 1);
        assertEq(vat.live(), 1);
        assertEq(cat.live(), 1);
        assertEq(vow.live(), 1);
        assertEq(pot.live(), 1);
        assertEq(vow.flopper().live(), 1);
        assertEq(vow.flapper().live(), 1);
        end.cage();
        assertEq(end.live(), 0);
        assertEq(vat.live(), 0);
        assertEq(cat.live(), 0);
        assertEq(vow.live(), 0);
        assertEq(pot.live(), 0);
        assertEq(vow.flopper().live(), 0);
        assertEq(vow.flapper().live(), 0);
    }

    function test_cage_pot_drip() public {
        assertEq(pot.live(), 1);
        pot.drip();
        end.cage();

        assertEq(pot.live(), 0);
        assertEq(pot.dsr(), 10 ** 27);
        assertTrue(!try_pot_file("dsr", 10 ** 27 + 1));
    }

    // -- Scenario where there is one over-collateralised CDP
    // -- and there is no Vow deficit or surplus
    function test_cage_collateralised() public {
        Ilk memory gold = init_collateral("gold");

        Usr ali = new Usr(vat, end);

        // make a CDP:
        address urn1 = address(ali);
        gold.gemA.join(urn1, 10 ether);
        ali.frob("gold", urn1, urn1, urn1, 10 ether, 15 ether);
        // ali's urn has 0 gem, 10 ink, 15 tab, 15 dai

        // global checks:
        assertEq(vat.debt(), rad(15 ether));
        assertEq(vat.vice(), 0);

        // collateral price is 5
        gold.pip.poke(bytes32(5 * WAD));
        end.cage();
        end.cage("gold");
        end.skim("gold", urn1);

        // local checks:
        assertEq(art("gold", urn1), 0);
        assertEq(ink("gold", urn1), 7 ether);
        assertEq(vat.sin(address(vow)), rad(15 ether));

        // global checks:
        assertEq(vat.debt(), rad(15 ether));
        assertEq(vat.vice(), rad(15 ether));

        // CDP closing
        ali.free("gold");
        assertEq(ink("gold", urn1), 0);
        assertEq(gem("gold", urn1), 7 ether);
        ali.exit(gold.gemA, address(this), 7 ether);

        hevm.warp(now + 1 hours);
        end.thaw();
        end.flow("gold");
        assertTrue(end.fix("gold") != 0);

        // dai redemption
        ali.hope(address(end));
        ali.pack(15 ether);
        vow.heal(rad(15 ether));

        // global checks:
        assertEq(vat.debt(), 0);
        assertEq(vat.vice(), 0);

        ali.cash("gold", 15 ether);

        // local checks:
        assertEq(dai(urn1), 0);
        assertEq(gem("gold", urn1), 3 ether);
        ali.exit(gold.gemA, address(this), 3 ether);

        assertEq(gem("gold", address(end)), 0);
        assertEq(balanceOf("gold", address(gold.gemA)), 0);
    }

    // -- Scenario where there is one over-collateralised and one
    // -- under-collateralised CDP, and no Vow deficit or surplus
    function test_cage_undercollateralised() public {
        Ilk memory gold = init_collateral("gold");

        Usr ali = new Usr(vat, end);
        Usr bob = new Usr(vat, end);

        // make a CDP:
        address urn1 = address(ali);
        gold.gemA.join(urn1, 10 ether);
        ali.frob("gold", urn1, urn1, urn1, 10 ether, 15 ether);
        // ali's urn has 0 gem, 10 ink, 15 tab, 15 dai

        // make a second CDP:
        address urn2 = address(bob);
        gold.gemA.join(urn2, 1 ether);
        bob.frob("gold", urn2, urn2, urn2, 1 ether, 3 ether);
        // bob's urn has 0 gem, 1 ink, 3 tab, 3 dai

        // global checks:
        assertEq(vat.debt(), rad(18 ether));
        assertEq(vat.vice(), 0);

        // collateral price is 2
        gold.pip.poke(bytes32(2 * WAD));
        end.cage();
        end.cage("gold");
        end.skim("gold", urn1);  // over-collateralised
        end.skim("gold", urn2);  // under-collateralised

        // local checks
        assertEq(art("gold", urn1), 0);
        assertEq(ink("gold", urn1), 2.5 ether);
        assertEq(art("gold", urn2), 0);
        assertEq(ink("gold", urn2), 0);
        assertEq(vat.sin(address(vow)), rad(18 ether));

        // global checks
        assertEq(vat.debt(), rad(18 ether));
        assertEq(vat.vice(), rad(18 ether));

        // CDP closing
        ali.free("gold");
        assertEq(ink("gold", urn1), 0);
        assertEq(gem("gold", urn1), 2.5 ether);
        ali.exit(gold.gemA, address(this), 2.5 ether);

        hevm.warp(now + 1 hours);
        end.thaw();
        end.flow("gold");
        assertTrue(end.fix("gold") != 0);

        // first dai redemption
        ali.hope(address(end));
        ali.pack(15 ether);
        vow.heal(rad(15 ether));

        // global checks:
        assertEq(vat.debt(), rad(3 ether));
        assertEq(vat.vice(), rad(3 ether));

        ali.cash("gold", 15 ether);

        // local checks:
        assertEq(dai(urn1), 0);
        uint256 fix = end.fix("gold");
        assertEq(gem("gold", urn1), rmul(fix, 15 ether));
        ali.exit(gold.gemA, address(this), rmul(fix, 15 ether));

        // second dai redemption
        bob.hope(address(end));
        bob.pack(3 ether);
        vow.heal(rad(3 ether));

        // global checks:
        assertEq(vat.debt(), 0);
        assertEq(vat.vice(), 0);

        bob.cash("gold", 3 ether);

        // local checks:
        assertEq(dai(urn2), 0);
        assertEq(gem("gold", urn2), rmul(fix, 3 ether));
        bob.exit(gold.gemA, address(this), rmul(fix, 3 ether));

        // some dust remains in the End because of rounding:
        assertEq(gem("gold", address(end)), 1);
        assertEq(balanceOf("gold", address(gold.gemA)), 1);
    }

    // -- Scenario where there is one collateralised CDP
    // -- undergoing auction at the time of cage
    function test_cage_skip() public {
        Ilk memory gold = init_collateral("gold");

        Usr ali = new Usr(vat, end);

        // make a CDP:
        address urn1 = address(ali);
        gold.gemA.join(urn1, 10 ether);
        ali.frob("gold", urn1, urn1, urn1, 10 ether, 15 ether);
        // this urn has 0 gem, 10 ink, 15 tab, 15 dai

        vat.file("gold", "spot", ray(1 ether));     // now unsafe

        uint auction = cat.bite("gold", urn1);  // CDP liquidated
        assertEq(vat.vice(), rad(15 ether));    // now there is sin
        // get 1 dai from ali
        ali.move(address(ali), address(this), rad(1 ether));
        vat.hope(address(gold.flip));
        (,uint lot,,,,,,) = gold.flip.bids(auction);
        gold.flip.tend(auction, lot, rad(1 ether)); // bid 1 dai
        assertEq(dai(urn1), 14 ether);

        // collateral price is 5
        gold.pip.poke(bytes32(5 * WAD));
        end.cage();
        end.cage("gold");

        end.skip("gold", auction);
        assertEq(dai(address(this)), 1 ether);       // bid refunded
        vat.move(address(this), urn1, rad(1 ether)); // return 1 dai to ali

        end.skim("gold", urn1);

        // local checks:
        assertEq(art("gold", urn1), 0);
        assertEq(ink("gold", urn1), 7 ether);
        assertEq(vat.sin(address(vow)), rad(30 ether));

        // balance the vow
        vow.heal(min(vat.dai(address(vow)), vat.sin(address(vow))));
        // global checks:
        assertEq(vat.debt(), rad(15 ether));
        assertEq(vat.vice(), rad(15 ether));

        // CDP closing
        ali.free("gold");
        assertEq(ink("gold", urn1), 0);
        assertEq(gem("gold", urn1), 7 ether);
        ali.exit(gold.gemA, address(this), 7 ether);

        hevm.warp(now + 1 hours);
        end.thaw();
        end.flow("gold");
        assertTrue(end.fix("gold") != 0);

        // dai redemption
        ali.hope(address(end));
        ali.pack(15 ether);
        vow.heal(rad(15 ether));

        // global checks:
        assertEq(vat.debt(), 0);
        assertEq(vat.vice(), 0);

        ali.cash("gold", 15 ether);

        // local checks:
        assertEq(dai(urn1), 0);
        assertEq(gem("gold", urn1), 3 ether);
        ali.exit(gold.gemA, address(this), 3 ether);

        assertEq(gem("gold", address(end)), 0);
        assertEq(balanceOf("gold", address(gold.gemA)), 0);
    }

    // -- Scenario where there is one collateralised CDP
    // -- undergoing auction at the time of cage
    function test_cage_snip() public {
        Ilk memory gold = init_collateral("gold");

        Usr ali = new Usr(vat, end);

        vat.fold("gold", address(vow), int256(ray(0.25 ether)));

        // Make a CDP:
        address urn1 = address(ali);
        gold.gemA.join(urn1, 10 ether);
        ali.frob("gold", urn1, urn1, urn1, 10 ether, 15 ether);
        (uint ink1, uint art1) = vat.urns("gold", urn1); // CDP before liquidation
        (, uint rate,,,) = vat.ilks("gold");

        assertEq(vat.gem("gold", urn1), 0);
        assertEq(rate, ray(1.25 ether));
        assertEq(ink1, 10 ether);
        assertEq(art1, 15 ether);

        vat.file("gold", "spot", ray(1 ether)); // Now unsafe

        uint256 id = dog.bark("gold", urn1, address(this));

        uint256 tab1;
        uint256 lot1;
        {
            uint256 pos1;
            address usr1;
            uint96  tic1;
            uint256 top1;
            (pos1, tab1, lot1, usr1, tic1, top1) = gold.clip.sales(id);
            assertEq(pos1, 0);
            assertEq(tab1, art1 * rate * 1.1 ether / WAD); // tab uses chop
            assertEq(lot1, ink1);
            assertEq(usr1, address(ali));
            assertEq(uint256(tic1), now);
            assertEq(uint256(top1), ray(6 ether));
        }

        assertEq(dog.Dirt(), tab1);

        {
            (uint ink2, uint art2) = vat.urns("gold", urn1); // CDP after liquidation
            assertEq(ink2, 0);
            assertEq(art2, 0);
        }

        // Collateral price is $5
        gold.pip.poke(bytes32(5 * WAD));
        spot.poke("gold");
        end.cage();
        end.cage("gold");
        assertEq(end.tag("gold"), ray(0.2 ether)); // par / price = collateral per DAI

        assertEq(vat.gem("gold", address(gold.clip)), lot1); // From grab in dog.bark()
        assertEq(vat.sin(address(vow)),        art1 * rate); // From grab in dog.bark()
        assertEq(vat.vice(),                   art1 * rate); // From grab in dog.bark()
        assertEq(vat.debt(),                   art1 * rate); // From frob
        assertEq(vat.dai(address(vow)),                  0); // vat.suck() hasn't been called

        end.snip("gold", id);

        {
            uint256 pos2;
            uint256 tab2;
            uint256 lot2;
            address usr2;
            uint96  tic2;
            uint256 top2;
            (pos2, tab2, lot2, usr2, tic2, top2) = gold.clip.sales(id);
            assertEq(pos2,          0);
            assertEq(tab2,          0);
            assertEq(lot2,          0);
            assertEq(usr2,  address(0));
            assertEq(uint256(tic2), 0);
            assertEq(uint256(top2), 0);
        }

        assertEq(dog.Dirt(),                            0); // From clip.yank()
        assertEq(vat.gem("gold", address(gold.clip)),   0); // From clip.yank()
        assertEq(vat.gem("gold", address(end)),         0); // From grab in end.snip()
        assertEq(vat.sin(address(vow)),       art1 * rate); // From grab in dog.bark()
        assertEq(vat.vice(),                  art1 * rate); // From grab in dog.bark()
        assertEq(vat.debt(),           tab1 + art1 * rate); // From frob and suck
        assertEq(vat.dai(address(vow)),              tab1); // From vat.suck()
        assertEq(end.Art("gold") * rate,             tab1); // Incrementing total Art in End

        (uint ink3, uint art3) = vat.urns("gold", urn1);    // CDP after snip
        assertEq(ink3, 10 ether);                           // All collateral returned to CDP
        assertEq(art3, tab1 / rate);                        // Tab amount of normalized debt transferred back into CDP
    }

    // -- Scenario where there is one over-collateralised CDP
    // -- and there is a deficit in the Vow
    function test_cage_collateralised_deficit() public {
        Ilk memory gold = init_collateral("gold");

        Usr ali = new Usr(vat, end);

        // make a CDP:
        address urn1 = address(ali);
        gold.gemA.join(urn1, 10 ether);
        ali.frob("gold", urn1, urn1, urn1, 10 ether, 15 ether);
        // ali's urn has 0 gem, 10 ink, 15 tab, 15 dai
        // suck 1 dai and give to ali
        vat.suck(address(vow), address(ali), rad(1 ether));

        // global checks:
        assertEq(vat.debt(), rad(16 ether));
        assertEq(vat.vice(), rad(1 ether));

        // collateral price is 5
        gold.pip.poke(bytes32(5 * WAD));
        end.cage();
        end.cage("gold");
        end.skim("gold", urn1);

        // local checks:
        assertEq(art("gold", urn1), 0);
        assertEq(ink("gold", urn1), 7 ether);
        assertEq(vat.sin(address(vow)), rad(16 ether));

        // global checks:
        assertEq(vat.debt(), rad(16 ether));
        assertEq(vat.vice(), rad(16 ether));

        // CDP closing
        ali.free("gold");
        assertEq(ink("gold", urn1), 0);
        assertEq(gem("gold", urn1), 7 ether);
        ali.exit(gold.gemA, address(this), 7 ether);

        hevm.warp(now + 1 hours);
        end.thaw();
        end.flow("gold");
        assertTrue(end.fix("gold") != 0);

        // dai redemption
        ali.hope(address(end));
        ali.pack(16 ether);
        vow.heal(rad(16 ether));

        // global checks:
        assertEq(vat.debt(), 0);
        assertEq(vat.vice(), 0);

        ali.cash("gold", 16 ether);

        // local checks:
        assertEq(dai(urn1), 0);
        assertEq(gem("gold", urn1), 3 ether);
        ali.exit(gold.gemA, address(this), 3 ether);

        assertEq(gem("gold", address(end)), 0);
        assertEq(balanceOf("gold", address(gold.gemA)), 0);
    }

    // -- Scenario where there is one over-collateralised CDP
    // -- and one under-collateralised CDP and there is a
    // -- surplus in the Vow
    function test_cage_undercollateralised_surplus() public {
        Ilk memory gold = init_collateral("gold");

        Usr ali = new Usr(vat, end);
        Usr bob = new Usr(vat, end);

        // make a CDP:
        address urn1 = address(ali);
        gold.gemA.join(urn1, 10 ether);
        ali.frob("gold", urn1, urn1, urn1, 10 ether, 15 ether);
        // ali's urn has 0 gem, 10 ink, 15 tab, 15 dai
        // alive gives one dai to the vow, creating surplus
        ali.move(address(ali), address(vow), rad(1 ether));

        // make a second CDP:
        address urn2 = address(bob);
        gold.gemA.join(urn2, 1 ether);
        bob.frob("gold", urn2, urn2, urn2, 1 ether, 3 ether);
        // bob's urn has 0 gem, 1 ink, 3 tab, 3 dai

        // global checks:
        assertEq(vat.debt(), rad(18 ether));
        assertEq(vat.vice(), 0);

        // collateral price is 2
        gold.pip.poke(bytes32(2 * WAD));
        end.cage();
        end.cage("gold");
        end.skim("gold", urn1);  // over-collateralised
        end.skim("gold", urn2);  // under-collateralised

        // local checks
        assertEq(art("gold", urn1), 0);
        assertEq(ink("gold", urn1), 2.5 ether);
        assertEq(art("gold", urn2), 0);
        assertEq(ink("gold", urn2), 0);
        assertEq(vat.sin(address(vow)), rad(18 ether));

        // global checks
        assertEq(vat.debt(), rad(18 ether));
        assertEq(vat.vice(), rad(18 ether));

        // CDP closing
        ali.free("gold");
        assertEq(ink("gold", urn1), 0);
        assertEq(gem("gold", urn1), 2.5 ether);
        ali.exit(gold.gemA, address(this), 2.5 ether);

        hevm.warp(now + 1 hours);
        // balance the vow
        vow.heal(rad(1 ether));
        end.thaw();
        end.flow("gold");
        assertTrue(end.fix("gold") != 0);

        // first dai redemption
        ali.hope(address(end));
        ali.pack(14 ether);
        vow.heal(rad(14 ether));

        // global checks:
        assertEq(vat.debt(), rad(3 ether));
        assertEq(vat.vice(), rad(3 ether));

        ali.cash("gold", 14 ether);

        // local checks:
        assertEq(dai(urn1), 0);
        uint256 fix = end.fix("gold");
        assertEq(gem("gold", urn1), rmul(fix, 14 ether));
        ali.exit(gold.gemA, address(this), rmul(fix, 14 ether));

        // second dai redemption
        bob.hope(address(end));
        bob.pack(3 ether);
        vow.heal(rad(3 ether));

        // global checks:
        assertEq(vat.debt(), 0);
        assertEq(vat.vice(), 0);

        bob.cash("gold", 3 ether);

        // local checks:
        assertEq(dai(urn2), 0);
        assertEq(gem("gold", urn2), rmul(fix, 3 ether));
        bob.exit(gold.gemA, address(this), rmul(fix, 3 ether));

        // nothing left in the End
        assertEq(gem("gold", address(end)), 0);
        assertEq(balanceOf("gold", address(gold.gemA)), 0);
    }

    // -- Scenario where there is one over-collateralised and one
    // -- under-collateralised CDP of different collateral types
    // -- and no Vow deficit or surplus
    function test_cage_net_undercollateralised_multiple_ilks() public {
        Ilk memory gold = init_collateral("gold");
        Ilk memory coal = init_collateral("coal");

        Usr ali = new Usr(vat, end);
        Usr bob = new Usr(vat, end);

        // make a CDP:
        address urn1 = address(ali);
        gold.gemA.join(urn1, 10 ether);
        ali.frob("gold", urn1, urn1, urn1, 10 ether, 15 ether);
        // ali's urn has 0 gem, 10 ink, 15 tab

        // make a second CDP:
        address urn2 = address(bob);
        coal.gemA.join(urn2, 1 ether);
        vat.file("coal", "spot", ray(5 ether));
        bob.frob("coal", urn2, urn2, urn2, 1 ether, 5 ether);
        // bob's urn has 0 gem, 1 ink, 5 tab

        gold.pip.poke(bytes32(2 * WAD));
        // urn1 has 20 dai of ink and 15 dai of tab
        coal.pip.poke(bytes32(2 * WAD));
        // urn2 has 2 dai of ink and 5 dai of tab
        end.cage();
        end.cage("gold");
        end.cage("coal");
        end.skim("gold", urn1);  // over-collateralised
        end.skim("coal", urn2);  // under-collateralised

        hevm.warp(now + 1 hours);
        end.thaw();
        end.flow("gold");
        end.flow("coal");

        ali.hope(address(end));
        bob.hope(address(end));

        assertEq(vat.debt(),             rad(20 ether));
        assertEq(vat.vice(),             rad(20 ether));
        assertEq(vat.sin(address(vow)),  rad(20 ether));

        assertEq(end.Art("gold"), 15 ether);
        assertEq(end.Art("coal"),  5 ether);

        assertEq(end.gap("gold"),  0.0 ether);
        assertEq(end.gap("coal"),  1.5 ether);

        // there are 7.5 gold and 1 coal
        // the gold is worth 15 dai and the coal is worth 2 dai
        // the total collateral pool is worth 17 dai
        // the total outstanding debt is 20 dai
        // each dai should get (15/2)/20 gold and (2/2)/20 coal
        assertEq(end.fix("gold"), ray(0.375 ether));
        assertEq(end.fix("coal"), ray(0.050 ether));

        assertEq(gem("gold", address(ali)), 0 ether);
        ali.pack(1 ether);
        ali.cash("gold", 1 ether);
        assertEq(gem("gold", address(ali)), 0.375 ether);

        bob.pack(1 ether);
        bob.cash("coal", 1 ether);
        assertEq(gem("coal", address(bob)), 0.05 ether);

        ali.exit(gold.gemA, address(ali), 0.375 ether);
        bob.exit(coal.gemA, address(bob), 0.05  ether);
        ali.pack(1 ether);
        ali.cash("gold", 1 ether);
        ali.cash("coal", 1 ether);
        assertEq(gem("gold", address(ali)), 0.375 ether);
        assertEq(gem("coal", address(ali)), 0.05 ether);

        ali.exit(gold.gemA, address(ali), 0.375 ether);
        ali.exit(coal.gemA, address(ali), 0.05  ether);

        ali.pack(1 ether);
        ali.cash("gold", 1 ether);
        assertEq(end.out("gold", address(ali)), 3 ether);
        assertEq(end.out("coal", address(ali)), 1 ether);
        ali.pack(1 ether);
        ali.cash("coal", 1 ether);
        assertEq(end.out("gold", address(ali)), 3 ether);
        assertEq(end.out("coal", address(ali)), 2 ether);
        assertEq(gem("gold", address(ali)), 0.375 ether);
        assertEq(gem("coal", address(ali)), 0.05 ether);
    }

    // -- Scenario where flow() used to overflow
    function test_overflow() public {
        Ilk memory gold = init_collateral("gold");

        Usr ali = new Usr(vat, end);

        // make a CDP:
        address urn1 = address(ali);
        gold.gemA.join(urn1, 500_000 ether);
        ali.frob("gold", urn1, urn1, urn1, 500_000 ether, 1_000_000 ether);
        // ali's urn has 500_000 ink, 10^6 art (and 10^6 dai since rate == RAY)

        // global checks:
        assertEq(vat.debt(), rad(1_000_000 ether));
        assertEq(vat.vice(), 0);

        // collateral price is 5
        gold.pip.poke(bytes32(5 * WAD));
        end.cage();
        end.cage("gold");
        end.skim("gold", urn1);

        // local checks:
        assertEq(art("gold", urn1), 0);
        assertEq(ink("gold", urn1), 300_000 ether);
        assertEq(vat.sin(address(vow)), rad(1_000_000 ether));

        // global checks:
        assertEq(vat.debt(), rad(1_000_000 ether));
        assertEq(vat.vice(), rad(1_000_000 ether));

        // CDP closing
        ali.free("gold");
        assertEq(ink("gold", urn1), 0);
        assertEq(gem("gold", urn1), 300_000 ether);
        ali.exit(gold.gemA, address(this), 300_000 ether);

        hevm.warp(now + 1 hours);
        end.thaw();
        end.flow("gold");
    }

    uint256 constant RAD = 10**45;
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, WAD) / y;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, RAY) / y;
    }
    function fix_calc_0(uint256 col, uint256 debt) internal pure returns (uint256) {
        return rdiv(mul(col, RAY), debt);
    }
    function fix_calc_1(uint256 col, uint256 debt) internal pure returns (uint256) {
        return wdiv(mul(col, RAY), (debt / 10**9));
    }
    function fix_calc_2(uint256 col, uint256 debt) internal pure returns (uint256) {
        return mul(col, RAY) / (debt / RAY);
    }
    function wAssertCloseEnough(uint256 x, uint256 y) internal {
        uint256 diff = x > y ? x - y : y - x;
        if (diff == 0) return;
        uint256 xErr = mul(diff, WAD) / x;
        uint256 yErr = mul(diff, WAD) / y;
        uint256 err  = xErr > yErr ? xErr : yErr;
        assertTrue(err < WAD / 100_000_000);  // Error no more than one part in a hundred million
    }
    uint256 constant MIN_DEBT   = 10**6 * RAD;  // Minimum debt for fuzz runs
    uint256 constant REDEEM_AMT = 1_000 * WAD;  // Amount of DAI to redeem for error checking
    function test_fuzz_fix_calcs_0_1(uint256 col_seed, uint192 debt_seed) public {
        uint256 col = col_seed % (115792 * WAD);  // somewhat biased, but not enough to matter
        if (col < 10**12) col += 10**12;  // At least 10^-6 WAD units of collateral; this makes the fixes almost always non-zero.
        uint256 debt = debt_seed;
        if (debt < MIN_DEBT) debt += MIN_DEBT;  // consider at least MIN_DEBT of debt

        uint256 fix0 = fix_calc_0(col, debt);
        uint256 fix1 = fix_calc_1(col, debt);

        // how much collateral can be obtained with a single DAI in each case
        uint256 col0 = rmul(REDEEM_AMT, fix0);
        uint256 col1 = rmul(REDEEM_AMT, fix1);

        // Assert on percentage error of returned collateral
        wAssertCloseEnough(col0, col1);
    }
    function test_fuzz_fix_calcs_0_2(uint256 col_seed, uint192 debt_seed) public {
        uint256 col = col_seed % (115792 * WAD);  // somewhat biased, but not enough to matter
        if (col < 10**12) col += 10**12;  // At least 10^-6 WAD units of collateral; this makes the fixes almost always non-zero.
        uint256 debt = debt_seed;
        if (debt < MIN_DEBT) debt += MIN_DEBT;  // consider at least MIN_DEBT of debt

        uint256 fix0 = fix_calc_0(col, debt);
        uint256 fix2 = fix_calc_2(col, debt);

        // how much collateral can be obtained with a single DAI in each case
        uint256 col0 = rmul(REDEEM_AMT, fix0);
        uint256 col2 = rmul(REDEEM_AMT, fix2);

        // Assert on percentage error of returned collateral
        wAssertCloseEnough(col0, col2);
    }
    function test_fuzz_fix_calcs_1_2(uint256 col_seed, uint192 debt_seed) public {
        uint256 col = col_seed % (10**14 * WAD);  // somewhat biased, but not enough to matter
        if (col < 10**12) col += 10**12;  // At least 10^-6 WAD units of collateral; this makes the fixes almost always non-zero.
        uint256 debt = debt_seed;
        if (debt < MIN_DEBT) debt += MIN_DEBT;  // consider at least MIN_DEBT of debt

        uint256 fix1 = fix_calc_1(col, debt);
        uint256 fix2 = fix_calc_2(col, debt);

        // how much collateral can be obtained with a single DAI in each case
        uint256 col1 = rmul(REDEEM_AMT, fix1);
        uint256 col2 = rmul(REDEEM_AMT, fix2);

        // Assert on percentage error of returned collateral
        wAssertCloseEnough(col1, col2);
    }
}
