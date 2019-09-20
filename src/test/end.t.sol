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

pragma solidity >=0.5.0;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import {Vat}  from '../vat.sol';
import {Cat}  from '../cat.sol';
import {Vow}  from '../vow.sol';
import {Flipper} from '../flip.sol';
import {Flapper} from '../flap.sol';
import {Flopper} from '../flop.sol';
import {GemJoin} from '../join.sol';
import {End}  from '../end.sol';

contract Hevm {
    function warp(uint256) public;
}

contract TestSpot {
    struct Ilk {
        address pip;
        uint256 mat;
    }
    mapping (bytes32 => Ilk) public ilks;

    function file(bytes32 ilk, address pip_) public {
        ilks[ilk].pip = pip_;
    }
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
    Cat   cat;

    TestSpot spot;

    struct Ilk {
        DSValue pip;
        DSToken gem;
        GemJoin gemA;
        Flipper flip;
    }

    mapping (bytes32 => Ilk) ilks;

    Flapper flap;
    Flopper flop;

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

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

    function init_collateral(bytes32 name) internal returns (Ilk memory) {
        DSToken coin = new DSToken(name);
        coin.mint(20 ether);

        DSValue pip = new DSValue();
        spot.file(name, address(pip));
        // initial collateral price of 5
        pip.poke(bytes32(5 * WAD));

        vat.init(name);
        GemJoin gemA = new GemJoin(address(vat), name, address(coin));

        // 1 coin = 6 dai and liquidation ratio is 200%
        vat.file(name, "spot",    ray(3 ether));
        vat.file(name, "line", rad(1000 ether));

        coin.approve(address(gemA));
        coin.approve(address(vat));

        vat.rely(address(gemA));

        Flipper flip = new Flipper(address(vat), name);
        vat.hope(address(flip));
        flip.rely(address(end));
        cat.file(name, "flip", address(flip));
        cat.file(name, "chop", ray(1 ether));
        cat.file(name, "lump", rad(15 ether));

        ilks[name].pip = pip;
        ilks[name].gem = coin;
        ilks[name].gemA = gemA;
        ilks[name].flip = flip;

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

        cat = new Cat(address(vat));
        cat.file("vow", address(vow));
        vat.rely(address(cat));
        vow.rely(address(cat));

        spot = new TestSpot();
        vat.file("Line",         rad(1000 ether));

        end = new End();
        end.file("vat", address(vat));
        end.file("cat", address(cat));
        end.file("vow", address(vow));
        end.file("spot", address(spot));
        end.file("wait", 1 hours);
        vat.rely(address(end));
        vow.rely(address(end));
        cat.rely(address(end));
        flap.rely(address(vow));
        flop.rely(address(vow));
    }

    function test_cage_basic() public {
        assertEq(end.live(), 1);
        assertEq(vat.live(), 1);
        assertEq(cat.live(), 1);
        assertEq(vow.live(), 1);
        assertEq(vow.flopper().live(), 1);
        assertEq(vow.flapper().live(), 1);
        end.cage();
        assertEq(end.live(), 0);
        assertEq(vat.live(), 0);
        assertEq(cat.live(), 0);
        assertEq(vow.live(), 0);
        assertEq(vow.flopper().live(), 0);
        assertEq(vow.flapper().live(), 0);
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
        gold.flip.tend(auction, 10 ether, rad(1 ether)); // bid 1 dai
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
}
