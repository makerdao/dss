pragma solidity >=0.5.12;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import {Vat}     from "../vat.sol";
import {Spotter} from "../spot.sol";
import {Vow}     from "../vow.sol";

import {Clipper} from "../clip.sol";
import "../abaci.sol";
import "../dog.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
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
}

contract ClipperTest is DSTest {
    Hevm hevm;

    Vat     vat;
    Dog     dog;
    Spotter spot;
    Vow     vow;
    DSValue pip;

    Clipper clip;

    address me;

    address ali;
    address bob;

    uint256 WAD = 10 ** 18;
    uint256 RAY = 10 ** 27;
    uint256 RAD = 10 ** 45;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    bytes32 constant ilk = "gold";

    uint256 constant startTime = 604411200; // Used to avoid issues with `now`

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
        calc.file("cut",  ray(0.01 ether)); // 1% decrease
        calc.file("step", 1);               // Decrease every 1 second

        clip.file("buf",  ray(1.25 ether)); // 25% Initial price buffer
        clip.file("dust", rad(20   ether)); // $20 dust
        clip.file("calc", address(calc));   // File price contract
        clip.file("cusp", ray(0.3 ether));  // 70% drop before reset
        clip.file("tail", 3600);            // 1 hour before reset

        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        assertEq(clip.kicks(), 0);
        dog.bark(ilk, me);
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

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        hevm.warp(startTime);

        me = address(this);

        vat = new Vat();

        spot = new Spotter(address(vat));
        vat.rely(address(spot));

        vow = new Vow(address(vat), address(0), address(0));

        dog = new Dog(address(vat));
        dog.file("vow", address(vow));
        vat.rely(address(dog));
        vow.rely(address(dog));

        vat.init(ilk);

        vat.slip(ilk, me, 1000 ether);

        pip = new DSValue();
        pip.poke(bytes32(uint256(5 ether))); // Spot = $2.5

        spot.file(ilk, "pip", address(pip));
        spot.file(ilk, "mat", ray(2 ether)); // 100% liquidation ratio for easier test calcs
        spot.poke(ilk);

        vat.file(ilk, "line", rad(10000 ether));
        vat.file("Line",      rad(10000 ether));

        clip = new Clipper(address(vat), address(spot), address(dog), ilk);
        clip.rely(address(dog));

        dog.file(ilk, "clip", address(clip));
        dog.file(ilk, "chop", 1.1 ether); // 10% chop
        dog.file(ilk, "hole", rad(1000 ether));
        dog.file("Hole", rad(1000 ether));
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

        Guy(ali).hope(address(clip));
        Guy(bob).hope(address(clip));

        vat.suck(address(0), address(ali), rad(1000 ether));
        vat.suck(address(0), address(bob), rad(1000 ether));
    }

    function checkExpDecrease(
        StairstepExponentialDecrease calc,
        uint256 cut,
        uint256 step,
        uint256 top,
        uint256 tic,
        uint256 percentDecrease,
        uint256 testTime,
        uint256 tolerance
    )
        public
    {
        uint256 price;
        uint256 lastPrice;
        uint256 diff;
        uint256 testPrice;

        hevm.warp(startTime);
        calc.file(bytes32("step"), step);
        calc.file(bytes32("cut"),  cut);
        price = calc.price(top, tic);
        assertEq(price, top);

        for(uint256 i = 1; i < testTime; i += 1) {
            hevm.warp(startTime + i);
            lastPrice = price;
            price = calc.price(top, tic);
            // Stairstep calculation
            if (i % step == 0) { testPrice = lastPrice * (RAY - percentDecrease) / RAY; }
            else               { testPrice = lastPrice; }
            // Tolerance calculation
            if (testPrice >= price) { diff = testPrice - price; }
            else                    { diff = price - testPrice; }
            // Precision is lost as price goes higher (can only get 10^27 max precision).
            // E.g., top = 50m => Expected: 16338200015683006288456874400625678
            //                    Actual:   16338200015683006288456874350000000
            assertTrue(diff <= tolerance); 
        }
    }

    function test_stairstep_exp_decrease() public {
        StairstepExponentialDecrease calc = new StairstepExponentialDecrease();
        uint256 tic = now; // Start of auction
        uint256 percentDecrease;
        uint256 step;
        uint256 testTime = 10 minutes;


        /*** Extreme high collateral price ($50m) ***/
    
        uint256 tolerance = 100000000; // Tolerance scales with price
        uint256 top =       50000000 * RAY; 
        
        // 1.1234567890% decrease every 1 second
        // TODO: Check if there's a cleaner way to do this. I was getting rational_const errors.
        percentDecrease = 1.1234567890E27 / 100;
        step = 1;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 2.1234567890% decrease every 1 second
        percentDecrease = 2.1234567890E27 / 100;
        step = 1;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 1.1234567890% decrease every 5 seconds
        percentDecrease = 1.1234567890E27 / 100;
        step = 5;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 2.1234567890% decrease every 5 seconds
        percentDecrease = 2.1234567890E27 / 100;
        step = 5;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 1.1234567890% decrease every 5 minutes
        percentDecrease = 1.1234567890E27 / 100;
        step = 5 minutes;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);


        /*** Extreme low collateral price ($0.0000001) ***/
        
        tolerance = 1; // Lowest tolerance is 1e-27
        top = 1 * RAY / 10000000; 

        // 1.1234567890% decrease every 1 second
        percentDecrease = 1.1234567890E27 / 100;
        step = 1;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 2.1234567890% decrease every 1 second
        percentDecrease = 2.1234567890E27 / 100;
        step = 1;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 1.1234567890% decrease every 5 seconds
        percentDecrease = 1.1234567890E27 / 100;
        step = 5;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 2.1234567890% decrease every 5 seconds
        percentDecrease = 2.1234567890E27 / 100;
        step = 5;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 1.1234567890% decrease every 5 minutes
        percentDecrease = 1.1234567890E27 / 100;
        step = 5 minutes;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);
    }

    function test_linear_decrease() public {
        hevm.warp(startTime);
        LinearDecrease calc = new LinearDecrease();
        calc.file(bytes32("tau"), 3600);

        uint256 top = 1000 * RAY;
        uint256 tic = now; // Start of auction
        uint256 price = calc.price(top, tic);
        assertEq(price, top);

        hevm.warp(startTime + 360);                // 6min in,   1/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100) * RAY);

        hevm.warp(startTime + 360 * 2);            // 12min in,  2/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 2) * RAY);

        hevm.warp(startTime + 360 * 3);            // 18min in,  3/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 3) * RAY);

        hevm.warp(startTime + 360 * 4);            // 24min in,  4/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 4) * RAY);

        hevm.warp(startTime + 360 * 5);            // 30min in,  5/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 5) * RAY);

        hevm.warp(startTime + 360 * 6);            // 36min in,  6/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 6) * RAY);

        hevm.warp(startTime + 360 * 7);            // 42min in,  7/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 7) * RAY);

        hevm.warp(startTime + 360 * 8);            // 48min in,  8/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 8) * RAY);

        hevm.warp(startTime + 360 * 9);            // 54min in,  9/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 9) * RAY);

        hevm.warp(startTime + 360 * 10);           // 60min in, 10/10 done
        price = calc.price(top, tic);
        assertEq(price, 0);
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

        dog.bark(ilk, me);

        assertEq(clip.kicks(), 1);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, rad(110 ether));
        assertEq(lot, 40 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(4 ether));
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 0 ether);
        assertEq(art, 0 ether);

        pip.poke(bytes32(uint256(5 ether))); // Spot = $2.5
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

        dog.bark(ilk, me);

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
    }

    function test_Hole_hole() public {
        assertEq(dog.Dirt(), 0);
        (,,, uint256 dirt) = dog.ilks(ilk);
        assertEq(dirt, 0);

        dog.bark(ilk, me);

        (, uint256 tab,,,,) = clip.sales(1);

        assertEq(dog.Dirt(), tab);
        (,,, dirt) = dog.ilks(ilk);
        assertEq(dirt, tab);

        bytes32 ilk2 = "silver";
        Clipper clip2 = new Clipper(address(vat), address(spot), address(dog), ilk2);
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
        pip2.poke(bytes32(uint256(5 ether))); // Spot = $2.5

        spot.file(ilk2, "pip", address(pip2));
        spot.file(ilk2, "mat", ray(2 ether));
        spot.poke(ilk2);
        vat.frob(ilk2, me, me, me, 40 ether, 100 ether);
        pip2.poke(bytes32(uint256(4 ether))); // Spot = $2
        spot.poke(ilk2);

        dog.bark(ilk2, me);

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

        dog.bark(ilk, me);

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

        dog.bark(ilk, me);

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

    function testFail_take_bid_creates_dust() public takeSetup {
        // Bid so owe (= (22 - 1wei) * 5 = 110 RAD - 1) < tab (= 110 RAD) (fails with "Clipper/dust")
        Guy(ali).take({
            id:  1,
            amt: 22 ether - 1,
            max: ray(5 ether),
            who: address(ali),
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

        uint256 price = clip.calc().price(top, tic);
        Guy(bob).take({
            id:  1,
            amt: 30 ether,     // Buy the rest of the lot 
            max: ray(4 ether), // 5 * 0.99 ** 30 = 3.698501866941401 RAY => max > price
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

        uint256 expectedGem = (RAY * 60 ether) / price;  // tab / price
        assertEq(vat.gem(ilk, bob), expectedGem);        // Didn't take whole lot
        assertEq(vat.dai(bob), rad(940 ether));          // Paid rest of tab (60)

        uint256 lotReturn = 30 ether - expectedGem;         // lot - loaf.tab / max = 15
        assertEq(vat.gem(ilk, me), 960 ether + lotReturn);  // Collateral returned (10 WAD)
    } 

    function auctionResetSetup(uint256 tau) internal {
        LinearDecrease calc = new LinearDecrease();
        calc.file(bytes32("tau"), tau);     // tau hours till zero is reached (used to test tail)  

        clip.file("buf",  ray(1.25 ether)); // 25% Initial price buffer
        clip.file("dust", rad(20   ether)); // $20 dust
        clip.file("calc", address(calc));   // File price contract
        clip.file("cusp", ray(0.5 ether));  // 50% drop before reset
        clip.file("tail", 3600);            // 1 hour before reset

        assertEq(clip.kicks(), 0);
        dog.bark(ilk, me);
        assertEq(clip.kicks(), 1);
    }

    function try_redo(uint256 id) internal returns (bool ok) {
        string memory sig = "redo(uint256)";
        (ok,) = address(clip).call(abi.encodeWithSignature(sig, id));
    }

    function test_auction_reset_tail() public {
        auctionResetSetup(10 hours); // 10 hours till zero is reached (used to test tail) 

        pip.poke(bytes32(uint256(3 ether))); // Spot = $1.50 (update price before reset is called)

        (,,,, uint96 ticBefore, uint256 topBefore) = clip.sales(1);
        assertEq(uint256(ticBefore), startTime);
        assertEq(topBefore, ray(5 ether)); // $4 spot + 25% buffer = $5 (wasn't affected by poke)
        
        hevm.warp(startTime + 3600 seconds);
        assertTrue(!try_redo(1));
        hevm.warp(startTime + 3601 seconds);
        assertTrue( try_redo(1));
        
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
        assertTrue(!try_redo(1));
        hevm.warp(startTime + 1801 seconds);
        assertTrue( try_redo(1));
        
        (,,,, uint96 ticAfter, uint256 topAfter) = clip.sales(1);
        assertEq(uint256(ticAfter), startTime + 1801 seconds);     // (now)
        assertEq(topAfter, ray(3.75 ether)); // $3 spot + 25% buffer = $3.75 (used most recent OSM price)
    }

    function testFail_auction_reset_tail_twice() public {
        auctionResetSetup(10 hours); // 10 hours till zero is reached (used to test tail) 
        
        hevm.warp(startTime + 3601 seconds);
        clip.redo(1);

        clip.redo(1);
    }

    function testFail_auction_reset_cusp_twice() public {
        auctionResetSetup(1 hours); // 1 hour till zero is reached (used to test cusp) 
        
        hevm.warp(startTime + 1801 seconds); // Price goes below 50% "cusp" after 30min01sec
        clip.redo(1);

        clip.redo(1);
    }

    function test_setBreaker() public {
        clip.setBreaker(1);
        assertEq(clip.stopped(), 1);
    }

    function testFail_stopped_kick() public {
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

        clip.setBreaker(1);

        dog.bark(ilk, me);
    }

    // At a stopped == 1 we are ok to take
    function test_stopped_take() public takeSetup {
        clip.setBreaker(1);
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

    function testFail_stopped_take() public takeSetup {
        clip.setBreaker(2);
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

    function test_stopped_auction_reset_tail() public {
        auctionResetSetup(10 hours); // 10 hours till zero is reached (used to test tail) 

        clip.setBreaker(1);

        pip.poke(bytes32(uint256(3 ether))); // Spot = $1.50 (update price before reset is called)

        (,,,, uint96 ticBefore, uint256 topBefore) = clip.sales(1);
        assertEq(uint256(ticBefore), startTime);
        assertEq(topBefore, ray(5 ether)); // $4 spot + 25% buffer = $5 (wasn't affected by poke)
        
        hevm.warp(startTime + 3600 seconds);
        assertTrue(!try_redo(1));
        hevm.warp(startTime + 3601 seconds);
        assertTrue( try_redo(1));
        
        (,,,, uint96 ticAfter, uint256 topAfter) = clip.sales(1);
        assertEq(uint256(ticAfter), startTime + 3601 seconds);     // (now)
        assertEq(topAfter, ray(3.75 ether)); // $3 spot + 25% buffer = $5 (used most recent OSM price)
    }

    function testFail_stopped_auction_reset_tail() public {
        clip.setBreaker(2);

        auctionResetSetup(10 hours); // 10 hours till zero is reached (used to test tail) 

        pip.poke(bytes32(uint256(3 ether))); // Spot = $1.50 (update price before reset is called)

        (,,,, uint96 ticBefore, uint256 topBefore) = clip.sales(1);
        assertEq(uint256(ticBefore), startTime);
        assertEq(topBefore, ray(5 ether)); // $4 spot + 25% buffer = $5 (wasn't affected by poke)
        
        hevm.warp(startTime + 3600 seconds);
        assertTrue(!try_redo(1));
        hevm.warp(startTime + 3601 seconds);
        assertTrue( try_redo(1));
    }
}
