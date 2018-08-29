pragma solidity ^0.4.24;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "./flip.sol";
import {Dai20} from './transferFrom.sol';

contract Guy {
    Flipper flip;
    constructor(Flipper flip_) public {
        flip = flip_;
        DSToken(flip.dai()).approve(flip);
        DSToken(flip.gem()).approve(flip);
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

contract Vat is DSToken {
    mapping (bytes32 => uint) public gems;
    mapping (bytes32 => uint) public dai;
    uint256 constant ONE = 10 ** 27;
    function flux(bytes32 ilk, bytes32 src, bytes32 dst, int jam) public {
        gems[src] -= uint(jam) / ONE;
        gems[dst] += uint(jam) / ONE;
        ilk;
    }
    function move(bytes32 src, bytes32 dst, int rad) public {
        dai[src] -= uint(rad);
        dai[dst] += uint(rad);
    }
}

contract Dai is DSToken('Dai') {}
contract Gem is DSToken('Gem') {
    function push(bytes32 guy, uint wad) public {
        push(address(guy), wad);
    }
}

contract Gal {}

contract WarpFlip is Flipper {
    uint48 _era; function warp(uint48 era_) public { _era = era_; }
    function era() public view returns (uint48) { return _era; }
    constructor(address dai_, address gem_) public
        Flipper(dai_, gem_) {}
}

contract FlipTest is DSTest {
    WarpFlip flip;

    Dai  dai;
    Gem  gem;

    Guy  ali;
    Guy  bob;
    Gal  gal;
    Vat  vat;

    function setUp() public {
        dai = new Dai();
        gem = new Gem();

        flip = new WarpFlip(dai, gem);

        flip.warp(1 hours);

        ali = new Guy(flip);
        bob = new Guy(flip);
        gal = new Gal();

        dai.approve(flip);
        gem.approve(flip);

        gem.mint(this, 1000 ether);

        dai.mint(ali, 200 ether);
        dai.mint(bob, 200 ether);
    }
    function test_kick() public {
        flip.kick({ lot: 100 ether
                  , tab: 50 ether
                  , urn: bytes32(address(0xacab))
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
                            , urn: bytes32(address(0xacab))
                            , gal: gal
                            , bid: 0
                            });

        ali.tend(id, 100 ether, 1 ether);
        // bid taken from bidder
        assertEq(dai.balanceOf(ali),   199 ether);
        // gal receives payment
        assertEq(dai.balanceOf(gal),     1 ether);

        bob.tend(id, 100 ether, 2 ether);
        // bid taken from bidder
        assertEq(dai.balanceOf(bob), 198 ether);
        // prev bidder refunded
        assertEq(dai.balanceOf(ali), 200 ether);
        // gal receives excess
        assertEq(dai.balanceOf(gal),   2 ether);

        flip.warp(5 hours);
        bob.deal(id);
        // bob gets the winnings
        assertEq(gem.balanceOf(bob), 100 ether);
    }
    function test_tend_later() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , urn: bytes32(address(0xacab))
                            , gal: gal
                            , bid: 0
                            });
        flip.warp(5 hours);

        ali.tend(id, 100 ether, 1 ether);
        // bid taken from bidder
        assertEq(dai.balanceOf(ali), 199 ether);
        // gal receives payment
        assertEq(dai.balanceOf(gal),   1 ether);
    }
    function test_dent() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , urn: bytes32(address(0xacab))
                            , gal: gal
                            , bid: 0
                            });
        ali.tend(id, 100 ether,  1 ether);
        bob.tend(id, 100 ether, 50 ether);

        ali.dent(id,  95 ether, 50 ether);
        // plop the gems
        assertEq(gem.balanceOf(0xacab), 5 ether);
        assertEq(dai.balanceOf(ali),  150 ether);
        assertEq(dai.balanceOf(bob),  200 ether);
    }
    function test_beg() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , urn: bytes32(address(0xacab))
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
                            , urn: bytes32(address(0xacab))
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
                            , urn: bytes32(address(0xacab))
                            , gal: gal
                            , bid: 0
                            });

        // or after end
        flip.warp(2 days);
        ali.tend(ie, 100 ether, 1 ether);
        assertTrue(!bob.try_deal(ie));
        flip.warp(3 days);
        assertTrue( bob.try_deal(ie));
    }
    function test_tick() public {
        // start an auction
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , urn: bytes32(address(0xacab))
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
