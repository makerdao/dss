pragma solidity >=0.5.0;

import "ds-test/test.sol";

import {Flopper as Flop} from './flop.t.sol';
import {Flapper as Flap} from './flap.t.sol';
import {TestVat  as Vat} from './vat.t.sol';
import {DaiMove} from './move.sol';
import {Vow}     from './vow.sol';

contract Hevm {
    function warp(uint256) public;
}

contract Gem {
    mapping (address => uint256) public balanceOf;
    function mint(address guy, uint wad) public {
        balanceOf[guy] += wad;
    }
}

contract VowTest is DSTest {
    Hevm hevm;

    Vat  vat;
    Vow  vow;
    Flop flop;
    Flap flap;
    Gem  gov;

    DaiMove daiM;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(0);

        vat = new Vat();
        vow = new Vow();
        vat.rely(address(vow));
        gov  = new Gem();
        daiM = new DaiMove(address(vat));

        flop = new Flop(address(daiM), address(gov));
        flap = new Flap(address(daiM), address(gov));
        daiM.hope(address(flop));
        vat.rely(address(daiM));
        vat.rely(address(flop));
        vat.rely(address(flap));
        flop.rely(address(vow));

        vow.file("vat",  address(vat));
        vow.file("flop", address(flop));
        vow.file("flap", address(flap));
        vow.file("bump", uint256(100 ether));
        vow.file("sump", uint256(100 ether));
    }

    function try_flog(uint48 era) internal returns (bool ok) {
        string memory sig = "flog(uint48)";
        (ok,) = address(vow).call(abi.encodeWithSignature(sig, era));
    }
    function try_flop() internal returns (bool ok) {
        string memory sig = "flop()";
        (ok,) = address(vow).call(abi.encodeWithSignature(sig));
    }
    function try_flap() internal returns (bool ok) {
        string memory sig = "flap()";
        (ok,) = address(vow).call(abi.encodeWithSignature(sig));
    }
    function try_dent(uint id, uint lot, uint bid) internal returns (bool ok) {
        string memory sig = "dent(uint256,uint256,uint256)";
        (ok,) = address(flop).call(abi.encodeWithSignature(sig, id, lot, bid));
    }

    uint256 constant ONE = 10 ** 27;
    function suck(address who, uint wad) internal {
        vow.fess(wad);
        vat.init('');
        vat.heal(bytes32(bytes20(address(vow))), bytes32(bytes20(who)), -int(wad * ONE));
    }
    function flog(uint wad) internal {
        suck(address(0), wad);  // suck dai into the zero address
        vow.flog(uint48(now));
    }

    function test_flog_wait() public {
        assertEq(vow.wait(), 0);
        vow.file('wait', uint(100 seconds));
        assertEq(vow.wait(), 100 seconds);

        uint48 tic = uint48(now);
        vow.fess(100 ether);
        assertTrue(!try_flog(tic) );
        hevm.warp(tic + uint48(100 seconds));
        assertTrue( try_flog(tic) );
    }

    function test_no_reflop() public {
        flog(100 ether);
        assertTrue( try_flop() );
        assertTrue(!try_flop() );
    }

    function test_no_flop_pending_joy() public {
        flog(200 ether);

        vat.mint(address(vow), 100 ether);
        assertTrue(!try_flop() );

        vow.heal(100 ether);
        assertTrue( try_flop() );
    }

    function test_flap() public {
        vat.mint(address(vow), 100 ether);
        assertTrue( try_flap() );
    }

    function test_no_flap_pending_sin() public {
        vow.file("bump", uint256(0 ether));
        flog(100 ether);

        vat.mint(address(vow), 50 ether);
        assertTrue(!try_flap() );
    }
    function test_no_flap_nonzero_woe() public {
        vow.file("bump", uint256(0 ether));
        flog(100 ether);
        vat.mint(address(vow), 50 ether);
        assertTrue(!try_flap() );
    }
    function test_no_flap_pending_flop() public {
        flog(100 ether);
        vow.flop();

        vat.mint(address(vow), 100 ether);

        assertTrue(!try_flap() );
    }
    function test_no_flap_pending_kiss() public {
        flog(100 ether);
        uint id = vow.flop();

        vat.mint(address(this), 100 ether);
        flop.dent(id, 0 ether, 100 ether);

        assertTrue(!try_flap() );
    }

    function test_no_surplus_after_good_flop() public {
        flog(100 ether);
        uint id = vow.flop();
        vat.mint(address(this), 100 ether);

        flop.dent(id, 0 ether, 100 ether);  // flop succeeds..

        assertTrue(!try_flap() );
    }

    function test_multiple_flop_dents() public {
        flog(100 ether);
        uint id = vow.flop();

        vat.mint(address(this), 100 ether);
        assertTrue(try_dent(id, 2 ether,  100 ether));

        vat.mint(address(this), 100 ether);
        assertTrue(try_dent(id, 1 ether,  100 ether));
    }
}
