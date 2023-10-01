// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.12;

import "ds-test/test.sol";

import "../abaci.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

contract ClipperTest is DSTest {
    Hevm hevm;

    uint256 RAY = 10 ** 27;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    uint256 constant startTime = 604411200; // Used to avoid issues with `now`

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        hevm.warp(startTime);
    }

    function assertEqWithinTolerance(
        uint256 x,
        uint256 y,
        uint256 tolerance) internal {
            uint256 diff;
            if (x >= y) {
                diff = x - y;
            } else {
                diff = y - x;
            }
            assertTrue(diff <= tolerance);
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
        uint256 testPrice;

        hevm.warp(startTime);
        calc.file(bytes32("step"), step);
        calc.file(bytes32("cut"),  cut);
        price = calc.price(top, now - tic);
        assertEq(price, top);

        for(uint256 i = 1; i < testTime; i += 1) {
            hevm.warp(startTime + i);
            lastPrice = price;
            price = calc.price(top, now - tic);
            // Stairstep calculation
            if (i % step == 0) { testPrice = lastPrice * percentDecrease / RAY; }
            else               { testPrice = lastPrice; }
            assertEqWithinTolerance(testPrice, price, tolerance);
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
        percentDecrease = RAY - 1.1234567890E27 / 100;
        step = 1;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 2.1234567890% decrease every 1 second
        percentDecrease = RAY - 2.1234567890E27 / 100;
        step = 1;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 1.1234567890% decrease every 5 seconds
        percentDecrease = RAY - 1.1234567890E27 / 100;
        step = 5;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 2.1234567890% decrease every 5 seconds
        percentDecrease = RAY - 2.1234567890E27 / 100;
        step = 5;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 1.1234567890% decrease every 5 minutes
        percentDecrease = RAY - 1.1234567890E27 / 100;
        step = 5 minutes;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);


        /*** Extreme low collateral price ($0.0000001) ***/

        tolerance = 1; // Lowest tolerance is 1e-27
        top = 1 * RAY / 10000000;

        // 1.1234567890% decrease every 1 second
        percentDecrease = RAY - 1.1234567890E27 / 100;
        step = 1;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 2.1234567890% decrease every 1 second
        percentDecrease = RAY - 2.1234567890E27 / 100;
        step = 1;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 1.1234567890% decrease every 5 seconds
        percentDecrease = RAY - 1.1234567890E27 / 100;
        step = 5;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 2.1234567890% decrease every 5 seconds
        percentDecrease = RAY - 2.1234567890E27 / 100;
        step = 5;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);

        // 1.1234567890% decrease every 5 minutes
        percentDecrease = RAY - 1.1234567890E27 / 100;
        step = 5 minutes;
        checkExpDecrease(calc, percentDecrease, step, top, tic, percentDecrease, testTime, tolerance);
    }

    function test_continuous_exp_decrease() public {
        ExponentialDecrease calc = new ExponentialDecrease();
        uint256 tHalf = 900;
        uint256 cut = 0.999230132966E27;  // ~15 half life, cut ~= e^(ln(1/2)/900)
        calc.file("cut", cut);

        uint256 top = 4000 * RAY;
        uint256 expectedPrice = top;
        uint256 tolerance = RAY / 1000;  // 0.001, i.e 0.1%
        for (uint256 i = 0; i < 5; i++) {  // will cover initial value + four half-lives
            assertEqWithinTolerance(calc.price(top, i*tHalf), expectedPrice, tolerance);
            // each loop iteration advances one half-life, so expectedPrice decreases by a factor of 2
            expectedPrice /= 2;
        }
    }

    function test_linear_decrease() public {
        hevm.warp(startTime);
        LinearDecrease calc = new LinearDecrease();
        calc.file(bytes32("tau"), 3600);

        uint256 top = 1000 * RAY;
        uint256 tic = now; // Start of auction
        uint256 price = calc.price(top, now - tic);
        assertEq(price, top);

        hevm.warp(startTime + 360);                // 6min in,   1/10 done
        price = calc.price(top, now - tic);
        assertEq(price, (1000 - 100) * RAY);

        hevm.warp(startTime + 360 * 2);            // 12min in,  2/10 done
        price = calc.price(top, now - tic);
        assertEq(price, (1000 - 100 * 2) * RAY);

        hevm.warp(startTime + 360 * 3);            // 18min in,  3/10 done
        price = calc.price(top, now - tic);
        assertEq(price, (1000 - 100 * 3) * RAY);

        hevm.warp(startTime + 360 * 4);            // 24min in,  4/10 done
        price = calc.price(top, now - tic);
        assertEq(price, (1000 - 100 * 4) * RAY);

        hevm.warp(startTime + 360 * 5);            // 30min in,  5/10 done
        price = calc.price(top, now - tic);
        assertEq(price, (1000 - 100 * 5) * RAY);

        hevm.warp(startTime + 360 * 6);            // 36min in,  6/10 done
        price = calc.price(top, now - tic);
        assertEq(price, (1000 - 100 * 6) * RAY);

        hevm.warp(startTime + 360 * 7);            // 42min in,  7/10 done
        price = calc.price(top, now - tic);
        assertEq(price, (1000 - 100 * 7) * RAY);

        hevm.warp(startTime + 360 * 8);            // 48min in,  8/10 done
        price = calc.price(top, now - tic);
        assertEq(price, (1000 - 100 * 8) * RAY);

        hevm.warp(startTime + 360 * 9);            // 54min in,  9/10 done
        price = calc.price(top, now - tic);
        assertEq(price, (1000 - 100 * 9) * RAY);

        hevm.warp(startTime + 360 * 10);           // 60min in, 10/10 done
        price = calc.price(top, now - tic);
        assertEq(price, 0);
    }
}
