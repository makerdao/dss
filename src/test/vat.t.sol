pragma solidity >=0.5.12;

import "ds-test/test.sol";
import "ds-token/token.sol";

import {Vat} from '../vat.sol';
import {Cat} from '../cat.sol';
import {Vow} from '../vow.sol';
import {Jug} from '../jug.sol';
import {GemJoin, DaiJoin} from '../join.sol';

import {Flipper} from './flip.t.sol';
import {Flopper} from './flop.t.sol';
import {Flapper} from './flap.t.sol';


interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

contract TestVat is Vat {
    uint256 constant ONE = 10 ** 27;
    function mint(address usr, uint wad) public {
        dai[usr] += wad * ONE;
        debt += wad * ONE;
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
            let ok := call(gas(), addr, 0, add(_data, 0x20), mload(_data), 0, 0)
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
    address me;

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

        me = address(this);
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
        vat.frob("gold", me, me, me, 6 ether, 0);
        assertEq(ink("gold", address(this)),   6 ether);
        assertEq(gem("gold", address(this)), 994 ether);
        vat.frob("gold", me, me, me, -6 ether, 0);
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
        vat.frob("gold", me, me, me, 10 ether, 5 ether);                // safe draw
        assertTrue(!try_frob("gold", 0 ether, 6 ether));  // unsafe draw
    }
    function test_nice() public {
        // nice means that the collateral has increased or the debt has
        // decreased. remaining unsafe is ok as long as you're nice

        vat.frob("gold", me, me, me, 10 ether, 10 ether);
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
    DSToken gem;
    GemJoin gemA;
    DaiJoin daiA;
    DSToken dai;
    address me;

    function setUp() public {
        vat = new TestVat();
        vat.init("eth");

        gem  = new DSToken("Gem");
        gemA = new GemJoin(address(vat), "gem", address(gem));
        vat.rely(address(gemA));

        dai  = new DSToken("Dai");
        daiA = new DaiJoin(address(vat), address(dai));
        vat.rely(address(daiA));
        dai.setOwner(address(daiA));

        me = address(this);
    }
    function try_cage(address a) public payable returns (bool ok) {
        string memory sig = "cage()";
        (ok,) = a.call(abi.encodeWithSignature(sig));
    }
    function try_join_gem(address usr, uint wad) public returns (bool ok) {
        string memory sig = "join(address,uint256)";
        (ok,) = address(gemA).call(abi.encodeWithSignature(sig, usr, wad));
    }
    function try_exit_dai(address usr, uint wad) public returns (bool ok) {
        string memory sig = "exit(address,uint256)";
        (ok,) = address(daiA).call(abi.encodeWithSignature(sig, usr, wad));
    }
    function test_gem_join() public {
        gem.mint(20 ether);
        gem.approve(address(gemA), 20 ether);
        assertTrue( try_join_gem(address(this), 10 ether));
        assertEq(vat.gem("gem", me), 10 ether);
        assertTrue( try_cage(address(gemA)));
        assertTrue(!try_join_gem(address(this), 10 ether));
        assertEq(vat.gem("gem", me), 10 ether);
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
    function test_dai_exit() public {
        address urn = address(this);
        vat.mint(address(this), 100 ether);
        vat.hope(address(daiA));
        assertTrue( try_exit_dai(urn, 40 ether));
        assertEq(dai.balanceOf(address(this)), 40 ether);
        assertEq(vat.dai(me),              rad(60 ether));
        assertTrue( try_cage(address(daiA)));
        assertTrue(!try_exit_dai(urn, 40 ether));
        assertEq(dai.balanceOf(address(this)), 40 ether);
        assertEq(vat.dai(me),              rad(60 ether));
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
    function test_cage_no_access() public {
        gemA.deny(address(this));
        assertTrue(!try_cage(address(gemA)));
        daiA.deny(address(this));
        assertTrue(!try_cage(address(daiA)));
    }
}

interface FlipLike {
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
    function bids(uint) external view returns (
        uint256 bid,
        uint256 lot,
        address guy,
        uint48  tic,
        uint48  end,
        address usr,
        address gal,
        uint256 tab
    );
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

    address me;

    uint256 constant MLN = 10 ** 6;
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant RAD = 10 ** 45;

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
        flap.rely(address(vow));
        flop.rely(address(vow));

        jug = new Jug(address(vat));
        jug.init("gold");
        jug.file("vow", address(vow));
        vat.rely(address(jug));

        cat = new Cat(address(vat));
        cat.file("vow", address(vow));
        cat.file("box", rad((10 ether) * MLN));
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
        flip = new Flipper(address(vat), address(cat), "gold");
        flip.rely(address(cat));
        cat.rely(address(flip));
        cat.file("gold", "flip", address(flip));
        cat.file("gold", "chop", 1 ether);

        vat.rely(address(flip));
        vat.rely(address(flap));
        vat.rely(address(flop));

        vat.hope(address(flip));
        vat.hope(address(flop));
        gold.approve(address(vat));
        gov.approve(address(flap));

        me = address(this);
    }

    function test_set_dunk_multiple_ilks() public {
        cat.file("gold",   "dunk", rad(111111 ether));
        (,, uint256 goldDunk) = cat.ilks("gold");
        assertEq(goldDunk, rad(111111 ether));
        cat.file("silver", "dunk", rad(222222 ether));
        (,, uint256 silverDunk) = cat.ilks("silver");
        assertEq(silverDunk, rad(222222 ether));
    }
    function test_cat_set_box() public {
        assertEq(cat.box(), rad((10 ether) * MLN));
        cat.file("box", rad((20 ether) * MLN));
        assertEq(cat.box(), rad((20 ether) * MLN));
    }
    function test_bite_under_dunk() public {
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 40 ether, 100 ether);
        // tag=4, mat=2
        vat.file("gold", 'spot', ray(2 ether));  // now unsafe

        cat.file("gold", "dunk", rad(111 ether));
        cat.file("gold", "chop", 1.1 ether);

        uint auction = cat.bite("gold", address(this));
        // the full CDP is liquidated
        assertEq(ink("gold", address(this)), 0);
        assertEq(art("gold", address(this)), 0);
        // all debt goes to the vow
        assertEq(vow.Awe(), rad(100 ether));
        // auction is for all collateral
        (, uint lot,,,,,, uint tab) = flip.bids(auction);
        assertEq(lot,        40 ether);
        assertEq(tab,   rad(110 ether));
    }
    function test_bite_over_dunk() public {
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 40 ether, 100 ether);
        // tag=4, mat=2
        vat.file("gold", 'spot', ray(2 ether));  // now unsafe

        cat.file("gold", "chop", 1.1 ether);
        cat.file("gold", "dunk", rad(82.5 ether));

        uint auction = cat.bite("gold", address(this));
        // the CDP is partially liquidated
        assertEq(ink("gold", address(this)), 10 ether);
        assertEq(art("gold", address(this)), 25 ether);
        // a fraction of the debt goes to the vow
        assertEq(vow.Awe(), rad(75 ether));
        // auction is for a fraction of the collateral
        (, uint lot,,,,,, uint tab) = FlipLike(address(flip)).bids(auction);
        assertEq(lot,       30 ether);
        assertEq(tab,   rad(82.5 ether));
    }

    function test_happy_bite() public {
        // spot = tag / (par . mat)
        // tag=5, mat=2
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 40 ether, 100 ether);

        // tag=4, mat=2
        vat.file("gold", 'spot', ray(2 ether));  // now unsafe
        cat.file("gold", "chop", 1.1 ether);

        assertEq(ink("gold", address(this)),  40 ether);
        assertEq(art("gold", address(this)), 100 ether);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 960 ether);

        cat.file("gold", "dunk", rad(200 ether));  // => bite everything
        assertEq(cat.litter(), 0);
        uint auction = cat.bite("gold", address(this));
        assertEq(cat.litter(), rad(110 ether));
        assertEq(ink("gold", address(this)), 0);
        assertEq(art("gold", address(this)), 0);
        assertEq(vow.sin(now),   rad(100 ether));
        assertEq(gem("gold", address(this)), 960 ether);

        assertEq(vat.dai(address(vow)), rad(0 ether));
        vat.mint(address(this), 100 ether);  // magic up some dai for bidding
        flip.tend(auction, 40 ether,   rad(1 ether));
        flip.tend(auction, 40 ether, rad(110 ether));

        assertEq(vat.dai(address(this)),  rad(90 ether));
        assertEq(gem("gold", address(this)), 960 ether);
        flip.dent(auction, 38 ether,  rad(110 ether));
        assertEq(vat.dai(address(this)),  rad(90 ether));
        assertEq(gem("gold", address(this)), 962 ether);
        assertEq(vow.sin(now),     rad(100 ether));

        hevm.warp(now + 4 hours);
        assertEq(cat.litter(), rad(110 ether));
        flip.deal(auction);
        assertEq(cat.litter(), 0);
        assertEq(vat.dai(address(vow)),  rad(110 ether));
    }

    // tests a partial lot liquidation because it would fill the literbox
    function test_partial_litterbox() public {
        // spot = tag / (par . mat)
        // tag=5, mat=2
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 100 ether, 150 ether);

        // tag=4, mat=2
        vat.file("gold", 'spot', ray(1 ether));  // now unsafe

        assertEq(ink("gold", address(this)), 100 ether);
        assertEq(art("gold", address(this)), 150 ether);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 900 ether);

        cat.file("box", rad(75 ether));
        cat.file("gold", "dunk", rad(100 ether));
        assertEq(cat.box(), rad(75 ether));
        assertEq(cat.litter(), 0);
        uint auction = cat.bite("gold", address(this));

        assertEq(ink("gold", address(this)), 50 ether);
        assertEq(art("gold", address(this)), 75 ether);
        assertEq(vow.sin(now), rad(75 ether));
        assertEq(gem("gold", address(this)), 900 ether);

        assertEq(vat.dai(address(this)),  rad(150 ether));
        assertEq(vat.dai(address(vow)),     rad(0 ether));
        flip.tend(auction, 50 ether, rad(1 ether));
        assertEq(cat.litter(), rad(75 ether));
        assertEq(vat.dai(address(this)), rad(149 ether));
        flip.tend(auction, 50 ether, rad(75 ether));
        assertEq(vat.dai(address(this)), rad(75 ether));

        assertEq(gem("gold", address(this)),  900 ether);
        flip.dent(auction, 25 ether, rad(75 ether));
        assertEq(cat.litter(), rad(75 ether));
        assertEq(vat.dai(address(this)), rad(75 ether));
        assertEq(gem("gold", address(this)), 925 ether);
        assertEq(vow.sin(now), rad(75 ether));

        hevm.warp(now + 4 hours);
        flip.deal(auction);
        assertEq(cat.litter(), 0);
        assertEq(gem("gold", address(this)),  950 ether);
        assertEq(vat.dai(address(this)),   rad(75 ether));
        assertEq(vat.dai(address(vow)),    rad(75 ether));
    }

    // tests a partial lot liquidation because it would fill the literbox
    function test_partial_litterbox_realistic_values() public {
        // spot = tag / (par . mat)
        // tag=5, mat=2
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 100 ether, 150 ether);

        // tag=4, mat=2
        vat.file("gold", 'spot', ray(1 ether));  // now unsafe
        cat.file("gold", "chop", 1.13 ether);

        assertEq(ink("gold", address(this)), 100 ether);
        assertEq(art("gold", address(this)), 150 ether);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 900 ether);

        // To check this yourself, use the following rate calculation (example 8%):
        //
        // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
        uint256 EIGHT_PCT = 1000000002440418608258400030;
        jug.file("gold", "duty", EIGHT_PCT);
        hevm.warp(now + 10 days);
        jug.drip("gold");
        (, uint rate,,,) = vat.ilks("gold");

        uint vowBalance = vat.dai(address(vow)); // Balance updates after vat.fold is called from jug

        cat.file("box", rad(75 ether));
        cat.file("gold", "dunk", rad(100 ether));
        assertEq(cat.box(), rad(75 ether));
        assertEq(cat.litter(), 0);
        uint auction = cat.bite("gold", address(this));
        (,,,,,,,uint tab) = flip.bids(auction);

        assertTrue(cat.box() - cat.litter() < ray(1 ether)); // Rounding error to fill box
        assertEq(cat.litter(), tab);                         // tab = 74.9999... RAD

        uint256 dart = rad(75 ether) * WAD / rate / 1.13 ether; // room / rate / chop
        uint256 dink = 100 ether * dart / 150 ether;

        assertEq(ink("gold", address(this)), 100 ether - dink); // Taken in vat.grab
        assertEq(art("gold", address(this)), 150 ether - dart); // Taken in vat.grab
        assertEq(vow.sin(now), dart * rate);               
        assertEq(gem("gold", address(this)), 900 ether);

        assertEq(vat.dai(address(this)), rad(150 ether));
        assertEq(vat.dai(address(vow)),  vowBalance);
        flip.tend(auction, dink, rad( 1 ether));
        assertEq(cat.litter(), tab);
        assertEq(vat.dai(address(this)), rad(149 ether));
        flip.tend(auction, dink, tab);
        assertEq(vat.dai(address(this)), rad(150 ether) - tab);

        assertEq(gem("gold", address(this)),  900 ether);
        flip.dent(auction, 25 ether, tab);
        assertEq(cat.litter(), tab);
        assertEq(vat.dai(address(this)), rad(150 ether) - tab);
        assertEq(gem("gold", address(this)), 900 ether + (dink - 25 ether));
        assertEq(vow.sin(now), dart * rate);

        hevm.warp(now + 4 hours);
        flip.deal(auction);
        assertEq(cat.litter(), 0);
        assertEq(gem("gold", address(this)),  900 ether + dink); // (flux another 25 wad into gem)
        assertEq(vat.dai(address(this)), rad(150 ether) - tab);  
        assertEq(vat.dai(address(vow)),  vowBalance + tab);
    }

    // tests a partial lot liquidation that fill litterbox
    function testFail_fill_litterbox() public {
        // spot = tag / (par . mat)
        // tag=5, mat=2
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 100 ether, 150 ether);

        // tag=4, mat=2
        vat.file("gold", 'spot', ray(1 ether));  // now unsafe

        assertEq(ink("gold", address(this)), 100 ether);
        assertEq(art("gold", address(this)), 150 ether);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 900 ether);

        cat.file("box", rad(75 ether));
        cat.file("gold", "dunk", rad(100 ether));
        assertEq(cat.box(), rad(75 ether));
        assertEq(cat.litter(), 0);
        cat.bite("gold", address(this));
        assertEq(cat.litter(), rad(75 ether));
        assertEq(ink("gold", address(this)), 50 ether);
        assertEq(art("gold", address(this)), 75 ether);
        assertEq(vow.sin(now), rad(75 ether));
        assertEq(gem("gold", address(this)), 900 ether);

        // this bite puts us over the litterbox
        cat.bite("gold", address(this));
    }

    // Tests for multiple bites where second bite has a dusty amount for room
    function testFail_dusty_litterbox() public {
        // spot = tag / (par . mat)
        // tag=5, mat=2
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 50 ether, 80 ether + 1);

        // tag=4, mat=2
        vat.file("gold", 'spot', ray(1 ether));  // now unsafe

        assertEq(ink("gold", address(this)), 50 ether);
        assertEq(art("gold", address(this)), 80 ether + 1);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 950 ether);

        cat.file("box",  rad(100 ether));
        vat.file("gold", "dust", rad(20 ether));
        cat.file("gold", "dunk", rad(100 ether));

        assertEq(cat.box(), rad(100 ether));
        assertEq(cat.litter(), 0);
        cat.bite("gold", address(this));
        assertEq(cat.litter(), rad(80 ether + 1)); // room is now dusty
        assertEq(ink("gold", address(this)), 0 ether);
        assertEq(art("gold", address(this)), 0 ether);
        assertEq(vow.sin(now), rad(80 ether + 1));
        assertEq(gem("gold", address(this)), 950 ether);

        // spot = tag / (par . mat)
        // tag=5, mat=2
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 100 ether, 150 ether);

        // tag=4, mat=2
        vat.file("gold", 'spot', ray(1 ether));  // now unsafe

        assertEq(ink("gold", address(this)), 100 ether);
        assertEq(art("gold", address(this)), 150 ether);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 850 ether);

        assertTrue(cat.box() - cat.litter() < rad(20 ether)); // room < dust

        // // this bite puts us over the litterbox
        cat.bite("gold", address(this));
    }

    // test liquidations that fill the litterbox deal them then liquidate more
    function test_partial_litterbox_multiple_bites() public {
        // spot = tag / (par . mat)
        // tag=5, mat=2
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 100 ether, 150 ether);

        // tag=4, mat=2
        vat.file("gold", 'spot', ray(1 ether));  // now unsafe

        assertEq(ink("gold", address(this)), 100 ether);
        assertEq(art("gold", address(this)), 150 ether);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 900 ether);

        cat.file("box", rad(75 ether));
        cat.file("gold", "dunk", rad(100 ether));
        assertEq(cat.box(), rad(75 ether));
        assertEq(cat.litter(), 0);
        uint auction = cat.bite("gold", address(this));
        assertEq(cat.litter(), rad(75 ether));
        assertEq(ink("gold", address(this)), 50 ether);
        assertEq(art("gold", address(this)), 75 ether);
        assertEq(vow.sin(now), rad(75 ether));
        assertEq(gem("gold", address(this)), 900 ether);

        assertEq(vat.dai(address(this)), rad(150 ether));
        assertEq(vat.dai(address(vow)),    rad(0 ether));
        flip.tend(auction, 50 ether, rad( 1 ether));
        assertEq(cat.litter(), rad(75 ether));
        assertEq(vat.dai(address(this)), rad(149 ether));
        flip.tend(auction, 50 ether, rad(75 ether));
        assertEq(vat.dai(address(this)), rad(75 ether));

        assertEq(gem("gold", address(this)),  900 ether);
        flip.dent(auction, 25 ether, rad(75 ether));
        assertEq(cat.litter(), rad(75 ether));
        assertEq(vat.dai(address(this)), rad(75 ether));
        assertEq(gem("gold", address(this)), 925 ether);
        assertEq(vow.sin(now), rad(75 ether));

        // From testFail_fill_litterbox() we know another bite() here would
        // fail with a 'Cat/liquidation-limit-hit' revert.  So let's deal()
        // and then bite() again once there is more capacity in the litterbox

        hevm.warp(now + 4 hours);
        flip.deal(auction);
        assertEq(cat.litter(), 0);
        assertEq(gem("gold", address(this)), 950 ether);
        assertEq(vat.dai(address(this)),  rad(75 ether));
        assertEq(vat.dai(address(vow)),   rad(75 ether));

        // now bite more
        auction = cat.bite("gold", address(this));
        assertEq(cat.litter(), rad(75 ether));
        assertEq(ink("gold", address(this)), 0);
        assertEq(art("gold", address(this)), 0);
        assertEq(vow.sin(now), rad(75 ether));
        assertEq(gem("gold", address(this)), 950 ether);

        assertEq(vat.dai(address(this)), rad(75 ether));
        assertEq(vat.dai(address(vow)),  rad(75 ether));
        flip.tend(auction, 50 ether, rad( 1 ether));
        assertEq(cat.litter(), rad(75 ether));
        assertEq(vat.dai(address(this)), rad(74 ether));
        flip.tend(auction, 50 ether, rad(75 ether));
        assertEq(vat.dai(address(this)), 0);

        assertEq(gem("gold", address(this)),  950 ether);
        flip.dent(auction, 25 ether, rad(75 ether));
        assertEq(cat.litter(), rad(75 ether));
        assertEq(vat.dai(address(this)), 0);
        assertEq(gem("gold", address(this)), 975 ether);
        assertEq(vow.sin(now), rad(75 ether));

        hevm.warp(now + 4 hours);
        flip.deal(auction);
        assertEq(cat.litter(), 0);
        assertEq(gem("gold", address(this)),  1000 ether);
        assertEq(vat.dai(address(this)), 0);
        assertEq(vat.dai(address(vow)),  rad(150 ether));
    }

    function testFail_null_auctions_dart_realistic_values() public {
        vat.file("gold", "dust", rad(100 ether));
        vat.file("gold", "spot", ray(2.5 ether));
        vat.file("gold", "line", rad(2000 ether));
        vat.file("Line",         rad(2000 ether));
        vat.fold("gold", address(vow), int256(ray(0.25 ether)));
        vat.frob("gold", me, me, me, 800 ether, 2000 ether);

        vat.file("gold", 'spot', ray(1 ether));  // now unsafe

        // slightly contrived value to leave tiny amount of room post-liquidation
        cat.file("box", rad(1130 ether) + 1);
        cat.file("gold", "dunk", rad(1130 ether));
        cat.file("gold", "chop", 1.13 ether);
        cat.bite("gold", me);
        assertEq(cat.litter(), rad(1130 ether));
        uint room = cat.box() - cat.litter();
        assertEq(room, 1);
        (, uint256 rate,,,) = vat.ilks("gold");
        (, uint256 chop,) = cat.ilks("gold");
        assertEq(room * (1 ether) / rate / chop, 0);

        // Biting any non-zero amount of debt would overflow the box,
        // so this should revert and not create a null auction.
        // In this case we're protected by the dustiness check on room.
        cat.bite("gold", me);
    }

    function testFail_null_auctions_dart_artificial_values() public {
        // artificially tiny dust value, e.g. due to misconfiguration
        vat.file("dust", "dust", 1);
        vat.file("gold", "spot", ray(2.5 ether));
        vat.frob("gold", me, me, me, 100 ether, 200 ether);

        vat.file("gold", 'spot', ray(1 ether));  // now unsafe

        // contrived value to leave tiny amount of room post-liquidation
        cat.file("box", rad(113 ether) + 2);
        cat.file("gold", "dunk", rad(113  ether));
        cat.file("gold", "chop", 1.13 ether);
        cat.bite("gold", me);
        assertEq(cat.litter(), rad(113 ether));
        uint room = cat.box() - cat.litter();
        assertEq(room, 2);
        (, uint256 rate,,,) = vat.ilks("gold");
        (, uint256 chop,) = cat.ilks("gold");
        assertEq(room * (1 ether) / rate / chop, 0);

        // Biting any non-zero amount of debt would overflow the box,
        // so this should revert and not create a null auction.
        // The dustiness check on room doesn't apply here, so additional
        // logic is needed to make this test pass.
        cat.bite("gold", me);
    }

    function testFail_null_auctions_dink_artificial_values() public {
        // we're going to make 1 wei of ink worth 250
        vat.file("gold", "spot", ray(250 ether) * 1 ether);
        cat.file("gold", "dunk", rad(50 ether));
        vat.frob("gold", me, me, me, 1, 100 ether);

        vat.file("gold", 'spot', 1);  // massive price crash, now unsafe

        // This should leave us with 0 dink value, and fail
        cat.bite("gold", me);
    }

    function testFail_null_auctions_dink_artificial_values_2() public {
        vat.file("gold", "spot", ray(2000 ether));
        vat.file("gold", "line", rad(20000 ether));
        vat.file("Line",         rad(20000 ether));
        vat.frob("gold", me, me, me, 10 ether, 15000 ether);

        cat.file("box", rad(1000000 ether));  // plenty of room

        // misconfigured dunk (e.g. precision factor incorrect in spell)
        cat.file("gold", "dunk", rad(100));

        vat.file("gold", 'spot', ray(1000 ether));  // now unsafe

        // This should leave us with 0 dink value, and fail
        cat.bite("gold", me);
    }

    function testFail_null_spot_value() public {
        // spot = tag / (par . mat)
        // tag=5, mat=2
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 100 ether, 150 ether);

        vat.file("gold", 'spot', ray(1 ether));  // now unsafe

        assertEq(ink("gold", address(this)), 100 ether);
        assertEq(art("gold", address(this)), 150 ether);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 900 ether);

        cat.file("gold", "dunk", rad(75 ether));
        assertEq(cat.litter(), 0);
        cat.bite("gold", address(this));
        assertEq(cat.litter(), rad(75 ether));
        assertEq(ink("gold", address(this)), 50 ether);
        assertEq(art("gold", address(this)), 75 ether);
        assertEq(vow.sin(now), rad(75 ether));
        assertEq(gem("gold", address(this)), 900 ether);

        vat.file("gold", 'spot', 0);

        // this should fail because spot is 0
        cat.bite("gold", address(this));
    }

    function testFail_vault_is_safe() public {
        // spot = tag / (par . mat)
        // tag=5, mat=2
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 100 ether, 150 ether);

        assertEq(ink("gold", address(this)), 100 ether);
        assertEq(art("gold", address(this)), 150 ether);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 900 ether);

        cat.file("gold", "dunk", rad(75 ether));
        assertEq(cat.litter(), 0);

        // this should fail because the vault is safe
        cat.bite("gold", address(this));
    }

    function test_floppy_bite() public {
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 40 ether, 100 ether);
        vat.file("gold", 'spot', ray(2 ether));  // now unsafe

        cat.file("gold", "dunk", rad(200 ether));  // => bite everything
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
        vow.file("dump", 2000 ether);
        uint f1 = vow.flop();
        assertEq(vow.Woe(),  rad(90 ether));
        assertEq(vow.Joy(),  rad( 0 ether));
        assertEq(vow.Ash(),  rad(10 ether));
        flop.dent(f1, 1000 ether, rad(10 ether));
        assertEq(vow.Woe(),  rad(90 ether));
        assertEq(vow.Joy(),  rad( 0 ether));
        assertEq(vow.Ash(),  rad( 0 ether));

        assertEq(gov.balanceOf(address(this)),  100 ether);
        hevm.warp(now + 4 hours);
        gov.setOwner(address(flop));
        flop.deal(f1);
        assertEq(gov.balanceOf(address(this)), 1100 ether);
    }

    function test_flappy_bite() public {
        // get some surplus
        vat.mint(address(vow), 100 ether);
        assertEq(vat.dai(address(vow)),    rad(100 ether));
        assertEq(gov.balanceOf(address(this)), 100 ether);

        vow.file("bump", rad(100 ether));
        assertEq(vow.Awe(), 0 ether);
        uint id = vow.flap();

        assertEq(vat.dai(address(this)),     rad(0 ether));
        assertEq(gov.balanceOf(address(this)), 100 ether);
        flap.tend(id, rad(100 ether), 10 ether);
        hevm.warp(now + 4 hours);
        gov.setOwner(address(flap));
        flap.deal(id);
        assertEq(vat.dai(address(this)),     rad(100 ether));
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
