// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.12;

import "ds-test/test.sol";

import {Flopper as Flop} from './flop.t.sol';
import {Flapper as Flap} from './flap.t.sol';
import {TestVat as  Vat} from './vat.t.sol';
import {Vow}     from '../vow.sol';
import {Bow}     from '../bow.sol';

interface Hevm {
    function warp(uint256) external;
}

contract Gem {
    mapping (address => uint256) public balanceOf;
    function mint(address usr, uint rad) public {
        balanceOf[usr] += rad;
    }
}

contract BowTest is DSTest {
    Hevm hevm;

    Vat  vat;
    Vow  vow;
    Bow  bow;
    Flop flop;
    Flap flap;
    Gem  gov;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        vat = new Vat();

        gov  = new Gem();
        flop = new Flop(address(vat), address(gov));
        flap = new Flap(address(vat), address(gov));

        vow = new Vow(address(vat));
        bow = new Bow(address(vat), address(vow), address(flap), address(flop));
        vow.hope(address(bow));
        flap.rely(address(bow));
        flop.rely(address(bow));

        bow.file("bump", rad(100 ether));
        bow.file("sump", rad(100 ether));
        bow.file("dump", 200 ether);

        vat.hope(address(flop));
    }

    function try_flog(uint era) internal returns (bool ok) {
        string memory sig = "flog(uint256)";
        (ok,) = address(bow).call(abi.encodeWithSignature(sig, era));
    }
    function try_dent(uint id, uint lot, uint bid) internal returns (bool ok) {
        string memory sig = "dent(uint256,uint256,uint256)";
        (ok,) = address(flop).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_call(address addr, bytes calldata data) external returns (bool) {
        bytes memory _data = data;
        assembly {
            let ok := call(gas(), addr, 0, add(_data, 0x20), mload(_data), 0, 0)
            let free := mload(0x40)
            mstore(free, ok)
            mstore(0x40, add(free, 32))
            revert(free, 32)
        }
    }
    function can_flap() public returns (bool) {
        string memory sig = "flap()";
        bytes memory data = abi.encodeWithSignature(sig);

        bytes memory can_call = abi.encodeWithSignature("try_call(address,bytes)", bow, data);
        (bool ok, bytes memory success) = address(this).call(can_call);

        ok = abi.decode(success, (bool));
        if (ok) return true;
    }
    function can_flop() public returns (bool) {
        string memory sig = "flop()";
        bytes memory data = abi.encodeWithSignature(sig);

        bytes memory can_call = abi.encodeWithSignature("try_call(address,bytes)", bow, data);
        (bool ok, bytes memory success) = address(this).call(can_call);

        ok = abi.decode(success, (bool));
        if (ok) return true;
    }

    uint constant ONE = 10 ** 27;
    function rad(uint wad) internal pure returns (uint) {
        return wad * ONE;
    }

    function suck(address who, uint wad) internal {
        bow.fess(rad(wad));
        vat.init('');
        vat.suck(address(vow), who, rad(wad));
    }
    function flog(uint wad) internal {
        suck(address(0), wad);  // suck dai into the zero address
        bow.flog(now);
    }
    function heal(uint wad) internal {
        vow.heal(rad(wad));
    }

    function test_change_flap_flop() public {
        Flap newFlap = new Flap(address(vat), address(gov));
        Flop newFlop = new Flop(address(vat), address(gov));

        newFlap.rely(address(bow));
        newFlop.rely(address(bow));

        assertEq(vat.can(address(bow), address(flap)), 1);
        assertEq(vat.can(address(bow), address(newFlap)), 0);

        bow.file('flapper', address(newFlap));
        bow.file('flopper', address(newFlop));

        assertEq(address(bow.flapper()), address(newFlap));
        assertEq(address(bow.flopper()), address(newFlop));

        assertEq(vat.can(address(bow), address(flap)), 0);
        assertEq(vat.can(address(bow), address(newFlap)), 1);
    }

    function test_flog_wait() public {
        assertEq(bow.wait(), 0);
        bow.file('wait', uint(100 seconds));
        assertEq(bow.wait(), 100 seconds);

        uint tic = now;                                                                                                                                                       
        bow.fess(100 ether);                                                     
        hevm.warp(tic + 99 seconds);                                             
        assertTrue(!try_flog(tic) );                                             
        hevm.warp(tic + 100 seconds);                                            
        assertTrue( try_flog(tic) ); 
    }

    function test_no_reflop() public {
        flog(100 ether);
        assertTrue( can_flop() );
        bow.flop();
        assertTrue(!can_flop() );
    }

    function test_no_flop_pending_joy() public {
        flog(200 ether);

        vat.mint(address(vow), 100 ether);
        assertTrue(!can_flop() );

        heal(100 ether);
        assertTrue( can_flop() );
    }

    function test_flap() public {
        vat.mint(address(vow), 100 ether);
        assertTrue( can_flap() );
    }

    function test_no_flap_pending_sin() public {
        bow.file("bump", uint256(0 ether));
        flog(100 ether);

        vat.mint(address(vow), 50 ether);
        assertTrue(!can_flap() );
    }
    function test_no_flap_nonzero_woe() public {
        bow.file("bump", uint256(0 ether));
        flog(100 ether);
        vat.mint(address(vow), 50 ether);
        assertTrue(!can_flap() );
    }
    function test_no_flap_pending_flop() public {
        flog(100 ether);
        bow.flop();

        vat.mint(address(vow), 100 ether);

        assertTrue(!can_flap() );
    }
    function test_no_flap_pending_heal() public {
        flog(100 ether);
        uint id = bow.flop();

        vat.mint(address(this), 100 ether);
        flop.dent(id, 0 ether, rad(100 ether));

        assertTrue(!can_flap() );
    }

    function test_no_surplus_after_good_flop() public {
        flog(100 ether);
        uint id = bow.flop();
        vat.mint(address(this), 100 ether);

        flop.dent(id, 0 ether, rad(100 ether));  // flop succeeds..

        assertTrue(!can_flap() );
    }

    function test_multiple_flop_dents() public {
        flog(100 ether);
        uint id = bow.flop();

        vat.mint(address(this), 100 ether);
        assertTrue(try_dent(id, 2 ether,  rad(100 ether)));

        vat.mint(address(this), 100 ether);
        assertTrue(try_dent(id, 1 ether,  rad(100 ether)));
    }
}
