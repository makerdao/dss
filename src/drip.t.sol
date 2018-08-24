pragma solidity ^0.4.24;

import "ds-test/test.sol";

import "./drip.sol";
import "./tune.sol";

contract WarpDrip is Drip {
    constructor(address vat_) public Drip(vat_) {}
    uint48 _era; function warp(uint48 era_) public { _era = era_; }
    function era() public view returns (uint48) { return _era; }
}

contract DripTest is DSTest {
    Vat      vat;
    WarpDrip drip;

    function rad(uint wad_) internal pure returns (uint) {
        return wad_ * 10 ** 27;
    }
    function wad(uint rad_) internal pure returns (uint) {
        return rad_ / 10 ** 27;
    }
    function rho(bytes32 ilk) internal view returns (uint) {
        (bytes32 vow, uint tax, uint48 rho_) = drip.ilks(ilk); vow; tax;
        return uint(rho_);
    }
    function rate(bytes32 ilk) internal view returns (uint) {
        (uint rate_, uint Art) = vat.ilks(ilk); Art;
        return rate_;
    }

    function setUp() public {
        vat  = new Vat();
        drip = new WarpDrip(vat);
        vat.rely(drip);
        vat.init("i");
        vat.tune("i", "u", "v", "w", 0, 100 ether);
    }
    function test_drip_setup() public {
        assertEq(uint(drip.era()), 0);
        (uint _, uint Art) = vat.ilks("i"); _;
        assertEq(Art, 100 ether);
    }
    function test_drip_updates_rho() public {
        drip.file("i", "ali", 10 ** 27);
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
        drip.file("i", "ali", 10 ** 27);
        drip.warp(1);
        drip.drip("i");
        drip.file("i", "ali", 1000000564701133626865910626);  // 5% / day
    }
    function test_drip_0d() public {
        drip.file("i", "ali", 1000000564701133626865910626);  // 5% / day
        assertEq(vat.dai("ali"), rad(0 ether));
        drip.drip("i");
        assertEq(vat.dai("ali"), rad(0 ether));
    }
    function test_drip_1d() public {
        drip.file("i", "ali", 1000000564701133626865910626);  // 5% / day
        drip.warp(1 days);
        assertEq(wad(vat.dai("ali")), 0 ether);
        drip.drip("i");
        assertEq(wad(vat.dai("ali")), 5 ether);
    }
    function test_drip_2d() public {
        drip.file("i", "ali", 1000000564701133626865910626);  // 5% / day
        drip.warp(2 days);
        assertEq(wad(vat.dai("ali")), 0 ether);
        drip.drip("i");
        assertEq(wad(vat.dai("ali")), 10.25 ether);
    }
    function test_drip_3d() public {
        drip.file("i", "ali", 1000000564701133626865910626);  // 5% / day
        drip.warp(3 days);
        assertEq(wad(vat.dai("ali")), 0 ether);
        drip.drip("i");
        assertEq(wad(vat.dai("ali")), 15.7625 ether);
    }
    function test_drip_multi() public {
        drip.file("i", "ali", 1000000564701133626865910626);  // 5% / day
        drip.warp(1 days);
        drip.drip("i");
        assertEq(wad(vat.dai("ali")), 5 ether);
        drip.file("i", "ali", 1000001103127689513476993127);  // 10% / day
        drip.warp(2 days);
        drip.drip("i");
        assertEq(wad(vat.dai("ali")),  15.5 ether);
        assertEq(wad(vat.debt()),     115.5 ether);
        assertEq(rate("i") / 10 ** 9, 1.155 ether);
    }
}
