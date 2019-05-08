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

contract PipLike {
    function read() public returns (bytes32);
    function poke(bytes32 val) public;
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
    GemJoin public gemA;

    constructor(Vat vat_, End end_, GemJoin gemA_) public {
        vat  = vat_;
        end  = end_;
        gemA = gemA_;
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
    function join(address urn, uint wad) public {
        gemA.join(urn, wad);
    }
    function exit(address usr, uint wad) public {
        gemA.exit(usr, wad);
    }
    function free(bytes32 ilk) public {
        end.free(ilk);
    }
    function shop(uint256 rad) public {
        end.shop(rad);
    }
    function pack(bytes32 ilk) public {
        end.pack(ilk);
    }
    function cash(bytes32 ilk) public {
        end.cash(ilk);
    }
}

contract EndTest is DSTest {
    Hevm hevm;

    Vat   vat;
    End   end;
    Vow   vow;
    Cat   cat;

    DSToken gold;

    PipLike pip;
    TestSpot spot;

    GemJoin gemA;

    Flipper flip;
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

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(0);

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

        gold = new DSToken("GEM");
        gold.mint(20 ether);

        pip = PipLike(address(new DSValue()));
        spot = new TestSpot();
        spot.file("gold", address(pip));
        // initial collateral price of 5
        pip.poke(bytes32(5 * RAY));

        vat.init("gold");
        gemA = new GemJoin(address(vat), "gold", address(gold));

        // 1 gold = 6 dai and liquidation ratio is 200%
        vat.file("gold", "spot",    ray(3 ether));
        vat.file("gold", "line", rad(1000 ether));
        vat.file("Line",         rad(1000 ether));

        gold.approve(address(gemA));
        gold.approve(address(vat));

        vat.rely(address(gemA));

        flip = new Flipper(address(vat), "gold");
        cat.file("gold", "flip", address(flip));
        cat.file("gold", "chop", ray(1 ether));
        cat.file("gold", "lump", rad(15 ether));
        vat.hope(address(flip));

        end = new End();
        end.file("vat", address(vat));
        end.file("cat", address(cat));
        end.file("vow", address(vow));
        end.file("spot", address(spot));
        end.file("wait", 1 hours);
        vat.rely(address(end));
        vow.rely(address(end));
        cat.rely(address(end));
        flip.rely(address(end));
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

    function test_cage_collateralised() public {
        Usr ali = new Usr(vat, end, gemA);

        // make a CDP:
        address urn1 = address(ali);
        gemA.join(urn1, 10 ether);
        ali.frob("gold", urn1, urn1, urn1, 10 ether, 15 ether);
        // ali's urn has 0 gem, 10 ink, 15 tab, 15 dai

        // global checks:
        assertEq(vat.debt(), rad(15 ether));
        assertEq(vat.vice(), 0);

        // collateral price is 5
        pip.poke(bytes32(5 * RAY));
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
        ali.exit(address(this), 7 ether);

        hevm.warp(1 hours);
        end.thaw();
        end.flow("gold");
        assertTrue(end.fixs("gold") != 0);

        // dai redemption
        ali.hope(address(end));
        ali.shop(15 ether);

        // global checks:
        assertEq(vat.debt(), 0);
        assertEq(vat.vice(), 0);

        ali.pack("gold");
        ali.cash("gold");

        // local checks:
        assertEq(dai(urn1), 0);
        assertEq(gem("gold", urn1), 3 ether);
        ali.exit(address(this), 3 ether);

        assertEq(gem("gold", address(end)), 0);
        assertEq(gold.balanceOf(address(gemA)), 0);
    }

    function test_cage_undercollateralised_cdp_parity() public {
        Usr ali = new Usr(vat, end, gemA);
        Usr bob = new Usr(vat, end, gemA);

        // make a CDP:
        address urn1 = address(ali);
        gemA.join(urn1, 10 ether);
        ali.frob("gold", urn1, urn1, urn1, 10 ether, 15 ether);
        // ali's urn has 0 gem, 10 ink, 15 tab, 15 dai

        // make a second CDP:
        address urn2 = address(bob);
        gemA.join(urn2, 1 ether);
        bob.frob("gold", urn2, urn2, urn2, 1 ether, 3 ether);
        // bob's urn has 0 gem, 1 ink, 3 tab, 3 dai

        // global checks:
        assertEq(vat.debt(), rad(18 ether));
        assertEq(vat.vice(), 0);

        // collateral price is 2
        pip.poke(bytes32(2 * RAY));
        end.cage();
        end.cage("gold");
        end.skim("gold", urn1);
        // undercollateralised CDP is bailed
        end.bail("gold", urn2);

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
        ali.exit(address(this), 2.5 ether);

        hevm.warp(1 hours);
        end.thaw();
        end.flow("gold");
        assertTrue(end.fixs("gold") != 0);

        // first dai redemption
        ali.hope(address(end));
        ali.shop(15 ether);

        // global checks:
        assertEq(vat.debt(), rad(3 ether));
        assertEq(vat.vice(), rad(3 ether));

        ali.pack("gold");
        ali.cash("gold");

        // local checks:
        assertEq(dai(urn1), 0);
        uint256 fix = end.fixs("gold");
        assertEq(gem("gold", urn1), rmul(fix, 15 ether));
        ali.exit(address(this), rmul(fix, 15 ether));

        // second dai redemption
        bob.hope(address(end));
        bob.shop(3 ether);

        // global checks:
        assertEq(vat.debt(), 0);
        assertEq(vat.vice(), 0);

        bob.pack("gold");
        bob.cash("gold");

        // local checks:
        assertEq(dai(urn2), 0);
        assertEq(gem("gold", urn2), rmul(fix, 3 ether));
        bob.exit(address(this), rmul(fix, 3 ether));

        // some dust remains in the End because of rounding:
        assertEq(gem("gold", address(end)), 1);
        assertEq(gold.balanceOf(address(gemA)), 1);
    }

    function test_cage_skip() public {
        Usr ali = new Usr(vat, end, gemA);

        // make a CDP:
        address urn1 = address(ali);
        gemA.join(urn1, 10 ether);
        ali.frob("gold", urn1, urn1, urn1, 10 ether, 15 ether);
        // this urn has 0 gem, 10 ink, 15 tab, 15 dai

        vat.file("gold", "spot", ray(1 ether));     // now unsafe

        uint id = cat.bite("gold", urn1);           // CDP liquidated
        assertEq(vat.vice(), rad(15 ether));        // now there is sin
        uint auction = cat.flip(id, rad(15 ether)); // flip all the tab
        // get 1 dai from ali
        ali.move(address(ali), address(this), rad(1 ether));
        vat.hope(address(flip));
        flip.tend(auction, 10 ether, rad(1 ether)); // bid 1 dai
        assertEq(dai(urn1), 14 ether);

        // collateral price is 5
        pip.poke(bytes32(5 * RAY));
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
        vow.flog(uint48(now));
        vow.heal(min(vow.Joy(), vow.Woe()));
        vow.kiss(min(vow.Joy(), vow.Ash()));
        // global checks:
        assertEq(vat.debt(), rad(15 ether));
        assertEq(vat.vice(), rad(15 ether));

        // CDP closing
        ali.free("gold");
        assertEq(ink("gold", urn1), 0);
        assertEq(gem("gold", urn1), 7 ether);
        ali.exit(address(this), 7 ether);

        hevm.warp(1 hours);
        end.thaw();
        end.flow("gold");
        assertTrue(end.fixs("gold") != 0);

        // dai redemption
        ali.hope(address(end));
        ali.shop(15 ether);

        // global checks:
        // no need for vent
        assertEq(vat.debt(), 0);
        assertEq(vat.vice(), 0);

        ali.pack("gold");
        ali.cash("gold");

        // local checks:
        assertEq(dai(urn1), 0);
        assertEq(gem("gold", urn1), 3 ether);
        ali.exit(address(this), 3 ether);

        assertEq(gem("gold", address(end)), 0);
        assertEq(gold.balanceOf(address(gemA)), 0);
    }
}
