// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.12;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import {Vat}     from "../vat.sol";
import {Spotter} from "../spot.sol";
import {Vow}     from "../vow.sol";
import {GemJoin, DaiJoin} from "../join.sol";

import {Clipper} from "../clip.sol";
import "../abaci.sol";
import "../dog.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

contract Exchange {

    DSToken gold;
    DSToken dai;
    uint256 goldPrice;

    constructor(DSToken gold_, DSToken dai_, uint256 goldPrice_) public {
        gold = gold_;
        dai = dai_;
        goldPrice = goldPrice_;
    }

    function sellGold(uint256 goldAmt) external {
        gold.transferFrom(msg.sender, address(this), goldAmt);
        uint256 daiAmt = goldAmt * goldPrice / 1E18;
        dai.transfer(msg.sender, daiAmt);
    }
}

contract Trader {

    Clipper clip;
    Vat vat;
    DSToken gold;
    GemJoin goldJoin;
    DSToken dai;
    DaiJoin daiJoin;
    Exchange exchange;

    constructor(
        Clipper clip_,
        Vat vat_,
        DSToken gold_,
        GemJoin goldJoin_,
        DSToken dai_,
        DaiJoin daiJoin_,
        Exchange exchange_
    ) public {
        clip = clip_;
        vat = vat_;
        gold = gold_;
        goldJoin = goldJoin_;
        dai = dai_;
        daiJoin = daiJoin_;
        exchange = exchange_;
    }

    function take(
        uint256 id,
        uint256 amt,
        uint256 max,
        address who,
        bytes calldata data
    )
        external
    {
        clip.take({
            id: id,
            amt: amt,
            max: max,
            who: who,
            data: data
        });
    }

    function clipperCall(address sender, uint256 owe, uint256 slice, bytes calldata data)
        external {
        data;
        goldJoin.exit(address(this), slice);
        gold.approve(address(exchange));
        exchange.sellGold(slice);
        dai.approve(address(daiJoin));
        vat.hope(address(clip));
        daiJoin.join(sender, owe / 1E27);
    }
}

contract Guy {
    Clipper clip;

    constructor(Clipper clip_) public {
        clip = clip_;
    }

    function hope(address usr) public {
        Vat(address(clip.vat())).hope(usr);
    }

    function take(
        uint256 id,
        uint256 amt,
        uint256 max,
        address who,
        bytes calldata data
    )
        external
    {
        clip.take({
            id: id,
            amt: amt,
            max: max,
            who: who,
            data: data
        });
    }

    function bark(Dog dog, bytes32 ilk, address urn, address usr) external {
        dog.bark(ilk, urn, usr);
    }
}

contract BadGuy is Guy {

    constructor(Clipper clip_) Guy(clip_) public {}

    function clipperCall(address sender, uint256 owe, uint256 slice, bytes calldata data)
        external {
        sender; owe; slice; data;
        clip.take({ // attempt reentrancy
            id: 1,
            amt: 25 ether,
            max: 5 ether * 10E27,
            who: address(this),
            data: ""
        });
    }
}

contract RedoGuy is Guy {

    constructor(Clipper clip_) Guy(clip_) public {}

    function clipperCall(
        address sender, uint256 owe, uint256 slice, bytes calldata data
    ) external {
        owe; slice; data;
        clip.redo(1, sender);
    }
}

contract KickGuy is Guy {

    constructor(Clipper clip_) Guy(clip_) public {}

    function clipperCall(
        address sender, uint256 owe, uint256 slice, bytes calldata data
    ) external {
        sender; owe; slice; data;
        clip.kick(1, 1, address(0), address(0));
    }
}

contract FileUintGuy is Guy {

    constructor(Clipper clip_) Guy(clip_) public {}

    function clipperCall(
        address sender, uint256 owe, uint256 slice, bytes calldata data
    ) external {
        sender; owe; slice; data;
        clip.file("stopped", 1);
    }
}

contract FileAddrGuy is Guy {

    constructor(Clipper clip_) Guy(clip_) public {}

    function clipperCall(
        address sender, uint256 owe, uint256 slice, bytes calldata data
    ) external {
        sender; owe; slice; data;
        clip.file("vow", address(123));
    }
}

contract YankGuy is Guy {

    constructor(Clipper clip_) Guy(clip_) public {}

    function clipperCall(
        address sender, uint256 owe, uint256 slice, bytes calldata data
    ) external {
        sender; owe; slice; data;
        clip.yank(1);
    }
}

contract PublicClip is Clipper {

    constructor(address vat, address spot, address dog, bytes32 ilk) public Clipper(vat, spot, dog, ilk) {}

    function add() public returns (uint256 id) {
        id = ++kicks;
        active.push(id);
        sales[id].pos = active.length - 1;
    }

    function remove(uint256 id) public {
        _remove(id);
    }
}

contract ClipperTest is DSTest {
    Hevm hevm;

    Vat     vat;
    Dog     dog;
    Spotter spot;
    Vow     vow;
    DSValue pip;
    DSToken gold;
    GemJoin goldJoin;
    DSToken dai;
    DaiJoin daiJoin;

    Clipper clip;

    address me;
    Exchange exchange;

    address ali;
    address bob;
    address che;

    uint256 WAD = 10 ** 18;
    uint256 RAY = 10 ** 27;
    uint256 RAD = 10 ** 45;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    bytes32 constant ilk = "gold";
    uint256 constant goldPrice = 5 ether;

    uint256 constant startTime = 604411200; // Used to avoid issues with `now`

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function _ink(bytes32 ilk_, address urn_) internal view returns (uint256) {
        (uint256 ink_,) = vat.urns(ilk_, urn_);
        return ink_;
    }
    function _art(bytes32 ilk_, address urn_) internal view returns (uint256) {
        (,uint256 art_) = vat.urns(ilk_, urn_);
        return art_;
    }

    modifier takeSetup {
        uint256 pos;
        uint256 tab;
        uint256 lot;
        address usr;
        uint96  tic;
        uint256 top;
        uint256 ink;
        uint256 art;

        StairstepExponentialDecrease calc = new StairstepExponentialDecrease();
        calc.file("cut",  RAY - ray(0.01 ether));  // 1% decrease
        calc.file("step", 1);                      // Decrease every 1 second

        clip.file("buf",  ray(1.25 ether));   // 25% Initial price buffer
        clip.file("calc", address(calc));     // File price contract
        clip.file("cusp", ray(0.3 ether));    // 70% drop before reset
        clip.file("tail", 3600);              // 1 hour before reset

        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        assertEq(clip.kicks(), 0);
        dog.bark(ilk, me, address(this));
        assertEq(clip.kicks(), 1);

        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 0);
        assertEq(art, 0);

        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, rad(110 ether));
        assertEq(lot, 40 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(5 ether)); // $4 plus 25%

        assertEq(vat.gem(ilk, ali), 0);
        assertEq(vat.dai(ali), rad(1000 ether));
        assertEq(vat.gem(ilk, bob), 0);
        assertEq(vat.dai(bob), rad(1000 ether));

        _;
    }

    function ray(uint256 wad) internal pure returns (uint256) {
        return wad * 10 ** 9;
    }
    function rad(uint256 wad) internal pure returns (uint256) {
        return wad * 10 ** 27;
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        hevm.warp(startTime);

        me = address(this);

        vat = new Vat();

        spot = new Spotter(address(vat));
        vat.rely(address(spot));

        vow = new Vow(address(vat), address(0), address(0));
        gold = new DSToken("GLD");
        goldJoin = new GemJoin(address(vat), ilk, address(gold));
        vat.rely(address(goldJoin));
        dai = new DSToken("DAI");
        daiJoin = new DaiJoin(address(vat), address(dai));
        vat.suck(address(0), address(daiJoin), rad(1000 ether));
        exchange = new Exchange(gold, dai, goldPrice * 11 / 10);

        dai.mint(1000 ether);
        dai.transfer(address(exchange), 1000 ether);
        dai.setOwner(address(daiJoin));
        gold.mint(1000 ether);
        gold.transfer(address(goldJoin), 1000 ether);

        dog = new Dog(address(vat));
        dog.file("vow", address(vow));
        vat.rely(address(dog));
        vow.rely(address(dog));

        vat.init(ilk);

        vat.slip(ilk, me, 1000 ether);

        pip = new DSValue();
        pip.poke(bytes32(goldPrice)); // Spot = $2.5

        spot.file(ilk, "pip", address(pip));
        spot.file(ilk, "mat", ray(2 ether)); // 200% liquidation ratio for easier test calcs
        spot.poke(ilk);

        vat.file(ilk, "dust", rad(20 ether)); // $20 dust
        vat.file(ilk, "line", rad(10000 ether));
        vat.file("Line",      rad(10000 ether));

        dog.file(ilk, "chop", 1.1 ether); // 10% chop
        dog.file(ilk, "hole", rad(1000 ether));
        dog.file("Hole", rad(1000 ether));

        // dust and chop filed previously so clip.chost will be set correctly
        clip = new Clipper(address(vat), address(spot), address(dog), ilk);
        clip.upchost();
        clip.rely(address(dog));

        dog.file(ilk, "clip", address(clip));
        dog.rely(address(clip));
        vat.rely(address(clip));

        assertEq(vat.gem(ilk, me), 1000 ether);
        assertEq(vat.dai(me), 0);
        vat.frob(ilk, me, me, me, 40 ether, 100 ether);
        assertEq(vat.gem(ilk, me), 960 ether);
        assertEq(vat.dai(me), rad(100 ether));

        pip.poke(bytes32(uint256(4 ether))); // Spot = $2
        spot.poke(ilk);          // Now unsafe

        ali = address(new Guy(clip));
        bob = address(new Guy(clip));
        che = address(new Trader(clip, vat, gold, goldJoin, dai, daiJoin, exchange));

        vat.hope(address(clip));
        Guy(ali).hope(address(clip));
        Guy(bob).hope(address(clip));

        vat.suck(address(0), address(this), rad(1000 ether));
        vat.suck(address(0), address(ali),  rad(1000 ether));
        vat.suck(address(0), address(bob),  rad(1000 ether));
    }

    function test_change_dog() public {
        assertTrue(address(clip.dog()) != address(123));
        clip.file("dog", address(123));
        assertEq(address(clip.dog()), address(123));
    }

    function test_get_chop() public {
        uint256 chop = dog.chop(ilk);
        (, uint256 chop2,,) = dog.ilks(ilk);
        assertEq(chop, chop2);
    }

    function test_kick() public {
        uint256 pos;
        uint256 tab;
        uint256 lot;
        address usr;
        uint96  tic;
        uint256 top;
        uint256 ink;
        uint256 art;

        clip.file("tip",  rad(100 ether)); // Flat fee of 100 DAI
        clip.file("chip", 0);              // No linear increase

        assertEq(clip.kicks(), 0);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 960 ether);
        assertEq(vat.dai(ali), rad(1000 ether));
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        Guy(ali).bark(dog, ilk, me, address(ali));

        assertEq(clip.kicks(), 1);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, rad(110 ether));
        assertEq(lot, 40 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(4 ether));
        assertEq(vat.gem(ilk, me), 960 ether);
        assertEq(vat.dai(ali), rad(1100 ether)); // Paid "tip" amount of DAI for calling bark()
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 0 ether);
        assertEq(art, 0 ether);

        pip.poke(bytes32(goldPrice)); // Spot = $2.5
        spot.poke(ilk);          // Now safe

        hevm.warp(startTime + 100);
        vat.frob(ilk, me, me, me, 40 ether, 100 ether);

        pip.poke(bytes32(uint256(4 ether))); // Spot = $2
        spot.poke(ilk);          // Now unsafe

        (pos, tab, lot, usr, tic, top) = clip.sales(2);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 920 ether);

        clip.file(bytes32("buf"),  ray(1.25 ether)); // 25% Initial price buffer

        clip.file("tip",  rad(100 ether)); // Flat fee of 100 DAI
        clip.file("chip", 0.02 ether);     // Linear increase of 2% of tab

        assertEq(vat.dai(bob), rad(1000 ether));

        Guy(bob).bark(dog, ilk, me, address(bob));

        assertEq(clip.kicks(), 2);
        (pos, tab, lot, usr, tic, top) = clip.sales(2);
        assertEq(pos, 1);
        assertEq(tab, rad(110 ether));
        assertEq(lot, 40 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(5 ether));
        assertEq(vat.gem(ilk, me), 920 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 0 ether);
        assertEq(art, 0 ether);

        assertEq(vat.dai(bob), rad(1000 ether) + rad(100 ether) + tab * 0.02 ether / WAD); // Paid (tip + due * chip) amount of DAI for calling bark()
    }

    function testFail_kick_zero_price() public {
        pip.poke(bytes32(0));
        dog.bark(ilk, me, address(this));
    }

    function testFail_redo_zero_price() public {
        auctionResetSetup(1 hours);

        pip.poke(bytes32(0));

        hevm.warp(startTime + 1801 seconds);
        (bool needsRedo,,,) = clip.getStatus(1);
        assertTrue(needsRedo);
        clip.redo(1, address(this));
    }

    function try_kick(uint256 tab, uint256 lot, address usr, address kpr) internal returns (bool ok) {
        string memory sig = "kick(uint256,uint256,address,address)";
        (ok,) = address(clip).call(abi.encodeWithSignature(sig, tab, lot, usr, kpr));
    }

    function test_kick_basic() public {
        assertTrue(try_kick(1 ether, 2 ether, address(1), address(this)));
    }

    function test_kick_zero_tab() public {
        assertTrue(!try_kick(0, 2 ether, address(1), address(this)));
    }

    function test_kick_zero_lot() public {
        assertTrue(!try_kick(1 ether, 0, address(1), address(this)));
    }

    function test_kick_zero_usr() public {
        assertTrue(!try_kick(1 ether, 2 ether, address(0), address(this)));
    }

    function try_bark(bytes32 ilk_, address urn_) internal returns (bool ok) {
        string memory sig = "bark(bytes32,address,address)";
        (ok,) = address(dog).call(abi.encodeWithSignature(sig, ilk_, urn_, address(this)));
    }

    function test_bark_not_leaving_dust() public {
        uint256 pos;
        uint256 tab;
        uint256 lot;
        address usr;
        uint96  tic;
        uint256 top;
        uint256 ink;
        uint256 art;

        dog.file(ilk, "hole", rad(80 ether)); // Makes room = 80 WAD
        dog.file(ilk, "chop", 1 ether); // 0% chop (for precise calculations)

        assertEq(clip.kicks(), 0);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        assertTrue(try_bark(ilk, me)); // art - dart = 100 - 80 = dust (= 20)

        assertEq(clip.kicks(), 1);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, rad(80 ether)); // No chop
        assertEq(lot, 32 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(4 ether));
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 8 ether);
        assertEq(art, 20 ether);
    }

    function test_bark_not_leaving_dust_over_hole() public {
        uint256 pos;
        uint256 tab;
        uint256 lot;
        address usr;
        uint96  tic;
        uint256 top;
        uint256 ink;
        uint256 art;

        dog.file(ilk, "hole", rad(80 ether) + ray(1 ether)); // Makes room = 80 WAD + 1 wei
        dog.file(ilk, "chop", 1 ether); // 0% chop (for precise calculations)

        assertEq(clip.kicks(), 0);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        assertTrue(try_bark(ilk, me)); // art - dart = 100 - (80 + 1 wei) < dust (= 20) then the whole debt is taken

        assertEq(clip.kicks(), 1);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, rad(100 ether)); // No chop
        assertEq(lot, 40 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(4 ether));
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 0 ether);
        assertEq(art, 0 ether);
    }

    function test_bark_not_leaving_dust_rate() public {
        uint256 pos;
        uint256 tab;
        uint256 lot;
        address usr;
        uint96  tic;
        uint256 top;
        uint256 ink;
        uint256 art;

        vat.fold(ilk, address(vow), int256(ray(0.02 ether)));
        (, uint256 rate,,,) = vat.ilks(ilk);
        assertEq(rate, ray(1.02 ether));

        dog.file(ilk, "hole", 100 * RAD);   // Makes room = 100 RAD
        dog.file(ilk, "chop",   1 ether);   // 0% chop for precise calculations
        vat.file(ilk, "dust",  20 * RAD);   // 20 DAI minimum Vault debt
        clip.upchost();

        assertEq(clip.kicks(), 0);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);  // Full debt is 102 DAI since rate = 1.02 * RAY

        // (art - dart) * rate ~= 2 RAD < dust = 20 RAD
        //   => remnant would be dusty, so a full liquidation occurs.
        assertTrue(try_bark(ilk, me));

        assertEq(clip.kicks(), 1);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, mul(100 ether, rate));  // No chop
        assertEq(lot, 40 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(4 ether));
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 0);
        assertEq(art, 0);
    }

    function test_bark_only_leaving_dust_over_hole_rate() public {
        uint256 pos;
        uint256 tab;
        uint256 lot;
        address usr;
        uint96  tic;
        uint256 top;
        uint256 ink;
        uint256 art;

        vat.fold(ilk, address(vow), int256(ray(0.02 ether)));
        (, uint256 rate,,,) = vat.ilks(ilk);
        assertEq(rate, ray(1.02 ether));

        dog.file(ilk, "hole", 816 * RAD / 10);  // Makes room = 81.6 RAD => dart = 80
        dog.file(ilk, "chop",   1 ether);       // 0% chop for precise calculations
        vat.file(ilk, "dust", 204 * RAD / 10);  // 20.4 DAI dust
        clip.upchost();

        assertEq(clip.kicks(), 0);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        // (art - dart) * rate = 20.4 RAD == dust
        //   => marginal threshold at which partial liquidation is acceptable
        assertTrue(try_bark(ilk, me));

        assertEq(clip.kicks(), 1);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 816 * RAD / 10);  // Equal to ilk.hole
        assertEq(lot, 32 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(4 ether));
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 8 ether);
        assertEq(art, 20 ether);
        (,,,, uint256 dust) = vat.ilks(ilk);
        assertEq(art * rate, dust);
    }

    function test_Hole_hole() public {
        assertEq(dog.Dirt(), 0);
        (,,, uint256 dirt) = dog.ilks(ilk);
        assertEq(dirt, 0);

        dog.bark(ilk, me, address(this));

        (, uint256 tab,,,,) = clip.sales(1);

        assertEq(dog.Dirt(), tab);
        (,,, dirt) = dog.ilks(ilk);
        assertEq(dirt, tab);

        bytes32 ilk2 = "silver";
        Clipper clip2 = new Clipper(address(vat), address(spot), address(dog), ilk2);
        clip2.upchost();
        clip2.rely(address(dog));

        dog.file(ilk2, "clip", address(clip2));
        dog.file(ilk2, "chop", 1.1 ether);
        dog.file(ilk2, "hole", rad(1000 ether));
        dog.rely(address(clip2));

        vat.init(ilk2);
        vat.rely(address(clip2));
        vat.file(ilk2, "line", rad(100 ether));

        vat.slip(ilk2, me, 40 ether);

        DSValue pip2 = new DSValue();
        pip2.poke(bytes32(goldPrice)); // Spot = $2.5

        spot.file(ilk2, "pip", address(pip2));
        spot.file(ilk2, "mat", ray(2 ether));
        spot.poke(ilk2);
        vat.frob(ilk2, me, me, me, 40 ether, 100 ether);
        pip2.poke(bytes32(uint256(4 ether))); // Spot = $2
        spot.poke(ilk2);

        dog.bark(ilk2, me, address(this));

        (, uint256 tab2,,,,) = clip2.sales(1);

        assertEq(dog.Dirt(), tab + tab2);
        (,,, dirt) = dog.ilks(ilk);
        (,,, uint256 dirt2) = dog.ilks(ilk2);
        assertEq(dirt, tab);
        assertEq(dirt2, tab2);
    }

    function test_partial_liquidation_Hole_limit() public {
        dog.file("Hole", rad(75 ether));

        assertEq(_ink(ilk, me), 40 ether);
        assertEq(_art(ilk, me), 100 ether);

        assertEq(dog.Dirt(), 0);
        (,uint256 chop,, uint256 dirt) = dog.ilks(ilk);
        assertEq(dirt, 0);

        dog.bark(ilk, me, address(this));

        (, uint256 tab, uint256 lot,,,) = clip.sales(1);

        (, uint256 rate,,,) = vat.ilks(ilk);

        assertEq(lot, 40 ether * (tab * WAD / rate / chop) / 100 ether);
        assertEq(tab, rad(75 ether) - ray(0.2 ether)); // 0.2 RAY rounding error

        assertEq(_ink(ilk, me), 40 ether - lot);
        assertEq(_art(ilk, me), 100 ether - tab * WAD / rate / chop);

        assertEq(dog.Dirt(), tab);
        (,,, dirt) = dog.ilks(ilk);
        assertEq(dirt, tab);
    }

    function test_partial_liquidation_hole_limit() public {
        dog.file(ilk, "hole", rad(75 ether));

        assertEq(_ink(ilk, me), 40 ether);
        assertEq(_art(ilk, me), 100 ether);

        assertEq(dog.Dirt(), 0);
        (,uint256 chop,, uint256 dirt) = dog.ilks(ilk);
        assertEq(dirt, 0);

        dog.bark(ilk, me, address(this));

        (, uint256 tab, uint256 lot,,,) = clip.sales(1);

        (, uint256 rate,,,) = vat.ilks(ilk);

        assertEq(lot, 40 ether * (tab * WAD / rate / chop) / 100 ether);
        assertEq(tab, rad(75 ether) - ray(0.2 ether)); // 0.2 RAY rounding error

        assertEq(_ink(ilk, me), 40 ether - lot);
        assertEq(_art(ilk, me), 100 ether - tab * WAD / rate / chop);

        assertEq(dog.Dirt(), tab);
        (,,, dirt) = dog.ilks(ilk);
        assertEq(dirt, tab);
    }

    function try_take(uint256 id, uint256 amt, uint256 max, address who, bytes memory data) internal returns (bool ok) {
        string memory sig = "take(uint256,uint256,uint256,address,bytes)";
        (ok,) = address(clip).call(abi.encodeWithSignature(sig, id, amt, max, who, data));
    }

    function test_take_zero_usr() public takeSetup {
        // Auction id 2 is unpopulated.
        (,,, address usr,,) = clip.sales(2);
        assertEq(usr, address(0));
        assertTrue(!try_take(2, 25 ether, ray(5 ether), address(ali), ""));
    }

    function test_take_over_tab() public takeSetup {
        // Bid so owe (= 25 * 5 = 125 RAD) > tab (= 110 RAD)
        // Readjusts slice to be tab/top = 25
        Guy(ali).take({
            id:  1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(ali),
            data: ""
        });

        assertEq(vat.gem(ilk, ali), 22 ether);  // Didn't take whole lot
        assertEq(vat.dai(ali), rad(890 ether)); // Didn't pay more than tab (110)
        assertEq(vat.gem(ilk, me),  978 ether); // 960 + (40 - 22) returned to usr

        // Assert auction ends
        (uint256 pos, uint256 tab, uint256 lot, address usr, uint256 tic, uint256 top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);

        assertEq(dog.Dirt(), 0);
        (,,, uint256 dirt) = dog.ilks(ilk);
        assertEq(dirt, 0);
    }

    function test_take_at_tab() public takeSetup {
        // Bid so owe (= 22 * 5 = 110 RAD) == tab (= 110 RAD)
        Guy(ali).take({
            id:  1,
            amt: 22 ether,
            max: ray(5 ether),
            who: address(ali),
            data: ""
        });

        assertEq(vat.gem(ilk, ali), 22 ether);  // Didn't take whole lot
        assertEq(vat.dai(ali), rad(890 ether)); // Paid full tab (110)
        assertEq(vat.gem(ilk, me), 978 ether);  // 960 + (40 - 22) returned to usr

        // Assert auction ends
        (uint256 pos, uint256 tab, uint256 lot, address usr, uint256 tic, uint256 top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);

        assertEq(dog.Dirt(), 0);
        (,,, uint256 dirt) = dog.ilks(ilk);
        assertEq(dirt, 0);
    }

    function test_take_under_tab() public takeSetup {
        // Bid so owe (= 11 * 5 = 55 RAD) < tab (= 110 RAD)
        Guy(ali).take({
            id:  1,
            amt: 11 ether,     // Half of tab at $110
            max: ray(5 ether),
            who: address(ali),
            data: ""
        });

        assertEq(vat.gem(ilk, ali), 11 ether);  // Didn't take whole lot
        assertEq(vat.dai(ali), rad(945 ether)); // Paid half tab (55)
        assertEq(vat.gem(ilk, me), 960 ether);  // Collateral not returned (yet)

        // Assert auction DOES NOT end
        (uint256 pos, uint256 tab, uint256 lot, address usr, uint256 tic, uint256 top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, rad(55 ether));  // 110 - 5 * 11
        assertEq(lot, 29 ether);       // 40 - 11
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(5 ether));

        assertEq(dog.Dirt(), tab);
        (,,, uint256 dirt) = dog.ilks(ilk);
        assertEq(dirt, tab);
    }

    function test_take_full_lot_partial_tab() public takeSetup {
        hevm.warp(now + 69);  // approx 50% price decline
        // Bid to purchase entire lot less than tab (~2.5 * 40 ~= 100 < 110)
        Guy(ali).take({
            id:  1,
            amt: 40 ether,     // purchase all collateral
            max: ray(2.5 ether),
            who: address(ali),
            data: ""
        });

        assertEq(vat.gem(ilk, ali), 40 ether);  // Took entire lot
        assertTrue(sub(vat.dai(ali), rad(900 ether)) < rad(0.1 ether));  // Paid about 100 ether
        assertEq(vat.gem(ilk, me), 960 ether);  // Collateral not returned

        // Assert auction ends
        (uint256 pos, uint256 tab, uint256 lot, address usr, uint256 tic, uint256 top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);

        // All dirt should be cleared, since the auction has ended, even though < 100% of tab was collected
        assertEq(dog.Dirt(), 0);
        (,,, uint256 dirt) = dog.ilks(ilk);
        assertEq(dirt, 0);
    }

    function testFail_take_bid_too_low() public takeSetup {
        // Bid so max (= 4) < price (= top = 5) (fails with "Clipper/too-expensive")
        Guy(ali).take({
            id:  1,
            amt: 22 ether,
            max: ray(4 ether),
            who: address(ali),
            data: ""
        });
    }

    function test_take_bid_recalculates_due_to_chost_check() public takeSetup {
        (, uint256 tab, uint256 lot,,,) = clip.sales(1);
        assertEq(tab, rad(110 ether));
        assertEq(lot, 40 ether);

        (, uint256 price,uint256 _lot, uint256 _tab) = clip.getStatus(1);
        assertEq(_lot, lot);
        assertEq(_tab, tab);
        assertEq(price, ray(5 ether));

        // Bid for an amount that would leave less than chost remaining tab--bid will be decreased
        // to leave tab == chost post-execution.
        Guy(ali).take({
            id:  1,
            amt: 18 * WAD,  // Costs 90 DAI at current price; 110 - 90 == 20 < 22 == chost
            max: ray(5 ether),
            who: address(ali),
            data: ""
        });

        (, tab, lot,,,) = clip.sales(1);
        assertEq(tab, clip.chost());
        assertEq(lot, 40 ether - (110 * RAD - clip.chost()) / price);
    }

    function test_take_bid_avoids_recalculate_due_no_more_lot() public takeSetup {
        hevm.warp(now + 60); // Reducing the price

        (, uint256 tab, uint256 lot,,,) = clip.sales(1);
        assertEq(tab, rad(110 ether));
        assertEq(lot, 40 ether);

        (, uint256 price,,) = clip.getStatus(1);
        assertEq(price, 2735783211953807380973706855); // 2.73 RAY

        // Bid so owe (= (22 - 1wei) * 5 = 110 RAD - 1) < tab (= 110 RAD)
        // 1 < 20 RAD => owe = 110 RAD - 20 RAD
        Guy(ali).take({
            id:  1,
            amt: 40 ether,
            max: ray(2.8 ether),
            who: address(ali),
            data: ""
        });

        // 40 * 2.73 = 109.42...
        // It means a very low amount of tab (< dust) would remain but doesn't matter
        // as the auction is finished because there isn't more lot
        (, tab, lot,,,) = clip.sales(1);
        assertEq(tab, 0);
        assertEq(lot, 0);
    }

    function test_take_bid_fails_no_partial_allowed() public takeSetup {
        (, uint256 price,,) = clip.getStatus(1);
        assertEq(price, ray(5 ether));

        clip.take({
            id:  1,
            amt: 17.6 ether,
            max: ray(5 ether),
            who: address(this),
            data: ""
        });

        (, uint256 tab, uint256 lot,,,) = clip.sales(1);
        assertEq(tab, rad(22 ether));
        assertEq(lot, 22.4 ether);
        assertTrue(!(tab > clip.chost()));

        assertTrue(!try_take({
            id:  1,
            amt: 1 ether,  // partial purchase attempt when !(tab > chost)
            max: ray(5 ether),
            who: address(this),
            data: ""
        }));

        clip.take({
            id:  1,
            amt: tab / price, // This time take the whole tab
            max: ray(5 ether),
            who: address(this),
            data: ""
        });
    }

    function test_take_multiple_bids_different_prices() public takeSetup {
        uint256 pos;
        uint256 tab;
        uint256 lot;
        address usr;
        uint96  tic;
        uint256 top;

        // Bid so owe (= 10 * 5 = 50 RAD) < tab (= 110 RAD)
        Guy(ali).take({
            id:  1,
            amt: 10 ether,
            max: ray(5 ether),
            who: address(ali),
            data: ""
        });

        assertEq(vat.gem(ilk, ali), 10 ether);  // Didn't take whole lot
        assertEq(vat.dai(ali), rad(950 ether)); // Paid some tab (50)
        assertEq(vat.gem(ilk, me), 960 ether);  // Collateral not returned (yet)

        // Assert auction DOES NOT end
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, rad(60 ether));  // 110 - 5 * 10
        assertEq(lot, 30 ether);       // 40 - 10
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(5 ether));

        hevm.warp(now + 30);

        (, uint256 _price, uint256 _lot,) = clip.getStatus(1);
        Guy(bob).take({
            id:  1,
            amt: _lot,     // Buy the rest of the lot
            max: ray(_price), // 5 * 0.99 ** 30 = 3.698501866941401 RAY => max > price
            who: address(bob),
            data: ""
        });

        // Assert auction is over
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0 * WAD);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);

        uint256 expectedGem = (RAY * 60 ether) / _price;  // tab / price
        assertEq(vat.gem(ilk, bob), expectedGem);         // Didn't take whole lot
        assertEq(vat.dai(bob), rad(940 ether));           // Paid rest of tab (60)

        uint256 lotReturn = 30 ether - expectedGem;         // lot - loaf.tab / max = 15
        assertEq(vat.gem(ilk, me), 960 ether + lotReturn);  // Collateral returned (10 WAD)
    }

    function auctionResetSetup(uint256 tau) internal {
        LinearDecrease calc = new LinearDecrease();
        calc.file(bytes32("tau"), tau);       // tau hours till zero is reached (used to test tail)

        vat.file(ilk, "dust", rad(20 ether)); // $20 dust

        clip.file("buf",  ray(1.25 ether));   // 25% Initial price buffer
        clip.file("calc", address(calc));     // File price contract
        clip.file("cusp", ray(0.5 ether));    // 50% drop before reset
        clip.file("tail", 3600);              // 1 hour before reset

        assertEq(clip.kicks(), 0);
        dog.bark(ilk, me, address(this));
        assertEq(clip.kicks(), 1);
    }

    function try_redo(uint256 id, address kpr) internal returns (bool ok) {
        string memory sig = "redo(uint256,address)";
        (ok,) = address(clip).call(abi.encodeWithSignature(sig, id, kpr));
    }

    function test_auction_reset_tail() public {
        auctionResetSetup(10 hours); // 10 hours till zero is reached (used to test tail)

        pip.poke(bytes32(uint256(3 ether))); // Spot = $1.50 (update price before reset is called)

        (,,,, uint96 ticBefore, uint256 topBefore) = clip.sales(1);
        assertEq(uint256(ticBefore), startTime);
        assertEq(topBefore, ray(5 ether)); // $4 spot + 25% buffer = $5 (wasn't affected by poke)

        hevm.warp(startTime + 3600 seconds);
        (bool needsRedo,,,) = clip.getStatus(1);
        assertTrue(!needsRedo);
        assertTrue(!try_redo(1, address(this)));
        hevm.warp(startTime + 3601 seconds);
        (needsRedo,,,) = clip.getStatus(1);
        assertTrue(needsRedo);
        assertTrue(try_redo(1, address(this)));

        (,,,, uint96 ticAfter, uint256 topAfter) = clip.sales(1);
        assertEq(uint256(ticAfter), startTime + 3601 seconds);     // (now)
        assertEq(topAfter, ray(3.75 ether)); // $3 spot + 25% buffer = $5 (used most recent OSM price)
    }

    function test_auction_reset_cusp() public {
        auctionResetSetup(1 hours); // 1 hour till zero is reached (used to test cusp)

        pip.poke(bytes32(uint256(3 ether))); // Spot = $1.50 (update price before reset is called)

        (,,,, uint96 ticBefore, uint256 topBefore) = clip.sales(1);
        assertEq(uint256(ticBefore), startTime);
        assertEq(topBefore, ray(5 ether)); // $4 spot + 25% buffer = $5 (wasn't affected by poke)

        hevm.warp(startTime + 1800 seconds);
        (bool needsRedo,,,) = clip.getStatus(1);
        assertTrue(!needsRedo);
        assertTrue(!try_redo(1, address(this)));
        hevm.warp(startTime + 1801 seconds);
        (needsRedo,,,) = clip.getStatus(1);
        assertTrue(needsRedo);
        assertTrue(try_redo(1, address(this)));

        (,,,, uint96 ticAfter, uint256 topAfter) = clip.sales(1);
        assertEq(uint256(ticAfter), startTime + 1801 seconds);     // (now)
        assertEq(topAfter, ray(3.75 ether)); // $3 spot + 25% buffer = $3.75 (used most recent OSM price)
    }

    function test_auction_reset_tail_twice() public {
        auctionResetSetup(10 hours); // 10 hours till zero is reached (used to test tail)

        hevm.warp(startTime + 3601 seconds);
        clip.redo(1, address(this));

        assertTrue(!try_redo(1, address(this)));
    }

    function test_auction_reset_cusp_twice() public {
        auctionResetSetup(1 hours); // 1 hour till zero is reached (used to test cusp)

        hevm.warp(startTime + 1801 seconds); // Price goes below 50% "cusp" after 30min01sec
        clip.redo(1, address(this));

        assertTrue(!try_redo(1, address(this)));
    }

    function test_redo_zero_usr() public {
        // Can't reset a non-existent auction.
        assertTrue(!try_redo(1, address(this)));
    }

    function test_setBreaker() public {
        clip.file("stopped", 1);
        assertEq(clip.stopped(), 1);
        clip.file("stopped", 2);
        assertEq(clip.stopped(), 2);
        clip.file("stopped", 3);
        assertEq(clip.stopped(), 3);
        clip.file("stopped", 0);
        assertEq(clip.stopped(), 0);
    }

    function test_stopped_kick() public {
        uint256 pos;
        uint256 tab;
        uint256 lot;
        address usr;
        uint96  tic;
        uint256 top;
        uint256 ink;
        uint256 art;

        assertEq(clip.kicks(), 0);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        // Any level of stoppage prevents kicking.
        clip.file("stopped", 1);
        assertTrue(!try_bark(ilk, me));

        clip.file("stopped", 2);
        assertTrue(!try_bark(ilk, me));

        clip.file("stopped", 3);
        assertTrue(!try_bark(ilk, me));

        clip.file("stopped", 0);
        assertTrue(try_bark(ilk, me));
    }

    // At a stopped == 1 we are ok to take
    function test_stopped_1_take() public takeSetup {
        clip.file("stopped", 1);
        // Bid so owe (= 25 * 5 = 125 RAD) > tab (= 110 RAD)
        // Readjusts slice to be tab/top = 25
        Guy(ali).take({
            id:  1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(ali),
            data: ""
        });
    }

    function test_stopped_2_take() public takeSetup {
        clip.file("stopped", 2);
        // Bid so owe (= 25 * 5 = 125 RAD) > tab (= 110 RAD)
        // Readjusts slice to be tab/top = 25
        Guy(ali).take({
            id:  1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(ali),
            data: ""
        });
    }

    function testFail_stopped_3_take() public takeSetup {
        clip.file("stopped", 3);
        // Bid so owe (= 25 * 5 = 125 RAD) > tab (= 110 RAD)
        // Readjusts slice to be tab/top = 25
        Guy(ali).take({
            id:  1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(ali),
            data: ""
        });
    }

    function test_stopped_1_auction_reset_tail() public {
        auctionResetSetup(10 hours); // 10 hours till zero is reached (used to test tail)

        clip.file("stopped", 1);

        pip.poke(bytes32(uint256(3 ether))); // Spot = $1.50 (update price before reset is called)

        (,,,, uint96 ticBefore, uint256 topBefore) = clip.sales(1);
        assertEq(uint256(ticBefore), startTime);
        assertEq(topBefore, ray(5 ether)); // $4 spot + 25% buffer = $5 (wasn't affected by poke)

        hevm.warp(startTime + 3600 seconds);
        assertTrue(!try_redo(1, address(this)));
        hevm.warp(startTime + 3601 seconds);
        assertTrue(try_redo(1, address(this)));

        (,,,, uint96 ticAfter, uint256 topAfter) = clip.sales(1);
        assertEq(uint256(ticAfter), startTime + 3601 seconds);     // (now)
        assertEq(topAfter, ray(3.75 ether)); // $3 spot + 25% buffer = $5 (used most recent OSM price)
    }

    function test_stopped_2_auction_reset_tail() public {
        auctionResetSetup(10 hours); // 10 hours till zero is reached (used to test tail)

        clip.file("stopped", 2);

        pip.poke(bytes32(uint256(3 ether))); // Spot = $1.50 (update price before reset is called)

        (,,,, uint96 ticBefore, uint256 topBefore) = clip.sales(1);
        assertEq(uint256(ticBefore), startTime);
        assertEq(topBefore, ray(5 ether)); // $4 spot + 25% buffer = $5 (wasn't affected by poke)

        hevm.warp(startTime + 3601 seconds);
        (bool needsRedo,,,) = clip.getStatus(1);
        assertTrue(needsRedo);  // Redo possible if circuit breaker not set
        assertTrue(!try_redo(1, address(this)));  // Redo fails because of circuit breaker
    }

    function test_stopped_3_auction_reset_tail() public {
        auctionResetSetup(10 hours); // 10 hours till zero is reached (used to test tail)

        clip.file("stopped", 3);

        pip.poke(bytes32(uint256(3 ether))); // Spot = $1.50 (update price before reset is called)

        (,,,, uint96 ticBefore, uint256 topBefore) = clip.sales(1);
        assertEq(uint256(ticBefore), startTime);
        assertEq(topBefore, ray(5 ether)); // $4 spot + 25% buffer = $5 (wasn't affected by poke)

        hevm.warp(startTime + 3601 seconds);
        (bool needsRedo,,,) = clip.getStatus(1);
        assertTrue(needsRedo);  // Redo possible if circuit breaker not set
        assertTrue(!try_redo(1, address(this)));  // Redo fails because of circuit breaker
    }

    function test_redo_incentive() public takeSetup {
        clip.file("tip",  rad(100 ether)); // Flat fee of 100 DAI
        clip.file("chip", 0);              // No linear increase

        (, uint256 tab, uint256 lot,,,) = clip.sales(1);

        assertEq(tab, rad(110 ether));
        assertEq(lot, 40 ether);

        hevm.warp(now + 300);
        clip.redo(1, address(123));
        assertEq(vat.dai(address(123)), clip.tip());

        clip.file("chip", 0.02 ether);     // Reward 2% of tab
        hevm.warp(now + 300);
        clip.redo(1, address(234));
        assertEq(vat.dai(address(234)), clip.tip() + clip.chip() * tab / WAD);

        clip.file("tip", 0); // No more flat fee
        hevm.warp(now + 300);
        clip.redo(1, address(345));
        assertEq(vat.dai(address(345)), clip.chip() * tab / WAD);

        vat.file(ilk, "dust", rad(100 ether) + 1); // ensure wmul(dust, chop) > 110 DAI (tab)
        clip.upchost();
        assertEq(clip.chost(), 110 * RAD + 1);

        hevm.warp(now + 300);
        clip.redo(1, address(456));
        assertEq(vat.dai(address(456)), 0);

        // Set dust so that wmul(dust, chop) is well below tab to check the dusty lot case.
        vat.file(ilk, "dust", rad(20 ether)); // $20 dust
        clip.upchost();
        assertEq(clip.chost(), 22 * RAD);

        hevm.warp(now + 100); // Reducing the price

        (, uint256 price,,) = clip.getStatus(1);
        assertEq(price, 1830161706366147524653080130); // 1.83 RAY

        clip.take({
            id:  1,
            amt: 38 ether,
            max: ray(5 ether),
            who: address(this),
            data: ""
        });

        (, tab, lot,,,) = clip.sales(1);

        assertEq(tab, rad(110 ether) - 38 ether * price); // > 22 DAI chost
        // When auction is reset the current price of lot
        // is calculated from oracle price ($4) to see if dusty
        assertEq(lot, 2 ether); // (2 * $4) < $20 quivalent (dusty collateral)

        hevm.warp(now + 300);
        clip.redo(1, address(567));
        assertEq(vat.dai(address(567)), 0);
    }

    function test_incentive_max_values() public {
        clip.file("chip", 2 ** 64 - 1);
        clip.file("tip", 2 ** 192 - 1);

        assertEq(uint256(clip.chip()), uint256(18.446744073709551615 * 10 ** 18));
        assertEq(uint256(clip.tip()), uint256(6277101735386.680763835789423207666416102355444464034512895 * 10 ** 45));

        clip.file("chip", 2 ** 64);
        clip.file("tip", 2 ** 192);

        assertEq(uint256(clip.chip()), 0);
        assertEq(uint256(clip.tip()), 0);
    }

    function test_Clipper_yank() public takeSetup {
        uint256 preGemBalance = vat.gem(ilk, address(this));
        (,, uint256 origLot,,,) = clip.sales(1);

        uint startGas = gasleft();
        clip.yank(1);
        uint endGas = gasleft();
        emit log_named_uint("yank gas", startGas - endGas);

        // Assert that the auction was deleted.
        (uint256 pos, uint256 tab, uint256 lot, address usr, uint256 tic, uint256 top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);

        // Assert that callback to clear dirt was successful.
        assertEq(dog.Dirt(), 0);
        (,,, uint256 dirt) = dog.ilks(ilk);
        assertEq(dirt, 0);

        // Assert transfer of gem.
        assertEq(vat.gem(ilk, address(this)), preGemBalance + origLot);
    }

    function test_remove_id() public {
        PublicClip pclip = new PublicClip(address(vat), address(spot), address(dog), "gold");
        uint256 pos;

        pclip.add();
        pclip.add();
        uint256 id = pclip.add();
        pclip.add();
        pclip.add();

        // [1,2,3,4,5]
        assertEq(pclip.count(), 5);   // 5 elements added
        assertEq(pclip.active(0), 1);
        assertEq(pclip.active(1), 2);
        assertEq(pclip.active(2), 3);
        assertEq(pclip.active(3), 4);
        assertEq(pclip.active(4), 5);

        pclip.remove(id);

        // [1,2,5,4]
        assertEq(pclip.count(), 4);
        assertEq(pclip.active(0), 1);
        assertEq(pclip.active(1), 2);
        assertEq(pclip.active(2), 5);  // Swapped last for middle
        (pos,,,,,) = pclip.sales(5);
        assertEq(pos, 2);
        assertEq(pclip.active(3), 4);

        pclip.remove(4);

        // [1,2,5]
        assertEq(pclip.count(), 3);

        (pos,,,,,) = pclip.sales(1);
        assertEq(pos, 0); // Sale 1 in slot 0
        assertEq(pclip.active(0), 1);

        (pos,,,,,) = pclip.sales(2);
        assertEq(pos, 1); // Sale 2 in slot 1
        assertEq(pclip.active(1), 2);

        (pos,,,,,) = pclip.sales(5);
        assertEq(pos, 2); // Sale 5 in slot 2
        assertEq(pclip.active(2), 5); // Final element removed

        (pos,,,,,) = pclip.sales(4);
        assertEq(pos, 0); // Sale 4 was deleted. Returns 0
    }

    function testFail_id_out_of_range() public {
        PublicClip pclip = new PublicClip(address(vat), address(spot), address(dog), "gold");

        pclip.add();
        pclip.add();

        pclip.active(9); // Fail because id is out of range
    }

    function testFail_not_enough_dai() public takeSetup {
        Guy(che).take({
            id:  1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(che),
            data: ""
        });
    }

    function test_flashsale() public takeSetup {
        assertEq(vat.dai(che), 0);
        assertEq(dai.balanceOf(che), 0);
        Guy(che).take({
            id:  1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(che),
            data: "hey"
        });
        assertEq(vat.dai(che), 0);
        assertTrue(dai.balanceOf(che) > 0); // Che turned a profit
    }

    function testFail_reentrancy_take() public takeSetup {
        BadGuy usr = new BadGuy(clip);
        usr.hope(address(clip));
        vat.suck(address(0), address(usr),  rad(1000 ether));

        usr.take({
            id: 1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(usr),
            data: "hey"
        });
    }

    function testFail_reentrancy_redo() public takeSetup {
        RedoGuy usr = new RedoGuy(clip);
        usr.hope(address(clip));
        vat.suck(address(0), address(usr),  rad(1000 ether));

        usr.take({
            id: 1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(usr),
            data: "hey"
        });
    }

    function testFail_reentrancy_kick() public takeSetup {
        KickGuy usr = new KickGuy(clip);
        usr.hope(address(clip));
        vat.suck(address(0), address(usr),  rad(1000 ether));
        clip.rely(address(usr));

        usr.take({
            id: 1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(usr),
            data: "hey"
        });
    }

    function testFail_reentrancy_file_uint() public takeSetup {
        FileUintGuy usr = new FileUintGuy(clip);
        usr.hope(address(clip));
        vat.suck(address(0), address(usr),  rad(1000 ether));
        clip.rely(address(usr));

        usr.take({
            id: 1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(usr),
            data: "hey"
        });
    }

    function testFail_reentrancy_file_addr() public takeSetup {
        FileAddrGuy usr = new FileAddrGuy(clip);
        usr.hope(address(clip));
        vat.suck(address(0), address(usr),  rad(1000 ether));
        clip.rely(address(usr));

        usr.take({
            id: 1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(usr),
            data: "hey"
        });
    }

    function testFail_reentrancy_yank() public takeSetup {
        YankGuy usr = new YankGuy(clip);
        usr.hope(address(clip));
        vat.suck(address(0), address(usr),  rad(1000 ether));
        clip.rely(address(usr));

        usr.take({
            id: 1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(usr),
            data: "hey"
        });
    }

    function testFail_take_impersonation() public takeSetup { // should fail, but works
        Guy usr = new Guy(clip);
        usr.take({
            id: 1,
            amt: 99999999999999 ether,
            max: ray(99999999999999 ether),
            who: address(ali),
            data: ""
        });
    }

    function test_gas_bark_kick() public {
        // Assertions to make sure setup is as expected.
        assertEq(clip.kicks(), 0);
        (uint256 pos, uint256 tab, uint256 lot, address usr, uint256 tic, uint256 top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 960 ether);
        assertEq(vat.dai(ali), rad(1000 ether));
        (uint256 ink, uint256 art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        uint256 preGas = gasleft();
        Guy(ali).bark(dog, ilk, me, address(ali));
        uint256 diffGas = preGas - gasleft();
        log_named_uint("bark with kick gas", diffGas);
    }

    function test_gas_partial_take() public takeSetup {
        uint256 preGas = gasleft();
        // Bid so owe (= 11 * 5 = 55 RAD) < tab (= 110 RAD)
        Guy(ali).take({
            id:  1,
            amt: 11 ether,     // Half of tab at $110
            max: ray(5 ether),
            who: address(ali),
            data: ""
        });
        uint256 diffGas = preGas - gasleft();
        log_named_uint("partial take gas", diffGas);

        assertEq(vat.gem(ilk, ali), 11 ether);  // Didn't take whole lot
        assertEq(vat.dai(ali), rad(945 ether)); // Paid half tab (55)
        assertEq(vat.gem(ilk, me), 960 ether);  // Collateral not returned (yet)

        // Assert auction DOES NOT end
        (uint256 pos, uint256 tab, uint256 lot, address usr, uint256 tic, uint256 top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, rad(55 ether));  // 110 - 5 * 11
        assertEq(lot, 29 ether);       // 40 - 11
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(5 ether));
    }

    function test_gas_full_take() public takeSetup {
        uint256 preGas = gasleft();
        // Bid so owe (= 25 * 5 = 125 RAD) > tab (= 110 RAD)
        // Readjusts slice to be tab/top = 25
        Guy(ali).take({
            id:  1,
            amt: 25 ether,
            max: ray(5 ether),
            who: address(ali),
            data: ""
        });
        uint256 diffGas = preGas - gasleft();
        log_named_uint("full take gas", diffGas);

        assertEq(vat.gem(ilk, ali), 22 ether);  // Didn't take whole lot
        assertEq(vat.dai(ali), rad(890 ether)); // Didn't pay more than tab (110)
        assertEq(vat.gem(ilk, me),  978 ether); // 960 + (40 - 22) returned to usr

        // Assert auction ends
        (uint256 pos, uint256 tab, uint256 lot, address usr, uint256 tic, uint256 top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
    }
}
