pragma solidity >=0.5.0;

import "ds-test/test.sol";
import "ds-token/token.sol";

import {Vat} from './tune.sol';
import {Pit} from './frob.sol';
import {Cat} from './bite.sol';
import {Vow} from './heal.sol';
import {Drip} from './drip.sol';
import {GemJoin, ETHJoin, DaiJoin} from './join.sol';
import {GemMove, DaiMove} from './move.sol';

import {Flipper} from './flip.t.sol';
import {Flopper} from './flop.t.sol';
import {Flapper} from './flap.t.sol';


contract Hevm {
    function warp(uint256) public;
}

contract TestVat is Vat {
    uint256 constant ONE = 10 ** 27;
    function mint(address guy, uint wad) public {
        dai[bytes32(bytes20(guy))] += wad * ONE;
        debt              += wad * ONE;
    }
    function balanceOf(address guy) public view returns (uint) {
        return dai[bytes32(bytes20(guy))] / ONE;
    }
}

contract Guy {
    function try_call(address addr, bytes calldata data) external returns (bool) {
        bytes memory _data = data;
        assembly {
            let ok := call(gas, addr, 0, add(_data, 0x20), mload(_data), 0, 0)
            let free := mload(0x40)
            mstore(free, ok)
            mstore(0x40, add(free, 32))
            revert(free, 32)
        }
    }
    function can_frob(address pit, bytes32 ilk, bytes32 u, bytes32 v, bytes32 w, int dink, int dart) public returns (bool) {
        string memory sig = "frob(bytes32,bytes32,bytes32,bytes32,int256,int256)";
        bytes memory data = abi.encodeWithSignature(sig, ilk, u, v, w, dink, dart);

        bytes memory can_call = abi.encodeWithSignature("try_call(address,bytes)", pit, data);
        (bool ok, bytes memory success) = address(this).call(can_call);

        ok = abi.decode(success, (bool));
        if (ok) return true;
    }
    function frob(address pit, bytes32 ilk, bytes32 u, bytes32 v, bytes32 w, int dink, int dart) public returns (bool) {
        Pit(pit).frob(ilk, u, v, w, dink, dart);
    }
}


contract FrobTest is DSTest {
    TestVat vat;
    Pit     pit;
    DSToken gold;
    Drip    drip;

    GemJoin gemA;

    function try_frob(bytes32 ilk, int ink, int art) public returns (bool ok) {
        string memory sig = "frob(bytes32,bytes32,int256,int256)";
        bytes32 self = bytes32(bytes20(address(this)));
        (ok,) = address(pit).call(abi.encodeWithSignature(sig, ilk, self, ink, art));
    }

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }

    function setUp() public {
        vat = new TestVat();
        pit = new Pit(address(vat));

        gold = new DSToken("GEM");
        gold.mint(1000 ether);

        vat.init("gold");
        gemA = new GemJoin(address(vat), "gold", address(gold));

        pit.file("gold", "spot", ray(1 ether));
        pit.file("gold", "line", 1000 ether);
        pit.file("Line", uint(1000 ether));
        drip = new Drip(address(vat));
        drip.init("gold");
        vat.rely(address(drip));

        gold.approve(address(gemA));
        gold.approve(address(vat));

        vat.rely(address(pit));
        vat.rely(address(gemA));

        gemA.join(bytes32(bytes20(address(this))), 1000 ether);
    }

    function gem(bytes32 ilk, address urn) internal view returns (uint) {
        return vat.gem(ilk, bytes32(bytes20(urn))) / 10 ** 27;
    }
    function ink(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, bytes32(bytes20(urn))); art_;
        return ink_;
    }
    function art(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, bytes32(bytes20(urn))); ink_;
        return art_;
    }


    function test_join() public {
        bytes32 urn = bytes32(bytes20(address(this)));
        gold.mint(500 ether);
        assertEq(gold.balanceOf(address(this)),    500 ether);
        assertEq(gold.balanceOf(address(gemA)),   1000 ether);
        gemA.join(urn,                             500 ether);
        assertEq(gold.balanceOf(address(this)),      0 ether);
        assertEq(gold.balanceOf(address(gemA)),   1500 ether);
        gemA.exit(urn, address(this),              250 ether);
        assertEq(gold.balanceOf(address(this)),    250 ether);
        assertEq(gold.balanceOf(address(gemA)),   1250 ether);
    }
    function test_lock() public {
        assertEq(ink("gold", address(this)),    0 ether);
        assertEq(gem("gold", address(this)), 1000 ether);
        pit.frob("gold", 6 ether, 0);
        assertEq(ink("gold", address(this)),   6 ether);
        assertEq(gem("gold", address(this)), 994 ether);
        pit.frob("gold", -6 ether, 0);
        assertEq(ink("gold", address(this)),    0 ether);
        assertEq(gem("gold", address(this)), 1000 ether);
    }
    function test_calm() public {
        // calm means that the debt ceiling is not exceeded
        // it's ok to increase debt as long as you remain calm
        pit.file("gold", 'line', 10 ether);
        assertTrue( try_frob("gold", 10 ether, 9 ether));
        // only if under debt ceiling
        assertTrue(!try_frob("gold",  0 ether, 2 ether));
    }
    function test_cool() public {
        // cool means that the debt has decreased
        // it's ok to be over the debt ceiling as long as you're cool
        pit.file("gold", 'line', 10 ether);
        assertTrue(try_frob("gold", 10 ether,  8 ether));
        pit.file("gold", 'line', 5 ether);
        // can decrease debt when over ceiling
        assertTrue(try_frob("gold",  0 ether, -1 ether));
    }
    function test_safe() public {
        // safe means that the cdp is not risky
        // you can't frob a cdp into unsafe
        pit.frob("gold", 10 ether, 5 ether);                // safe draw
        assertTrue(!try_frob("gold", 0 ether, 6 ether));  // unsafe draw
    }
    function test_nice() public {
        // nice means that the collateral has increased or the debt has
        // decreased. remaining unsafe is ok as long as you're nice

        pit.frob("gold", 10 ether, 10 ether);
        pit.file("gold", 'spot', ray(0.5 ether));  // now unsafe

        // debt can't increase if unsafe
        assertTrue(!try_frob("gold",  0 ether,  1 ether));
        // debt can decrease
        assertTrue( try_frob("gold",  0 ether, -1 ether));
        // ink can't decrease
        assertTrue(!try_frob("gold", -1 ether,  0 ether));
        // ink can increase
        assertTrue( try_frob("gold",  1 ether,  0 ether));

        // cdp is still unsafe
        // ink can't decrease, even if debt decreases more
        assertTrue(!this.try_frob("gold", -2 ether, -4 ether));
        // debt can't increase, even if ink increases more
        assertTrue(!this.try_frob("gold",  5 ether,  1 ether));

        // ink can decrease if end state is safe
        assertTrue( this.try_frob("gold", -1 ether, -4 ether));
        pit.file("gold", 'spot', ray(0.4 ether));  // now unsafe
        // debt can increase if end state is safe
        assertTrue( this.try_frob("gold",  5 ether, 1 ether));
    }

    function b32(address addr) internal pure returns (bytes32) {
        return bytes32(bytes20(addr));
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
    function test_alt_callers() public {
        Guy ali = new Guy();
        Guy bob = new Guy();
        Guy che = new Guy();

        bytes32 a = b32(address(ali));
        bytes32 b = b32(address(bob));
        bytes32 c = b32(address(che));

        vat.slip("gold", a, int(rad(20 ether)));
        vat.slip("gold", b, int(rad(20 ether)));
        vat.slip("gold", c, int(rad(20 ether)));

        ali.frob(address(pit), "gold", a, a, a, 10 ether, 5 ether);

        // anyone can lock
        assertTrue( ali.can_frob(address(pit), "gold", a, a, a,  1 ether,  0 ether));
        assertTrue( bob.can_frob(address(pit), "gold", a, b, b,  1 ether,  0 ether));
        assertTrue( che.can_frob(address(pit), "gold", a, c, c,  1 ether,  0 ether));
        // but only with their own gems
        assertTrue(!ali.can_frob(address(pit), "gold", a, b, a,  1 ether,  0 ether));
        assertTrue(!bob.can_frob(address(pit), "gold", a, c, b,  1 ether,  0 ether));
        assertTrue(!che.can_frob(address(pit), "gold", a, a, c,  1 ether,  0 ether));

        // only the lad can free
        assertTrue( ali.can_frob(address(pit), "gold", a, a, a, -1 ether,  0 ether));
        assertTrue(!bob.can_frob(address(pit), "gold", a, b, b, -1 ether,  0 ether));
        assertTrue(!che.can_frob(address(pit), "gold", a, c, c, -1 ether,  0 ether));
        // the lad can free to anywhere
        assertTrue( ali.can_frob(address(pit), "gold", a, b, a, -1 ether,  0 ether));
        assertTrue( ali.can_frob(address(pit), "gold", a, c, a, -1 ether,  0 ether));

        // only the lad can draw
        assertTrue( ali.can_frob(address(pit), "gold", a, a, a,  0 ether,  1 ether));
        assertTrue(!bob.can_frob(address(pit), "gold", a, b, b,  0 ether,  1 ether));
        assertTrue(!che.can_frob(address(pit), "gold", a, c, c,  0 ether,  1 ether));
        // the lad can draw to anywhere
        assertTrue( ali.can_frob(address(pit), "gold", a, a, b,  0 ether,  1 ether));
        assertTrue( ali.can_frob(address(pit), "gold", a, a, c,  0 ether,  1 ether));

        vat.move(a, b, int(rad(1 ether)));
        vat.move(a, c, int(rad(1 ether)));

        // anyone can wipe
        assertTrue( ali.can_frob(address(pit), "gold", a, a, a,  0 ether, -1 ether));
        assertTrue( bob.can_frob(address(pit), "gold", a, b, b,  0 ether, -1 ether));
        assertTrue( che.can_frob(address(pit), "gold", a, c, c,  0 ether, -1 ether));
        // but only with their own dai
        assertTrue(!ali.can_frob(address(pit), "gold", a, a, b,  0 ether, -1 ether));
        assertTrue(!bob.can_frob(address(pit), "gold", a, b, c,  0 ether, -1 ether));
        assertTrue(!che.can_frob(address(pit), "gold", a, c, a,  0 ether, -1 ether));
    }
}

contract JoinTest is DSTest {
    TestVat vat;
    ETHJoin ethA;
    DaiJoin daiA;
    DSToken dai;
    bytes32 me;

    function setUp() public {
        vat = new TestVat();
        vat.init("eth");

        ethA = new ETHJoin(address(vat), "eth");
        vat.rely(address(ethA));

        dai  = new DSToken("Dai");
        daiA = new DaiJoin(address(vat), address(dai));
        vat.rely(address(daiA));
        dai.setOwner(address(daiA));

        me = bytes32(bytes20(address(this)));
    }
    function () external payable {}
    function test_eth_join() public {
        ethA.join.value(10 ether)(bytes32(bytes20(address(this))));
        assertEq(vat.gem("eth", me), rad(10 ether));
    }
    function test_eth_exit() public {
        bytes32 urn = bytes32(bytes20(address(this)));
        ethA.join.value(50 ether)(urn);
        ethA.exit(urn, address(this), 10 ether);
        assertEq(vat.gem("eth", me), rad(40 ether));
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
    function test_dai_exit() public {
        bytes32 urn = bytes32(bytes20(address(this)));
        vat.mint(address(this), 100 ether);
        daiA.exit(urn, address(this), 60 ether);
        assertEq(dai.balanceOf(address(this)), 60 ether);
        assertEq(vat.dai(me),              rad(40 ether));
    }
    function test_dai_exit_join() public {
        bytes32 urn = bytes32(bytes20(address(this)));
        vat.mint(address(this), 100 ether);
        daiA.exit(urn, address(this), 60 ether);
        dai.approve(address(daiA), uint(-1));
        daiA.join(urn, 30 ether);
        assertEq(dai.balanceOf(address(this)),     30 ether);
        assertEq(vat.dai(me),                  rad(70 ether));
    }
    function test_fallback_reverts() public {
        (bool ok,) = address(ethA).call("invalid calldata");
        assertTrue(!ok);
    }
    function test_nonzero_fallback_reverts() public {
        (bool ok,) = address(ethA).call.value(10)("invalid calldata");
        assertTrue(!ok);
    }
}

contract BiteTest is DSTest {
    Hevm hevm;

    TestVat vat;
    Pit     pit;
    Vow     vow;
    Cat     cat;
    DSToken gold;
    Drip    drip;

    GemJoin gemA;
    GemMove gemM;
    DaiMove daiM;

    Flipper flip;
    Flopper flop;
    Flapper flap;

    DSToken gov;

    function try_frob(bytes32 ilk, int ink, int art) public returns (bool ok) {
        string memory sig = "frob(bytes32,int256,int256)";
        (ok,) = address(vat).call(abi.encodeWithSignature(sig, ilk, ink, art));
    }

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }

    function gem(bytes32 ilk, address urn) internal view returns (uint) {
        return vat.gem(ilk, bytes32(bytes20(urn))) / 10 ** 27;
    }
    function ink(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, bytes32(bytes20(urn))); art_;
        return ink_;
    }
    function art(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, bytes32(bytes20(urn))); ink_;
        return art_;
    }

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(0);

        gov = new DSToken('GOV');
        gov.mint(100 ether);

        vat = new TestVat();
        pit = new Pit(address(vat));
        vat.rely(address(pit));

        daiM = new DaiMove(address(vat));
        vat.rely(address(daiM));

        flap = new Flapper(address(daiM), address(gov));
        flop = new Flopper(address(daiM), address(gov));
        gov.setOwner(address(flop));

        vow = new Vow();
        vow.file("vat",  address(vat));
        vow.file("flap", address(flap));
        vow.file("flop", address(flop));
        flop.rely(address(vow));

        drip = new Drip(address(vat));
        drip.init("gold");
        drip.file("vow", bytes32(bytes20(address(vow))));
        vat.rely(address(drip));

        cat = new Cat(address(vat));
        cat.file("pit", address(pit));
        cat.file("vow", address(vow));
        vat.rely(address(cat));
        vow.rely(address(cat));

        gold = new DSToken("GEM");
        gold.mint(1000 ether);

        vat.init("gold");
        gemA = new GemJoin(address(vat), "gold", address(gold));
        vat.rely(address(gemA));
        gold.approve(address(gemA));
        gemA.join(bytes32(bytes20(address(this))), 1000 ether);

        gemM = new GemMove(address(vat), "gold");
        vat.rely(address(gemM));

        pit.file("gold", "spot", ray(1 ether));
        pit.file("gold", "line", 1000 ether);
        pit.file("Line", uint(1000 ether));
        flip = new Flipper(address(daiM), address(gemM));
        cat.file("gold", "flip", address(flip));
        cat.file("gold", "chop", ray(1 ether));

        vat.rely(address(flip));
        vat.rely(address(flap));
        vat.rely(address(flop));

        daiM.hope(address(flip));
        daiM.hope(address(flop));
        gold.approve(address(vat));
        gov.approve(address(flap));
    }
    function test_happy_bite() public {
        // spot = tag / (par . mat)
        // tag=5, mat=2
        pit.file("gold", 'spot', ray(2.5 ether));
        pit.frob("gold",  40 ether, 100 ether);

        // tag=4, mat=2
        pit.file("gold", 'spot', ray(2 ether));  // now unsafe

        assertEq(ink("gold", address(this)),  40 ether);
        assertEq(art("gold", address(this)), 100 ether);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 960 ether);
        uint id = cat.bite("gold", bytes32(bytes20(address(this))));
        assertEq(ink("gold", address(this)), 0);
        assertEq(art("gold", address(this)), 0);
        assertEq(vow.sin(uint48(now)),      100 ether);
        assertEq(gem("gold", address(this)), 960 ether);

        cat.file("gold", "lump", uint(100 ether));
        uint auction = cat.flip(id, 100 ether);  // flip all the tab

        assertEq(vat.balanceOf(address(vow)),   0 ether);
        flip.tend(auction, 40 ether,   1 ether);
        assertEq(vat.balanceOf(address(vow)),   1 ether);
        flip.tend(auction, 40 ether, 100 ether);
        assertEq(vat.balanceOf(address(vow)), 100 ether);

        assertEq(vat.balanceOf(address(this)),       0 ether);
        assertEq(gem("gold", address(this)), 960 ether);
        vat.mint(address(this), 100 ether);  // magic up some dai for bidding
        flip.dent(auction, 38 ether,  100 ether);
        assertEq(vat.balanceOf(address(this)), 100 ether);
        assertEq(vat.balanceOf(address(vow)),  100 ether);
        assertEq(gem("gold", address(this)), 962 ether);
        assertEq(gem("gold", address(this)), 962 ether);

        assertEq(vow.sin(uint48(now)),       100 ether);
        assertEq(vat.balanceOf(address(vow)), 100 ether);
    }

    function test_floppy_bite() public {
        pit.file("gold", 'spot', ray(2.5 ether));
        pit.frob("gold",  40 ether, 100 ether);
        pit.file("gold", 'spot', ray(2 ether));  // now unsafe

        assertEq(vow.sin(uint48(now)),   0 ether);
        cat.bite("gold", bytes32(bytes20(address(this))));
        assertEq(vow.sin(uint48(now)), 100 ether);

        assertEq(vow.Sin(), 100 ether);
        vow.flog(uint48(now));
        assertEq(vow.Sin(),   0 ether);
        assertEq(vow.Woe(), 100 ether);
        assertEq(vow.Joy(),   0 ether);
        assertEq(vow.Ash(),   0 ether);

        vow.file("sump", uint(10 ether));
        uint f1 = vow.flop();
        assertEq(vow.Woe(),  90 ether);
        assertEq(vow.Joy(),   0 ether);
        assertEq(vow.Ash(),  10 ether);
        flop.dent(f1, 1000 ether, 10 ether);
        assertEq(vow.Woe(),  90 ether);
        assertEq(vow.Joy(),  10 ether);
        assertEq(vow.Ash(),  10 ether);

        assertEq(gov.balanceOf(address(this)),  100 ether);
        hevm.warp(4 hours);
        flop.deal(f1);
        assertEq(gov.balanceOf(address(this)), 1100 ether);
    }

    function test_flappy_bite() public {
        // get some surplus
        vat.mint(address(vow), 100 ether);
        assertEq(vat.balanceOf(address(vow)),  100 ether);
        assertEq(gov.balanceOf(address(this)), 100 ether);

        vow.file("bump", uint(100 ether));
        assertEq(vow.Awe(), 0 ether);
        uint id = vow.flap();

        assertEq(vat.balanceOf(address(this)),   0 ether);
        assertEq(gov.balanceOf(address(this)), 100 ether);
        flap.tend(id, 100 ether, 10 ether);
        hevm.warp(4 hours);
        flap.deal(id);
        assertEq(vat.balanceOf(address(this)),   100 ether);
        assertEq(gov.balanceOf(address(this)),    90 ether);
    }
}

contract FoldTest is DSTest {
    Vat vat;

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
    function tab(bytes32 ilk, bytes32 urn) internal view returns (uint) {
        (uint ink, uint art)  = vat.urns(ilk, urn); ink;
        (uint take, uint rate, uint Ink, uint Art) = vat.ilks(ilk); Art; Ink; take;
        return art * rate;
    }
    function jam(bytes32 ilk, bytes32 urn) internal view returns (uint) {
        (uint ink, uint art)  = vat.urns(ilk, urn); art;
        (uint take, uint rate, uint Ink, uint Art) = vat.ilks(ilk); Art; Ink; rate;
        return ink * take;
    }

    function setUp() public {
        vat = new Vat();
        vat.init("gold");
    }
    function test_fold() public {
        vat.tune("gold", "bob", "bob", "bob", 0, 1 ether);

        assertEq(tab("gold", "bob"), rad(1.00 ether));
        vat.fold("gold", "ali",  int(ray(0.05 ether)));
        assertEq(tab("gold", "bob"), rad(1.05 ether));
        assertEq(vat.dai("ali"),     rad(0.05 ether));
    }
    function test_toll_down() public {
        vat.slip("gold", "bob", int(rad(1 ether)));
        vat.slip("gold", "cat", int(rad(2 ether)));
        vat.tune("gold", "bob", "bob", "bob", 1 ether, 0);
        vat.tune("gold", "cat", "cat", "cat", 2 ether, 0);

        assertEq(jam("gold", "bob"),     rad(1.00 ether));
        assertEq(jam("gold", "cat"),     rad(2.00 ether));
        vat.toll("gold", "ali",     -int(ray(0.05 ether)));
        assertEq(jam("gold", "bob"),     rad(0.95 ether));
        assertEq(jam("gold", "cat"),     rad(1.90 ether));
        assertEq(vat.gem("gold", "ali"), rad(0.15 ether));
    }
    function test_toll_up() public {
        vat.slip("gold", "ali", int(rad(1 ether)));
        vat.slip("gold", "bob", int(rad(1 ether)));
        vat.slip("gold", "cat", int(rad(2 ether)));
        vat.tune("gold", "bob", "bob", "bob", 1 ether, 0);
        vat.tune("gold", "cat", "cat", "cat", 2 ether, 0);

        assertEq(jam("gold", "bob"),     rad(1.00 ether));
        assertEq(jam("gold", "cat"),     rad(2.00 ether));
        vat.toll("gold", "ali",      int(ray(0.05 ether)));
        assertEq(jam("gold", "bob"),     rad(1.05 ether));
        assertEq(jam("gold", "cat"),     rad(2.10 ether));
        assertEq(vat.gem("gold", "ali"), rad(0.85 ether));
    }
}
