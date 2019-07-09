pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";
import "ds-token/token.sol";

import {Vat} from '../vat.sol';
import {Cat} from '../cat.sol';
import {Vow} from '../vow.sol';
import {Jug} from '../jug.sol';
import {GemJoin, ETHJoin, DaiJoin} from '../join.sol';

import {Flipper} from './flip.t.sol';
import {Flopper} from './flop.t.sol';
import {Flapper} from './flap.t.sol';


contract Hevm {
    function warp(uint256) public;
}

contract TestVat is Vat {
    uint256 constant ONE = 10 ** 27;
    function mint(address usr, uint wad) public {
        dai[usr] += wad * ONE;
        debt += wad * ONE;
    }
    function balanceOf(address usr) public view returns (uint) {
        return dai[usr] / ONE;
    }
    function frob(bytes32 ilk, int dink, int dart) public {
        address usr = msg.sender;
        frob(ilk, usr, usr, usr, dink, dart);
    }
}

contract TestVow is Vow {
    constructor(address vat, address flapper, address flopper)
        public Vow(vat, flapper, flopper) {}
    // Total deficit
    function Awe() public view returns (uint) {
        return vat.sin(address(this));
    }
    // Total surplus
    function Joy() public view returns (uint) {
        return vat.dai(address(this));
    }
    // Unqueued, pre-auction debt
    function Woe() public view returns (uint) {
        return sub(sub(Awe(), Sin), Ash);
    }
}

contract Usr {
    Vat public vat;
    constructor(Vat vat_) public {
        vat = vat_;
    }
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
    function can_frob(bytes32 ilk, address u, address v, address w, int dink, int dart) public returns (bool) {
        string memory sig = "frob(bytes32,address,address,address,int256,int256)";
        bytes memory data = abi.encodeWithSignature(sig, ilk, u, v, w, dink, dart);

        bytes memory can_call = abi.encodeWithSignature("try_call(address,bytes)", vat, data);
        (bool ok, bytes memory success) = address(this).call(can_call);

        ok = abi.decode(success, (bool));
        if (ok) return true;
    }
    function can_fork(bytes32 ilk, address src, address dst, int dink, int dart) public returns (bool) {
        string memory sig = "fork(bytes32,address,address,int256,int256)";
        bytes memory data = abi.encodeWithSignature(sig, ilk, src, dst, dink, dart);

        bytes memory can_call = abi.encodeWithSignature("try_call(address,bytes)", vat, data);
        (bool ok, bytes memory success) = address(this).call(can_call);

        ok = abi.decode(success, (bool));
        if (ok) return true;
    }
    function frob(bytes32 ilk, address u, address v, address w, int dink, int dart) public {
        vat.frob(ilk, u, v, w, dink, dart);
    }
    function fork(bytes32 ilk, address src, address dst, int dink, int dart) public {
        vat.fork(ilk, src, dst, dink, dart);
    }
    function hope(address usr) public {
        vat.hope(usr);
    }
}


contract FrobTest is DSTest {
    TestVat vat;
    DSToken gold;
    Jug     jug;

    GemJoin gemA;

    function try_frob(bytes32 ilk, int ink, int art) public returns (bool ok) {
        string memory sig = "frob(bytes32,address,address,address,int256,int256)";
        address self = address(this);
        (ok,) = address(vat).call(abi.encodeWithSignature(sig, ilk, self, self, self, ink, art));
    }

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }

    function setUp() public {
        vat = new TestVat();

        gold = new DSToken("GEM");
        gold.mint(1000 ether);

        vat.init("gold");
        gemA = new GemJoin(address(vat), "gold", address(gold));

        vat.file("gold", "spot",    ray(1 ether));
        vat.file("gold", "line", rad(1000 ether));
        vat.file("Line",         rad(1000 ether));
        jug = new Jug(address(vat));
        jug.init("gold");
        vat.rely(address(jug));

        gold.approve(address(gemA));
        gold.approve(address(vat));

        vat.rely(address(vat));
        vat.rely(address(gemA));

        gemA.join(address(this), 1000 ether);
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

    function test_setup() public {
        assertEq(gold.balanceOf(address(gemA)), 1000 ether);
        assertEq(gem("gold",    address(this)), 1000 ether);
    }
    function test_join() public {
        address urn = address(this);
        gold.mint(500 ether);
        assertEq(gold.balanceOf(address(this)),    500 ether);
        assertEq(gold.balanceOf(address(gemA)),   1000 ether);
        gemA.join(urn,                             500 ether);
        assertEq(gold.balanceOf(address(this)),      0 ether);
        assertEq(gold.balanceOf(address(gemA)),   1500 ether);
        gemA.exit(urn,                             250 ether);
        assertEq(gold.balanceOf(address(this)),    250 ether);
        assertEq(gold.balanceOf(address(gemA)),   1250 ether);
    }
    function test_lock() public {
        assertEq(ink("gold", address(this)),    0 ether);
        assertEq(gem("gold", address(this)), 1000 ether);
        vat.frob("gold", 6 ether, 0);
        assertEq(ink("gold", address(this)),   6 ether);
        assertEq(gem("gold", address(this)), 994 ether);
        vat.frob("gold", -6 ether, 0);
        assertEq(ink("gold", address(this)),    0 ether);
        assertEq(gem("gold", address(this)), 1000 ether);
    }
    function test_calm() public {
        // calm means that the debt ceiling is not exceeded
        // it's ok to increase debt as long as you remain calm
        vat.file("gold", 'line', rad(10 ether));
        assertTrue( try_frob("gold", 10 ether, 9 ether));
        // only if under debt ceiling
        assertTrue(!try_frob("gold",  0 ether, 2 ether));
    }
    function test_cool() public {
        // cool means that the debt has decreased
        // it's ok to be over the debt ceiling as long as you're cool
        vat.file("gold", 'line', rad(10 ether));
        assertTrue(try_frob("gold", 10 ether,  8 ether));
        vat.file("gold", 'line', rad(5 ether));
        // can decrease debt when over ceiling
        assertTrue(try_frob("gold",  0 ether, -1 ether));
    }
    function test_safe() public {
        // safe means that the cdp is not risky
        // you can't frob a cdp into unsafe
        vat.frob("gold", 10 ether, 5 ether);                // safe draw
        assertTrue(!try_frob("gold", 0 ether, 6 ether));  // unsafe draw
    }
    function test_nice() public {
        // nice means that the collateral has increased or the debt has
        // decreased. remaining unsafe is ok as long as you're nice

        vat.frob("gold", 10 ether, 10 ether);
        vat.file("gold", 'spot', ray(0.5 ether));  // now unsafe

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
        vat.file("gold", 'spot', ray(0.4 ether));  // now unsafe
        // debt can increase if end state is safe
        assertTrue( this.try_frob("gold",  5 ether, 1 ether));
    }

    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
    function test_alt_callers() public {
        Usr ali = new Usr(vat);
        Usr bob = new Usr(vat);
        Usr che = new Usr(vat);

        address a = address(ali);
        address b = address(bob);
        address c = address(che);

        vat.slip("gold", a, int(rad(20 ether)));
        vat.slip("gold", b, int(rad(20 ether)));
        vat.slip("gold", c, int(rad(20 ether)));

        ali.frob("gold", a, a, a, 10 ether, 5 ether);

        // anyone can lock
        assertTrue( ali.can_frob("gold", a, a, a,  1 ether,  0 ether));
        assertTrue( bob.can_frob("gold", a, b, b,  1 ether,  0 ether));
        assertTrue( che.can_frob("gold", a, c, c,  1 ether,  0 ether));
        // but only with their own gems
        assertTrue(!ali.can_frob("gold", a, b, a,  1 ether,  0 ether));
        assertTrue(!bob.can_frob("gold", a, c, b,  1 ether,  0 ether));
        assertTrue(!che.can_frob("gold", a, a, c,  1 ether,  0 ether));

        // only the lad can free
        assertTrue( ali.can_frob("gold", a, a, a, -1 ether,  0 ether));
        assertTrue(!bob.can_frob("gold", a, b, b, -1 ether,  0 ether));
        assertTrue(!che.can_frob("gold", a, c, c, -1 ether,  0 ether));
        // the lad can free to anywhere
        assertTrue( ali.can_frob("gold", a, b, a, -1 ether,  0 ether));
        assertTrue( ali.can_frob("gold", a, c, a, -1 ether,  0 ether));

        // only the lad can draw
        assertTrue( ali.can_frob("gold", a, a, a,  0 ether,  1 ether));
        assertTrue(!bob.can_frob("gold", a, b, b,  0 ether,  1 ether));
        assertTrue(!che.can_frob("gold", a, c, c,  0 ether,  1 ether));
        // the lad can draw to anywhere
        assertTrue( ali.can_frob("gold", a, a, b,  0 ether,  1 ether));
        assertTrue( ali.can_frob("gold", a, a, c,  0 ether,  1 ether));

        vat.mint(address(bob), 1 ether);
        vat.mint(address(che), 1 ether);

        // anyone can wipe
        assertTrue( ali.can_frob("gold", a, a, a,  0 ether, -1 ether));
        assertTrue( bob.can_frob("gold", a, b, b,  0 ether, -1 ether));
        assertTrue( che.can_frob("gold", a, c, c,  0 ether, -1 ether));
        // but only with their own dai
        assertTrue(!ali.can_frob("gold", a, a, b,  0 ether, -1 ether));
        assertTrue(!bob.can_frob("gold", a, b, c,  0 ether, -1 ether));
        assertTrue(!che.can_frob("gold", a, c, a,  0 ether, -1 ether));
    }

    function test_hope() public {
        Usr ali = new Usr(vat);
        Usr bob = new Usr(vat);
        Usr che = new Usr(vat);

        address a = address(ali);
        address b = address(bob);
        address c = address(che);

        vat.slip("gold", a, int(rad(20 ether)));
        vat.slip("gold", b, int(rad(20 ether)));
        vat.slip("gold", c, int(rad(20 ether)));

        ali.frob("gold", a, a, a, 10 ether, 5 ether);

        // only owner can do risky actions
        assertTrue( ali.can_frob("gold", a, a, a,  0 ether,  1 ether));
        assertTrue(!bob.can_frob("gold", a, b, b,  0 ether,  1 ether));
        assertTrue(!che.can_frob("gold", a, c, c,  0 ether,  1 ether));

        ali.hope(address(bob));

        // unless they hope another user
        assertTrue( ali.can_frob("gold", a, a, a,  0 ether,  1 ether));
        assertTrue( bob.can_frob("gold", a, b, b,  0 ether,  1 ether));
        assertTrue(!che.can_frob("gold", a, c, c,  0 ether,  1 ether));
    }

    function test_dust() public {
        assertTrue( try_frob("gold", 9 ether,  1 ether));
        vat.file("gold", "dust", rad(5 ether));
        assertTrue(!try_frob("gold", 5 ether,  2 ether));
        assertTrue( try_frob("gold", 0 ether,  5 ether));
        assertTrue(!try_frob("gold", 0 ether, -5 ether));
        assertTrue( try_frob("gold", 0 ether, -6 ether));
    }
}

contract JoinTest is DSTest {
    TestVat vat;
    ETHJoin ethA;
    DaiJoin daiA;
    DSToken dai;
    address me;

    function setUp() public {
        vat = new TestVat();
        vat.init("eth");

        ethA = new ETHJoin(address(vat), "eth");
        vat.rely(address(ethA));

        dai  = new DSToken("Dai");
        daiA = new DaiJoin(address(vat), address(dai));
        vat.rely(address(daiA));
        dai.setOwner(address(daiA));

        me = address(this);
    }
    function () external payable {}
    function test_eth_join() public {
        ethA.join.value(10 ether)(address(this));
        assertEq(vat.gem("eth", me), 10 ether);
    }
    function test_eth_exit() public {
        address payable urn = address(this);
        ethA.join.value(50 ether)(urn);
        ethA.exit(urn, 10 ether);
        assertEq(vat.gem("eth", me), 40 ether);
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
    function test_dai_exit() public {
        address urn = address(this);
        vat.mint(address(this), 100 ether);
        vat.hope(address(daiA));
        daiA.exit(urn, 60 ether);
        assertEq(dai.balanceOf(address(this)), 60 ether);
        assertEq(vat.dai(me),              rad(40 ether));
    }
    function test_dai_exit_join() public {
        address urn = address(this);
        vat.mint(address(this), 100 ether);
        vat.hope(address(daiA));
        daiA.exit(urn, 60 ether);
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

contract FlipLike {
    struct Bid {
        uint256 bid;
        uint256 lot;
        address guy;  // high bidder
        uint48  tic;  // expiry time
        uint48  end;
        address urn;
        address gal;
        uint256 tab;
    }
    function bids(uint) public view returns (Bid memory);
}

contract BiteTest is DSTest {
    Hevm hevm;

    TestVat vat;
    TestVow vow;
    Cat     cat;
    DSToken gold;
    Jug     jug;

    GemJoin gemA;

    Flipper flip;
    Flopper flop;
    Flapper flap;

    DSToken gov;

    function try_frob(bytes32 ilk, int ink, int art) public returns (bool ok) {
        string memory sig = "frob(bytes32,address,address,address,int256,int256)";
        address self = address(this);
        (ok,) = address(vat).call(abi.encodeWithSignature(sig, ilk, self, self, self, ink, art));
    }

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
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
        hevm.warp(604411200);

        gov = new DSToken('GOV');
        gov.mint(100 ether);

        vat = new TestVat();
        vat = vat;

        flap = new Flapper(address(vat), address(gov));
        flop = new Flopper(address(vat), address(gov));

        vow = new TestVow(address(vat), address(flap), address(flop));
        flop.rely(address(vow));

        jug = new Jug(address(vat));
        jug.init("gold");
        jug.file("vow", address(vow));
        vat.rely(address(jug));

        cat = new Cat(address(vat));
        cat.file("vow", address(vow));
        vat.rely(address(cat));
        vow.rely(address(cat));

        gold = new DSToken("GEM");
        gold.mint(1000 ether);

        vat.init("gold");
        gemA = new GemJoin(address(vat), "gold", address(gold));
        vat.rely(address(gemA));
        gold.approve(address(gemA));
        gemA.join(address(this), 1000 ether);

        vat.file("gold", "spot", ray(1 ether));
        vat.file("gold", "line", rad(1000 ether));
        vat.file("Line",         rad(1000 ether));
        flip = new Flipper(address(vat), "gold");
        cat.file("gold", "flip", address(flip));
        cat.file("gold", "chop", ray(1 ether));

        vat.rely(address(flip));
        vat.rely(address(flap));
        vat.rely(address(flop));

        vat.hope(address(flip));
        vat.hope(address(flop));
        gold.approve(address(vat));
        gov.approve(address(flap));
    }

    function test_bite_under_lump() public {
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold",  40 ether, 100 ether);
        // tag=4, mat=2
        vat.file("gold", 'spot', ray(2 ether));  // now unsafe

        cat.file("gold", "lump", 50 ether);
        cat.file("gold", "chop", ray(1.1 ether));

        uint auction = cat.bite("gold", address(this));
        // the full CDP is liquidated
        assertEq(ink("gold", address(this)), 0);
        assertEq(art("gold", address(this)), 0);
        // all debt goes to the vow
        assertEq(vow.Awe(), rad(100 ether));
        // auction is for all collateral
        FlipLike.Bid memory bid = FlipLike(address(flip)).bids(auction);
        assertEq(bid.lot,        40 ether);
        assertEq(bid.tab,   rad(110 ether));
    }
    function test_bite_over_lump() public {
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold",  40 ether, 100 ether);
        // tag=4, mat=2
        vat.file("gold", 'spot', ray(2 ether));  // now unsafe

        cat.file("gold", "chop", ray(1.1 ether));
        cat.file("gold", "lump", 30 ether);

        uint auction = cat.bite("gold", address(this));
        // the CDP is partially liquidated
        assertEq(ink("gold", address(this)), 10 ether);
        assertEq(art("gold", address(this)), 25 ether);
        // a fraction of the debt goes to the vow
        assertEq(vow.Awe(), rad(75 ether));
        // auction is for a fraction of the collateral
        FlipLike.Bid memory bid = FlipLike(address(flip)).bids(auction);
        assertEq(bid.lot,       30 ether);
        assertEq(bid.tab,   rad(82.5 ether));
    }

    function test_happy_bite() public {
        // spot = tag / (par . mat)
        // tag=5, mat=2
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold",  40 ether, 100 ether);

        // tag=4, mat=2
        vat.file("gold", 'spot', ray(2 ether));  // now unsafe

        assertEq(ink("gold", address(this)),  40 ether);
        assertEq(art("gold", address(this)), 100 ether);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 960 ether);

        cat.file("gold", "lump", 100 ether);  // => bite everything
        uint auction = cat.bite("gold", address(this));
        assertEq(ink("gold", address(this)), 0);
        assertEq(art("gold", address(this)), 0);
        assertEq(vow.sin(now),   rad(100 ether));
        assertEq(gem("gold", address(this)), 960 ether);

        assertEq(vat.balanceOf(address(vow)),    0 ether);
        flip.tend(auction, 40 ether,   rad(1 ether));
        flip.tend(auction, 40 ether, rad(100 ether));

        assertEq(vat.balanceOf(address(this)),   0 ether);
        assertEq(gem("gold", address(this)),   960 ether);
        vat.mint(address(this), 100 ether);  // magic up some dai for bidding
        flip.dent(auction, 38 ether,  rad(100 ether));
        assertEq(vat.balanceOf(address(this)), 100 ether);
        assertEq(gem("gold", address(this)),   962 ether);
        assertEq(gem("gold", address(this)),   962 ether);
        assertEq(vow.sin(now),     rad(100 ether));

        hevm.warp(now + 4 hours);
        flip.deal(auction);
        assertEq(vat.balanceOf(address(vow)),  100 ether);
    }

    function test_floppy_bite() public {
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold",  40 ether, 100 ether);
        vat.file("gold", 'spot', ray(2 ether));  // now unsafe

        cat.file("gold", "lump", 100 ether);  // => bite everything
        assertEq(vow.sin(now), rad(  0 ether));
        cat.bite("gold", address(this));
        assertEq(vow.sin(now), rad(100 ether));

        assertEq(vow.Sin(), rad(100 ether));
        vow.flog(now);
        assertEq(vow.Sin(), rad(  0 ether));
        assertEq(vow.Woe(), rad(100 ether));
        assertEq(vow.Joy(), rad(  0 ether));
        assertEq(vow.Ash(), rad(  0 ether));

        vow.file("sump", rad(10 ether));
        uint f1 = vow.flop();
        assertEq(vow.Woe(),  rad(90 ether));
        assertEq(vow.Joy(),  rad( 0 ether));
        assertEq(vow.Ash(),  rad(10 ether));
        flop.dent(f1, 1000 ether, rad(10 ether));
        assertEq(vow.Woe(),  rad(90 ether));
        assertEq(vow.Joy(),  rad(10 ether));
        assertEq(vow.Ash(),  rad(10 ether));

        assertEq(gov.balanceOf(address(this)),  100 ether);
        hevm.warp(now + 4 hours);
        gov.setOwner(address(flop));
        flop.deal(f1);
        assertEq(gov.balanceOf(address(this)), 1100 ether);
    }

    function test_flappy_bite() public {
        // get some surplus
        vat.mint(address(vow), 100 ether);
        assertEq(vat.balanceOf(address(vow)),  100 ether);
        assertEq(gov.balanceOf(address(this)), 100 ether);

        vow.file("bump", rad(100 ether));
        assertEq(vow.Awe(), 0 ether);
        uint id = vow.flap();

        assertEq(vat.balanceOf(address(this)),   0 ether);
        assertEq(gov.balanceOf(address(this)), 100 ether);
        flap.tend(id, rad(100 ether), 10 ether);
        hevm.warp(now + 4 hours);
        gov.setOwner(address(flap));
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
    function tab(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, urn); ink_;
        (uint Art_, uint rate, uint spot, uint line, uint dust) = vat.ilks(ilk);
        Art_; spot; line; dust;
        return art_ * rate;
    }
    function jam(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, urn); art_;
        return ink_;
    }

    function setUp() public {
        vat = new Vat();
        vat.init("gold");
        vat.file("Line", rad(100 ether));
        vat.file("gold", "line", rad(100 ether));
    }
    function draw(bytes32 ilk, uint dai) internal {
        vat.file("Line", rad(dai));
        vat.file(ilk, "line", rad(dai));
        vat.file(ilk, "spot", 10 ** 27 * 10000 ether);
        address self = address(this);
        vat.slip(ilk, self,  10 ** 27 * 1 ether);
        vat.frob(ilk, self, self, self, int(1 ether), int(dai));
    }
    function test_fold() public {
        address self = address(this);
        address ali  = address(bytes20("ali"));
        draw("gold", 1 ether);

        assertEq(tab("gold", self), rad(1.00 ether));
        vat.fold("gold", ali,   int(ray(0.05 ether)));
        assertEq(tab("gold", self), rad(1.05 ether));
        assertEq(vat.dai(ali),      rad(0.05 ether));
    }
}
