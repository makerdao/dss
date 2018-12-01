pragma solidity >=0.5.0;

import "ds-test/test.sol";
import {DSToken} from "ds-token/token.sol";

import {Flipper} from "./flip.sol";

contract Hevm {
    function warp(uint256) public;
}

contract Guy {
    Flipper flip;
    constructor(Flipper flip_) public {
        flip = flip_;
        DSToken(address(flip.dai())).approve(address(flip));
        DSToken(address(flip.gem())).approve(address(flip));
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
        public returns (bool ok)
    {
        string memory sig = "tend(uint256,uint256,uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_dent(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "dent(uint256,uint256,uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_deal(uint id)
        public returns (bool ok)
    {
        string memory sig = "deal(uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id));
    }
    function try_tick(uint id)
        public returns (bool ok)
    {
        string memory sig = "tick(uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id));
    }
}

contract Dai is DSToken('Dai') {}
contract Gem is DSToken('Gem') {
    function push(bytes32 guy, uint wad) public {
        push(address(bytes20(guy)), wad);
    }
}

contract Gal {}


contract FlipTest is DSTest {
    Hevm hevm;

    Flipper flip;

    Dai  dai;
    Gem  gem;

    address ali;
    address bob;
    address gal;
    bytes32 urn = bytes32(bytes20(address(0xacab)));

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(1 hours);

        dai = new Dai();
        gem = new Gem();

        flip = new Flipper(address(dai), address(gem));

        ali = address(new Guy(flip));
        bob = address(new Guy(flip));
        gal = address(new Gal());

        dai.approve(address(flip));
        gem.approve(address(flip));

        gem.mint(address(this), 1000 ether);

        dai.mint(ali, 200 ether);
        dai.mint(bob, 200 ether);
    }
    function test_kick() public {
        flip.kick({ lot: 100 ether
                  , tab: 50 ether
                  , urn: urn
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
                            , urn: urn
                            , gal: gal
                            , bid: 0
                            });

        Guy(ali).tend(id, 100 ether, 1 ether);
        // bid taken from bidder
        assertEq(dai.balanceOf(ali),   199 ether);
        // gal receives payment
        assertEq(dai.balanceOf(gal),     1 ether);

        Guy(bob).tend(id, 100 ether, 2 ether);
        // bid taken from bidder
        assertEq(dai.balanceOf(bob), 198 ether);
        // prev bidder refunded
        assertEq(dai.balanceOf(ali), 200 ether);
        // gal receives excess
        assertEq(dai.balanceOf(gal),   2 ether);

        hevm.warp(5 hours);
        Guy(bob).deal(id);
        // bob gets the winnings
        assertEq(gem.balanceOf(bob), 100 ether);
    }
    function test_tend_later() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , urn: urn
                            , gal: gal
                            , bid: 0
                            });
        hevm.warp(5 hours);

        Guy(ali).tend(id, 100 ether, 1 ether);
        // bid taken from bidder
        assertEq(dai.balanceOf(ali), 199 ether);
        // gal receives payment
        assertEq(dai.balanceOf(gal),   1 ether);
    }
    function test_dent() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , urn: urn
                            , gal: gal
                            , bid: 0
                            });
        Guy(ali).tend(id, 100 ether,  1 ether);
        Guy(bob).tend(id, 100 ether, 50 ether);

        Guy(ali).dent(id,  95 ether, 50 ether);
        // plop the gems
        assertEq(gem.balanceOf(address(0xacab)), 5 ether);
        assertEq(dai.balanceOf(ali),  150 ether);
        assertEq(dai.balanceOf(bob),  200 ether);
    }
    function test_beg() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , urn: urn
                            , gal: gal
                            , bid: 0
                            });
        assertTrue( Guy(ali).try_tend(id, 100 ether, 1.00 ether));
        assertTrue(!Guy(bob).try_tend(id, 100 ether, 1.01 ether));
        // high bidder is subject to beg
        assertTrue(!Guy(ali).try_tend(id, 100 ether, 1.01 ether));
        assertTrue( Guy(bob).try_tend(id, 100 ether, 1.07 ether));

        // can bid by less than beg at flip
        assertTrue( Guy(ali).try_tend(id, 100 ether, 49 ether));
        assertTrue( Guy(bob).try_tend(id, 100 ether, 50 ether));

        assertTrue(!Guy(ali).try_dent(id, 100 ether, 50 ether));
        assertTrue(!Guy(ali).try_dent(id,  99 ether, 50 ether));
        assertTrue( Guy(ali).try_dent(id,  95 ether, 50 ether));
    }
    function test_deal() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , urn: urn
                            , gal: gal
                            , bid: 0
                            });

        // only after ttl
        Guy(ali).tend(id, 100 ether, 1 ether);
        assertTrue(!Guy(bob).try_deal(id));
        hevm.warp(4.1 hours);
        assertTrue( Guy(bob).try_deal(id));

        uint ie = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , urn: urn
                            , gal: gal
                            , bid: 0
                            });

        // or after end
        hevm.warp(2 days);
        Guy(ali).tend(ie, 100 ether, 1 ether);
        assertTrue(!Guy(bob).try_deal(ie));
        hevm.warp(3 days);
        assertTrue( Guy(bob).try_deal(ie));
    }
    function test_tick() public {
        // start an auction
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , urn: urn
                            , gal: gal
                            , bid: 0
                            });
        // check no tick
        assertTrue(!Guy(ali).try_tick(id));
        // run past the end
        hevm.warp(2 weeks);
        // check not biddable
        assertTrue(!Guy(ali).try_tend(id, 100 ether, 1 ether));
        assertTrue( Guy(ali).try_tick(id));
        // check biddable
        assertTrue( Guy(ali).try_tend(id, 100 ether, 1 ether));
    }
    function test_no_deal_after_end() public {
        // if there are no bids and the auction ends, then it should not
        // be refundable to the creator. Rather, it ticks indefinitely.
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , urn: urn
                            , gal: gal
                            , bid: 0
                            });
        assertTrue(!Guy(ali).try_deal(id));
        hevm.warp(2 weeks);
        assertTrue(!Guy(ali).try_deal(id));
        assertTrue( Guy(ali).try_tick(id));
        assertTrue(!Guy(ali).try_deal(id));
    }
}
