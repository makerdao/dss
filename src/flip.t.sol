pragma solidity ^0.4.24;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "./flip.sol";
import {Dai20} from './transferFrom.sol';

contract Guy {
    Flipper flip;
    constructor(Flipper flip_) public {
        flip = flip_;
    }
    function tend(uint id, uint lot, uint bid) public {
        flip.tend(id, lot, bid);
    }
    function dent(uint id, uint lot, uint bid) public {
        flip.dent(id, lot, bid);
    }
    function deal(uint id) public {
        flip.deal(id);
    }
    function try_tend(uint id, uint lot, uint bid)
        public returns (bool)
    {
        bytes4 sig = bytes4(keccak256("tend(uint256,uint256,uint256)"));
        return address(flip).call(sig, id, lot, bid);
    }
    function try_dent(uint id, uint lot, uint bid)
        public returns (bool)
    {
        bytes4 sig = bytes4(keccak256("dent(uint256,uint256,uint256)"));
        return address(flip).call(sig, id, lot, bid);
    }
    function try_deal(uint id)
        public returns (bool)
    {
        bytes4 sig = bytes4(keccak256("deal(uint256)"));
        return address(flip).call(sig, id);
    }
    function try_tick(uint id)
        public returns (bool)
    {
        bytes4 sig = bytes4(keccak256("tick(uint256)"));
        return address(flip).call(sig, id);
    }
}

contract Vat is VatLike {
    mapping (bytes32 => int)  public gems;
    mapping (bytes32 => uint) public dai;
    function slip(bytes32 ilk, bytes32 lad, int jam) public {
        gems[lad] += jam;
        ilk;
    }
    function flux(bytes32 ilk, bytes32 src, bytes32 dst, int jam) public {
        gems[src] -= jam;
        gems[dst] += jam;
        ilk;
    }
    uint256 constant ONE = 10 ** 27;
    function move(bytes32 src, bytes32 dst, uint rad) public {
        dai[src] -= rad;
        dai[dst] += rad;
    }
}

contract Gal {}

contract WarpFlip is Flipper {
    uint48 _era; function warp(uint48 era_) public { _era = era_; }
    function era() public view returns (uint48) { return _era; }
    constructor(address vat_, bytes32 ilk_) public
        Flipper(vat_, ilk_) {}
}

contract FlipTest is DSTest {
    WarpFlip flip;
    Dai20   pie;

    Guy  ali;
    Guy  bob;
    Gal  gal;
    Vat  vat;

    function setUp() public {
        vat = new Vat();
        pie = new Dai20(vat);
        flip = new WarpFlip(vat, 'fake ilk');

        flip.warp(1 hours);

        ali = new Guy(flip);
        bob = new Guy(flip);
        gal = new Gal();

        pie.approve(flip);

        pie.push(ali, 200 ether);
        pie.push(bob, 200 ether);
    }
    function test_kick() public {
        flip.kick({ lot: 100 ether
                  , tab: 50 ether
                  , lad: address(0xacab)
                  , gal: gal
                  , bid: 0
                  });
    }
    function testFail_tend_empty() public {
        // can't tend on non-existent
        flip.tend(42, 0, 0);
    }
    function test_tend() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , lad: address(0xacab)
                            , gal: gal
                            , bid: 0
                            });

        ali.tend(id, 100 ether, 1 ether);
        // bid taken from bidder
        assertEq(pie.balanceOf(ali),   199 ether);
        // gal receives payment
        assertEq(pie.balanceOf(gal),     1 ether);

        bob.tend(id, 100 ether, 2 ether);
        // bid taken from bidder
        assertEq(pie.balanceOf(bob), 198 ether);
        // prev bidder refunded
        assertEq(pie.balanceOf(ali), 200 ether);
        // gal receives excess
        assertEq(pie.balanceOf(gal),   2 ether);

        flip.warp(5 hours);
        bob.deal(id);
        // bob gets the winnings
        assertEq(vat.gems(bytes32(address(bob))), 100 ether);
    }
    function test_tend_later() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , lad: address(0xacab)
                            , gal: gal
                            , bid: 0
                            });
        flip.warp(5 hours);

        ali.tend(id, 100 ether, 1 ether);
        // bid taken from bidder
        assertEq(pie.balanceOf(ali), 199 ether);
        // gal receives payment
        assertEq(pie.balanceOf(gal),   1 ether);
    }
    function test_dent() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , lad: address(0xacab)
                            , gal: gal
                            , bid: 0
                            });
        ali.tend(id, 100 ether,  1 ether);
        bob.tend(id, 100 ether, 50 ether);

        ali.dent(id,  95 ether, 50 ether);
        // plop the gems
        assertEq(vat.gems(0xacab), 5 ether);
        assertEq(pie.balanceOf(ali),  150 ether);
        assertEq(pie.balanceOf(bob),  200 ether);
    }
    function test_beg() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , lad: address(0xacab)
                            , gal: gal
                            , bid: 0
                            });
        assertTrue( ali.try_tend(id, 100 ether, 1.00 ether));
        assertTrue(!bob.try_tend(id, 100 ether, 1.01 ether));
        // high bidder is subject to beg
        assertTrue(!ali.try_tend(id, 100 ether, 1.01 ether));
        assertTrue( bob.try_tend(id, 100 ether, 1.07 ether));

        // can bid by less than beg at flip
        assertTrue( ali.try_tend(id, 100 ether, 49 ether));
        assertTrue( bob.try_tend(id, 100 ether, 50 ether));

        assertTrue(!ali.try_dent(id, 100 ether, 50 ether));
        assertTrue(!ali.try_dent(id,  99 ether, 50 ether));
        assertTrue( ali.try_dent(id,  95 ether, 50 ether));
    }
    function test_deal() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , lad: address(0xacab)
                            , gal: gal
                            , bid: 0
                            });

        // only after ttl
        ali.tend(id, 100 ether, 1 ether);
        assertTrue(!bob.try_deal(id));
        flip.warp(4.1 hours);
        assertTrue( bob.try_deal(id));

        uint ie = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , lad: address(0xacab)
                            , gal: gal
                            , bid: 0
                            });

        // or after end
        flip.warp(1 weeks);
        ali.tend(ie, 100 ether, 1 ether);
        assertTrue(!bob.try_deal(ie));
        flip.warp(1.1 weeks);
        assertTrue( bob.try_deal(ie));
    }
    function test_tick() public {
        // start an auction
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , lad: address(0xacab)
                            , gal: gal
                            , bid: 0
                            });
        // check no tick
        assertTrue(!ali.try_tick(id));
        // run past the end
        flip.warp(2 weeks);
        // check not biddable
        assertTrue(!ali.try_tend(id, 100 ether, 1 ether));
        assertTrue(ali.try_tick(id));
        // check biddable
        assertTrue( ali.try_tend(id, 100 ether, 1 ether));
    }
}
