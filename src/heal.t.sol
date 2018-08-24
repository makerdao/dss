pragma solidity ^0.4.24;

import "ds-test/test.sol";

import {WarpFlop as Flop} from './flop.t.sol';
import {WarpFlap as Flap} from './flap.t.sol';
import {WarpVat  as Vat}  from './frob.t.sol';
import {Vow}              from './heal.sol';

contract Gem {
    mapping (address => uint256) public balanceOf;
    function mint(address guy, uint wad) public {
        balanceOf[guy] += wad;
    }
}

contract WarpVow is Vow {
    uint48 _era; function warp(uint48 era_) public { _era = era_; }
    function era() public view returns (uint48) { return _era; }
}

contract VowTest is DSTest {
    Vat      vat;
    WarpVow  vow;
    Flop     flop;
    Flap     flap;
    Gem      gov;

    function setUp() public {
        vat = new Vat();
        vow = new WarpVow();
        vat.rely(vow);
        gov = new Gem();

        flop = new Flop(vat, gov);
        flap = new Flap(vat, gov);
        vat.rely(flop);
        vat.rely(flap);

        vow.file("vat",  address(vat));
        vow.file("flop", address(flop));
        vow.file("flap", address(flap));
        vow.file("lump", uint256(100 ether));
    }

    function try_flog(uint48 era) internal returns (bool) {
        bytes4 sig = bytes4(keccak256("flog(uint48)"));
        return address(vow).call(sig, era);
    }
    function try_flop() internal returns (bool) {
        bytes4 sig = bytes4(keccak256("flop()"));
        return address(vow).call(sig);
    }
    function try_flap() internal returns (bool) {
        bytes4 sig = bytes4(keccak256("flap()"));
        return address(vow).call(sig);
    }
    function try_dent(uint id, uint lot, uint bid) internal returns (bool) {
        bytes4 sig = bytes4(keccak256("dent(uint256,uint256,uint256)"));
        return address(flop).call(sig, id, lot, bid);
    }

    uint256 constant ONE = 10 ** 27;
    function suck(address who, uint wad) internal {
        vow.fess(wad);
        vat.init('');
        vat.heal(bytes32(address(vow)), bytes32(who), -int(wad * ONE));
    }
    function flog(uint wad) internal {
        suck(address(0), wad);  // suck dai into the zero address
        vow.flog(vow.era());
    }

    function test_flog_wait() public {
        assertEq(vow.wait(), 0);
        vow.file('wait', uint(100 seconds));
        assertEq(vow.wait(), 100 seconds);

        uint48 tic = uint48(now);
        vow.fess(100 ether);
        assertTrue(!try_flog(tic) );
        vow.warp(tic + uint48(100 seconds));
        assertTrue( try_flog(tic) );
    }

    function test_no_reflop() public {
        flog(100 ether);
        assertTrue( try_flop() );
        assertTrue(!try_flop() );
    }

    function test_no_flop_pending_joy() public {
        flog(200 ether);

        vat.mint(vow, 100 ether);
        assertTrue(!try_flop() );

        vow.heal(100 ether);
        assertTrue( try_flop() );
    }

    function test_flap() public {
        vat.mint(vow, 100 ether);
        assertTrue( try_flap() );
    }

    function test_no_flap_pending_sin() public {
        vow.file("lump", uint256(0 ether));
        flog(100 ether);

        vat.mint(vow, 50 ether);
        assertTrue(!try_flap() );
    }
    function test_no_flap_nonzero_woe() public {
        vow.file("lump", uint256(0 ether));
        flog(100 ether);
        vat.mint(vow, 50 ether);
        assertTrue(!try_flap() );
    }
    function test_no_flap_pending_flop() public {
        flog(100 ether);
        vow.flop();

        vat.mint(vow, 100 ether);

        assertTrue(!try_flap() );
    }
    function test_no_flap_pending_kiss() public {
        flog(100 ether);
        uint id = vow.flop();

        vat.mint(this, 100 ether);
        flop.dent(id, 0 ether, 100 ether);

        assertTrue(!try_flap() );
    }

    function test_no_surplus_after_good_flop() public {
        flog(100 ether);
        uint id = vow.flop();
        vat.mint(this, 100 ether);

        flop.dent(id, 0 ether, 100 ether);  // flop succeeds..

        assertTrue(!try_flap() );
    }

    function test_multiple_flop_dents() public {
        flog(100 ether);
        uint id = vow.flop();

        vat.mint(this, 100 ether);
        assertTrue(try_dent(id, 2 ether,  100 ether));

        vat.mint(this, 100 ether);
        assertTrue(try_dent(id, 1 ether,  100 ether));
    }
}
