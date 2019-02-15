pragma solidity >=0.5.0;

import "ds-test/test.sol";
import "dss/vat.sol";
import './dsr.sol';

contract Hevm {
    function warp(uint256) public;
}

contract DSRTest is DSTest {
    Hevm hevm;

    Vat vat;
    Pot pot;

    bytes32 self;
    bytes32 potb;

    function rad(uint wad_) internal pure returns (uint) {
        return wad_ * 10 ** 27;
    }
    function wad(uint rad_) internal pure returns (uint) {
        return rad_ / 10 ** 27;
    }

    function b32(address a) internal pure returns (bytes32) {
        return bytes32(bytes20(a));
    }

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(0);

        vat = new Vat();
        pot = new Pot(address(vat));
        vat.rely(address(pot));
        self = b32(address(this));
        potb = b32(address(pot));

        pot.file("vow", "vow");

        vat.heal(self, self, -int(rad(100 ether)));
    }
    function test_save_0d() public {
        assertEq(vat.dai(self), rad(100 ether));

        pot.save(self, int(100 ether));
        assertEq(wad(vat.dai(self)),   0 ether);
        assertEq(pot.pie(self),      100 ether);

        pot.save(self, int(-100 ether));
        assertEq(wad(vat.dai(self)), 100 ether);
    }
    function test_save_1d() public {
        pot.save(self, int(100 ether));
        pot.file("dsr", uint(1000000564701133626865910626));  // 5% / day
        hevm.warp(1 days);
        pot.drip();
        assertEq(pot.pie(self), 100 ether);
        pot.save(self, int(-100 ether));
        assertEq(wad(vat.dai(self)), 105 ether);
    }
    function test_drip_multi() public {
        pot.save(self, int(100 ether));
        pot.file("dsr", uint(1000000564701133626865910626));  // 5% / day
        hevm.warp(1 days);
        pot.drip();
        assertEq(wad(vat.dai(potb)),   105 ether);
        pot.file("dsr", uint(1000001103127689513476993127));  // 10% / day
        hevm.warp(2 days);
        pot.drip();
        assertEq(wad(vat.sin("vow")), 15.5 ether);
        assertEq(wad(vat.dai(potb)), 115.5 ether);
        assertEq(pot.Pie(),          100   ether);
        assertEq(pot.chi() / 10 ** 9, 1.155 ether);
    }
    function test_save_multi() public {
        pot.save(self, int(100 ether));
        pot.file("dsr", uint(1000000564701133626865910626));  // 5% / day
        hevm.warp(1 days);
        pot.drip();
        pot.save(self, -int(50 ether));
        assertEq(wad(vat.dai(self)), 52.5 ether);
        assertEq(pot.Pie(),          50.0 ether);

        pot.file("dsr", uint(1000001103127689513476993127));  // 10% / day
        hevm.warp(2 days);
        pot.drip();
        pot.save(self, -int(50 ether));
        assertEq(wad(vat.dai(self)), 110.25 ether);
        assertEq(pot.Pie(),            0.00 ether);
    }
    function test_save_owned_guy() public {
        bytes32 guy = bytes32(uint(address(this)) * 2 ** (12 * 8) + uint96(1111));
        vat.heal(guy, guy, -int(rad(100 ether)));
        pot.save(guy, int(100 ether));
    }
    function testFail_save_not_owned_guy() public {
        bytes32 guy = b32(address(123));
        vat.heal(guy, guy, -int(rad(100 ether)));
        pot.save(guy, int(100 ether));
    }
}
