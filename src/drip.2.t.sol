pragma solidity ^0.4.24;

import "ds-test/test.sol";

import {Drip, DripI} from "./drip.2.sol";
import {Vat, VatI} from "./tune.2.sol";

contract WarpDripI is DripI {
    function era() external returns (uint48 _era);
    function warp(uint48 era_) external;
}

contract WarpDrip is Drip {
    constructor(address vat_) public Drip(vat_) {}
    function warp(uint48 era_) public {
      assembly { sstore(99, era_) }
    }
    function era() public view returns (uint48 _era) {
      assembly { _era := sload(99) }
    }
}

contract Drip2Test is DSTest {
    VatI      vat;
    WarpDripI drip;

    function rad(uint wad_) internal pure returns (uint) {
        return wad_ * 10 ** 27;
    }
    function wad(uint rad_) internal pure returns (uint) {
        return rad_ / 10 ** 27;
    }
    function rho(bytes32 ilk) internal view returns (uint) {
        (uint tax, uint48 rho_) = drip.ilks(ilk); tax;
        return uint(rho_);
    }
    function rate(bytes32 ilk) internal view returns (uint) {
        (uint t, uint r, uint I, uint A) = vat.ilks(ilk); t; A; I;
        return r;
    }

    function setUp() public {
        vat  = VatI(new Vat());
        drip = WarpDripI(new WarpDrip(vat));
        vat.rely(drip);
        vat.init("i");
        vat.tune("i", "u", "v", "w", 0, 100 ether);
    }
    function test_drip_setup() public {
        assertEq(uint(drip.era()), 0);
        (uint t, uint r, uint I, uint A) = vat.ilks("i"); t; r; I;
        assertEq(A, 100 ether);
    }
    function test_drip_updates_rho() public {
        drip.init("i");
        assertEq(rho("i"), 0);

        drip.file("i", "tax", 10 ** 27);
        drip.drip("i");
        assertEq(rho("i"), 0);
        drip.warp(1);
        assertEq(rho("i"), 0);
        drip.drip("i");
        assertEq(rho("i"), 1);
        drip.warp(1 days);
        drip.drip("i");
        assertEq(rho("i"), 1 days);
    }
    function test_drip_file() public {
        drip.init("i");
        drip.file("i", "tax", 10 ** 27);
        drip.warp(1);
        drip.drip("i");
        drip.file("i", "tax", 1000000564701133626865910626);  // 5% / day
    }
    function test_drip_0d() public {
        drip.init("i");
        drip.file("i", "tax", 1000000564701133626865910626);  // 5% / day
        assertEq(vat.dai("ali"), rad(0 ether));
        drip.drip("i");
        assertEq(vat.dai("ali"), rad(0 ether));
    }
    function test_drip_1d() public {
        drip.init("i");
        drip.file("vow", "ali");

        drip.file("i", "tax", 1000000564701133626865910626);  // 5% / day
        drip.warp(1 days);
        assertEq(wad(vat.dai("ali")), 0 ether);
        drip.drip("i");
        assertEq(wad(vat.dai("ali")), 5 ether);
    }
    function test_drip_2d() public {
        drip.init("i");
        drip.file("vow", "ali");
        drip.file("i", "tax", 1000000564701133626865910626);  // 5% / day

        drip.warp(2 days);
        assertEq(wad(vat.dai("ali")), 0 ether);
        drip.drip("i");
        assertEq(wad(vat.dai("ali")), 10.25 ether);
    }
    function test_drip_3d() public {
        drip.init("i");
        drip.file("vow", "ali");

        drip.file("i", "tax", 1000000564701133626865910626);  // 5% / day
        drip.warp(3 days);
        assertEq(wad(vat.dai("ali")), 0 ether);
        drip.drip("i");
        assertEq(wad(vat.dai("ali")), 15.7625 ether);
    }
    function test_drip_multi() public {
        drip.init("i");
        drip.file("vow", "ali");

        drip.file("i", "tax", 1000000564701133626865910626);  // 5% / day
        drip.warp(1 days);
        drip.drip("i");
        assertEq(wad(vat.dai("ali")), 5 ether);
        drip.file("i", "tax", 1000001103127689513476993127);  // 10% / day
        drip.warp(2 days);
        drip.drip("i");
        assertEq(wad(vat.dai("ali")),  15.5 ether);
        assertEq(wad(vat.debt()),     115.5 ether);
        assertEq(rate("i") / 10 ** 9, 1.155 ether);
    }
    function test_drip_repo() public {
        vat.init("j");
        vat.tune("j", "u", "v", "w", 0, 100 ether);

        drip.init("i");
        drip.init("j");
        drip.file("vow", "ali");

        drip.file("i", "tax", 1050000000000000000000000000);  // 5% / second
        drip.file("j", "tax", 1000000000000000000000000000);  // 0% / second
        drip.file("repo",  uint(50000000000000000000000000)); // 5% / second
        drip.warp(1);
        drip.drip("i");
        assertEq(wad(vat.dai("ali")), 10 ether);
    }
}
