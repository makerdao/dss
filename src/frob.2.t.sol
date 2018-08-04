pragma solidity ^0.4.24;

import "ds-test/test.sol";
import "ds-token/token.sol";

import {Lad} from './frob.sol';
import {Vat} from './tune.2.sol';
import {Vat as VatI} from './tune.sol';
import {Dai20} from './transferFrom.sol';
import {Adapter} from './join.sol';

contract Frob2Test is DSTest {
    VatI    vat;
    Lad     lad;
    Dai20   pie;
    DSToken gold;

    Adapter adapter;

    function try_frob(bytes32 ilk, int ink, int art) public returns(bool) {
        bytes4 sig = bytes4(keccak256("frob(bytes32,int256,int256)"));
        return address(lad).call(sig, ilk, ink, art);
    }

    function ray(int wad) internal pure returns (int) {
        return wad * 10 ** 9;
    }

    function setUp() public {
        vat = VatI(new Vat());
        lad = new Lad(vat);
        pie = new Dai20(vat);

        gold = new DSToken("GEM");
        gold.mint(1000 ether);

        vat.file("gold", "rate", int(ray(1 ether)));
        adapter = new Adapter(vat, "gold", gold);
        gold.approve(adapter);
        adapter.join(1000 ether);

        lad.file("gold", "spot", int(ray(1 ether)));
        lad.file("gold", "line", 1000 ether);
        lad.file("Line", 1000 ether);

        gold.approve(vat);
    }

    function gem(bytes32 ilk, address lad_) internal view returns (int) {
        (int gem_, int ink_, int art_) = vat.urns(ilk, lad_); gem_; ink_; art_;
        return gem_;
    }
    function ink(bytes32 ilk, address lad_) internal view returns (int) {
        (int gem_, int ink_, int art_) = vat.urns(ilk, lad_); gem_; ink_; art_;
        return ink_;
    }
    function art(bytes32 ilk, address lad_) internal view returns (int) {
        (int gem_, int ink_, int art_) = vat.urns(ilk, lad_); gem_; ink_; art_;
        return art_;
    }

    function test_join() public {
        gold.mint(500 ether);
        assertEq(gold.balanceOf(this),     500 ether);
        assertEq(gold.balanceOf(adapter), 1000 ether);
        adapter.join(500 ether);
        assertEq(gold.balanceOf(this),       0 ether);
        assertEq(gold.balanceOf(adapter), 1500 ether);
        adapter.exit(250 ether);
        assertEq(gold.balanceOf(this),     250 ether);
        assertEq(gold.balanceOf(adapter), 1250 ether);
    }
    function test_lock() public {
        assertEq(ink("gold", this),    0 ether);
        assertEq(gem("gold", this), 1000 ether);
        lad.frob("gold", 6 ether, 0);
        assertEq(ink("gold", this),   6 ether);
        assertEq(gem("gold", this), 994 ether);
        lad.frob("gold", -6 ether, 0);
        assertEq(ink("gold", this),    0 ether);
        assertEq(gem("gold", this), 1000 ether);
    }
    function test_calm() public {
        // calm means that the debt ceiling is not exceeded
        // it's ok to increase debt as long as you remain calm
        lad.file("gold", 'line', 10 ether);
        assertTrue( try_frob("gold", 10 ether, 9 ether));
        // only if under debt ceiling
        assertTrue(!try_frob("gold",  0 ether, 2 ether));
    }
    function test_cool() public {
        // cool means that the debt has decreased
        // it's ok to be over the debt ceiling as long as you're cool
        lad.file("gold", 'line', 10 ether);
        assertTrue(try_frob("gold", 10 ether,  8 ether));
        lad.file("gold", 'line', 5 ether);
        // can decrease debt when over ceiling
        assertTrue(try_frob("gold",  0 ether, -1 ether));
    }
    function test_safe() public {
        // safe means that the cdp is not risky
        // you can't frob a cdp into unsafe
        lad.frob("gold", 10 ether, 5 ether);                // safe draw
        assertTrue(!try_frob("gold", 0 ether, 6 ether));  // unsafe draw
    }
    function test_nice() public {
        // nice means that the collateral has increased or the debt has
        // decreased. remaining unsafe is ok as long as you're nice

        lad.frob("gold", 10 ether, 10 ether);
        lad.file("gold", 'spot', int(ray(0.5 ether)));  // now unsafe

        // debt can't increase if unsafe
        assertTrue(!try_frob("gold",  0 ether,  1 ether));
        // debt can decrease
        assertTrue( try_frob("gold",  0 ether, -1 ether));
        // ink can't decrease
        assertTrue(!try_frob("gold", -1 ether,  0 ether));
        // ink can increase
        assertTrue( try_frob("gold",  1 ether,  0 ether));

        // cdp is still unsafe
        // ink can't decrease, even if debt decreases more
        assertTrue(!this.try_frob("gold", -2 ether, -4 ether));
        // debt can't increase, even if ink increases more
        assertTrue(!this.try_frob("gold",  5 ether,  1 ether));

        // ink can decrease if end state is safe
        assertTrue( this.try_frob("gold", -1 ether, -4 ether));
        lad.file("gold", 'spot', int(ray(0.4 ether)));  // now unsafe
        // debt can increase if end state is safe
        assertTrue( this.try_frob("gold",  5 ether, 1 ether));
    }
}
