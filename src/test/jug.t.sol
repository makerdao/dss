pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";

import {Jug} from "../jug.sol";
import {Vat} from "../vat.sol";


contract Hevm {
    function warp(uint256) public;
}

contract VatLike {
    function ilks(bytes32) public view returns (Vat.Ilk memory);
    function urns(bytes32,address) public view returns (Vat.Urn memory);
}

contract JugTest is DSTest {
    Hevm hevm;
    Jug drip;
    Vat  vat;

    function rad(uint wad_) internal pure returns (uint) {
        return wad_ * 10 ** 27;
    }
    function wad(uint rad_) internal pure returns (uint) {
        return rad_ / 10 ** 27;
    }
    function rho(bytes32 ilk) internal view returns (uint) {
        (uint duty, uint rho_) = drip.ilks(ilk); duty;
        return rho_;
    }
    function rate(bytes32 ilk) internal view returns (uint) {
        Vat.Ilk memory i = VatLike(address(vat)).ilks(ilk);
        return i.rate;
    }
    function line(bytes32 ilk) internal view returns (uint) {
        Vat.Ilk memory i = VatLike(address(vat)).ilks(ilk);
        return i.line;
    }

    address ali = address(bytes20("ali"));

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        vat  = new Vat();
        drip = new Jug(address(vat));
        vat.rely(address(drip));
        vat.init("i");

        draw("i", 100 ether);
    }
    function draw(bytes32 ilk, uint dai) internal {
        vat.file("Line", vat.Line() + rad(dai));
        vat.file(ilk, "line", line(ilk) + rad(dai));
        vat.file(ilk, "spot", 10 ** 27 * 10000 ether);
        address self = address(this);
        vat.slip(ilk, self,  10 ** 27 * 1 ether);
        vat.frob(ilk, self, self, self, int(1 ether), int(dai));
    }

    function test_drip_setup() public {
        hevm.warp(0);
        assertEq(uint(now), 0);
        hevm.warp(1);
        assertEq(uint(now), 1);
        hevm.warp(2);
        assertEq(uint(now), 2);
        Vat.Ilk memory i = VatLike(address(vat)).ilks("i");
        assertEq(i.Art, 100 ether);
    }
    function test_drip_updates_rho() public {
        drip.init("i");
        assertEq(rho("i"), now);

        drip.file("i", "duty", 10 ** 27);
        drip.drip("i");
        assertEq(rho("i"), now);
        hevm.warp(now + 1);
        assertEq(rho("i"), now - 1);
        drip.drip("i");
        assertEq(rho("i"), now);
        hevm.warp(now + 1 days);
        drip.drip("i");
        assertEq(rho("i"), now);
    }
    function test_drip_file() public {
        drip.init("i");
        drip.file("i", "duty", 10 ** 27);
        drip.drip("i");
        drip.file("i", "duty", 1000000564701133626865910626);  // 5% / day
    }
    function test_drip_0d() public {
        drip.init("i");
        drip.file("i", "duty", 1000000564701133626865910626);  // 5% / day
        assertEq(vat.dai(ali), rad(0 ether));
        drip.drip("i");
        assertEq(vat.dai(ali), rad(0 ether));
    }
    function test_drip_1d() public {
        drip.init("i");
        drip.file("vow", ali);

        drip.file("i", "duty", 1000000564701133626865910626);  // 5% / day
        hevm.warp(now + 1 days);
        assertEq(wad(vat.dai(ali)), 0 ether);
        drip.drip("i");
        assertEq(wad(vat.dai(ali)), 5 ether);
    }
    function test_drip_2d() public {
        drip.init("i");
        drip.file("vow", ali);
        drip.file("i", "duty", 1000000564701133626865910626);  // 5% / day

        hevm.warp(now + 2 days);
        assertEq(wad(vat.dai(ali)), 0 ether);
        drip.drip("i");
        assertEq(wad(vat.dai(ali)), 10.25 ether);
    }
    function test_drip_3d() public {
        drip.init("i");
        drip.file("vow", ali);

        drip.file("i", "duty", 1000000564701133626865910626);  // 5% / day
        hevm.warp(now + 3 days);
        assertEq(wad(vat.dai(ali)), 0 ether);
        drip.drip("i");
        assertEq(wad(vat.dai(ali)), 15.7625 ether);
    }
    function test_drip_negative_3d() public {
        drip.init("i");
        drip.file("vow", ali);

        drip.file("i", "duty", 999999706969857929985428567);  // -2.5% / day
        hevm.warp(now + 3 days);
        assertEq(wad(vat.dai(address(this))), 100 ether);
        vat.move(address(this), ali, rad(100 ether));
        assertEq(wad(vat.dai(ali)), 100 ether);
        drip.drip("i");
        assertEq(wad(vat.dai(ali)), 92.6859375 ether);
    }

    function test_drip_multi() public {
        drip.init("i");
        drip.file("vow", ali);

        drip.file("i", "duty", 1000000564701133626865910626);  // 5% / day
        hevm.warp(now + 1 days);
        drip.drip("i");
        assertEq(wad(vat.dai(ali)), 5 ether);
        drip.file("i", "duty", 1000001103127689513476993127);  // 10% / day
        hevm.warp(now + 1 days);
        drip.drip("i");
        assertEq(wad(vat.dai(ali)),  15.5 ether);
        assertEq(wad(vat.debt()),     115.5 ether);
        assertEq(rate("i") / 10 ** 9, 1.155 ether);
    }
    function test_drip_base() public {
        vat.init("j");
        draw("j", 100 ether);

        drip.init("i");
        drip.init("j");
        drip.file("vow", ali);

        drip.file("i", "duty", 1050000000000000000000000000);  // 5% / second
        drip.file("j", "duty", 1000000000000000000000000000);  // 0% / second
        drip.file("base",  uint(50000000000000000000000000)); // 5% / second
        hevm.warp(now + 1);
        drip.drip("i");
        assertEq(wad(vat.dai(ali)), 10 ether);
    }
}
