pragma solidity ^0.5.12;

import "ds-test/test.sol";

import "./DutchOven.sol";
import "./abaci.sol";

contract Hevm {
    function warp(uint256) public;
    function store(address,bytes32,bytes32) public;
}

contract DutchOvenTest is DSTest {
    Oven oven;
    Hevm hevm;

    uint256 MLN = 10 ** 6;
    uint256 BLN = 10 ** 9;
    uint256 WAD = 10 ** 18;
    uint256 RAY = 10 ** 27;
    uint256 RAD = 10 ** 45;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        oven = new Oven(address(0), address(0), bytes32("ilk"));
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

    function checkExpDecrease(
        StairstepExponentialDecrease calc, 
        uint cut, 
        uint step, 
        uint top, 
        uint tic, 
        uint percentDecrease,
        uint testTime,
        uint tolerance
    ) 
        public 
    {
        uint256 price;
        uint256 lastPrice;
        uint256 diff;
        uint256 testPrice;

        hevm.warp(0);
        calc.file(bytes32("step"), step);
        calc.file(bytes32("cut"),  cut);
        price = calc.price(top, tic);
        assertEq(price, top);

        for(uint256 i = 1; i < testTime; i += 1) {
            hevm.warp(i);
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
        hevm.warp(0);
        StairstepExponentialDecrease calc = new StairstepExponentialDecrease();
        uint256 tic = now; // Start of auction
        uint256 percentDecrease;
        uint256 step;
        uint256 testTime = 3600 seconds;


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
        hevm.warp(0);
        LinearDecrease calc = new LinearDecrease();
        calc.file(bytes32("tau"), 3600);

        uint256 top = 1000 * RAY;
        uint256 tic = now; // Start of auction
        uint256 price = calc.price(top, tic);
        assertEq(price, top);

        hevm.warp(360);                          // 6min in,   1/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100) * RAY);

        hevm.warp(360 * 2);                      // 12min in,  2/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 2) * RAY);

        hevm.warp(360 * 3);                      // 18min in,  3/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 3) * RAY);

        hevm.warp(360 * 4);                      // 24min in,  4/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 4) * RAY);

        hevm.warp(360 * 5);                      // 30min in,  5/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 5) * RAY);

        hevm.warp(360 * 6);                      // 36min in,  6/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 6) * RAY);

        hevm.warp(360 * 7);                      // 42min in,  7/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 7) * RAY);

        hevm.warp(360 * 8);                      // 48min in,  8/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 8) * RAY);

        hevm.warp(360 * 9);                      // 54min in,  9/10 done
        price = calc.price(top, tic);
        assertEq(price, (1000 - 100 * 9) * RAY);

        hevm.warp(360 * 10);                     // 60min in, 10/10 done
        price = calc.price(top, tic);
        assertEq(price, 0);
    }
}
