pragma solidity >=0.5.12;

import {DSTest}  from "ds-test/test.sol";
import {DSToken} from "ds-token/token.sol";
import "../flop.sol";
import "../vat.sol";


interface Hevm {
    function warp(uint256) external;
}

contract Guy {
    Flopper flop;
    constructor(Flopper flop_) public {
        flop = flop_;
        Vat(address(flop.vat())).hope(address(flop));
        DSToken(address(flop.gem())).approve(address(flop));
    }
    function dent(uint id, uint lot, uint bid) public {
        flop.dent(id, lot, bid);
    }
    function deal(uint id) public {
        flop.deal(id);
    }
    function try_dent(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "dent(uint256,uint256,uint256)";
        (ok,) = address(flop).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_deal(uint id)
        public returns (bool ok)
    {
        string memory sig = "deal(uint256)";
        (ok,) = address(flop).call(abi.encodeWithSignature(sig, id));
    }
    function try_tick(uint id)
        public returns (bool ok)
    {
        string memory sig = "tick(uint256)";
        (ok,) = address(flop).call(abi.encodeWithSignature(sig, id));
    }
}

contract Gal {
    uint public Ash;
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function kick(Flopper flop, uint lot, uint bid) external returns (uint) {
        Ash += bid;
        return flop.kick(address(this), lot, bid);
    }
    function kiss(uint rad) external {
        Ash = sub(Ash, rad);
    }
    function cage(Flopper flop) external {
        flop.cage();
    }
}

contract Vatish is DSToken('') {
    uint constant ONE = 10 ** 27;
    function hope(address usr) public {
         approve(usr, uint(-1));
    }
    function dai(address usr) public view returns (uint) {
         return balanceOf[usr];
    }
}

contract FlopTest is DSTest {
    Hevm hevm;

    Flopper flop;
    Vat     vat;
    DSToken gem;

    address ali;
    address bob;
    address gal;

    function kiss(uint) public pure { }  // arbitrary callback

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        vat = new Vat();
        gem = new DSToken('');

        flop = new Flopper(address(vat), address(gem));

        ali = address(new Guy(flop));
        bob = address(new Guy(flop));
        gal = address(new Gal());

        flop.rely(gal);
        flop.deny(address(this));

        vat.hope(address(flop));
        vat.rely(address(flop));
        gem.approve(address(flop));

        vat.suck(address(this), address(this), 1000 ether);

        vat.move(address(this), ali, 200 ether);
        vat.move(address(this), bob, 200 ether);
    }

    function test_kick() public {
        assertEq(vat.dai(gal), 0);
        assertEq(gem.balanceOf(gal), 0 ether);
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 5000 ether);
        // no value transferred
        assertEq(vat.dai(gal), 0);
        assertEq(gem.balanceOf(gal), 0 ether);
        // auction created with appropriate values
        assertEq(flop.kicks(), id);
        (uint256 bid, uint256 lot, address guy, uint48 tic, uint48 end) = flop.bids(id);
        assertEq(bid, 5000 ether);
        assertEq(lot, 200 ether);
        assertTrue(guy == gal);
        assertEq(uint256(tic), 0);
        assertEq(uint256(end), now + flop.tau());
    }

    function test_dent() public {
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 10 ether);

        Guy(ali).dent(id, 100 ether, 10 ether);
        // bid taken from bidder
        assertEq(vat.dai(ali), 190 ether);
        // gal receives payment
        assertEq(vat.dai(gal),  10 ether);
        assertEq(Gal(gal).Ash(), 0 ether);

        Guy(bob).dent(id, 80 ether, 10 ether);
        // bid taken from bidder
        assertEq(vat.dai(bob), 190 ether);
        // prev bidder refunded
        assertEq(vat.dai(ali), 200 ether);
        // gal receives no more
        assertEq(vat.dai(gal), 10 ether);

        hevm.warp(now + 5 weeks);
        assertEq(gem.totalSupply(),  0 ether);
        gem.setOwner(address(flop));
        Guy(bob).deal(id);
        // gems minted on demand
        assertEq(gem.totalSupply(), 80 ether);
        // bob gets the winnings
        assertEq(gem.balanceOf(bob), 80 ether);
    }

    function test_dent_Ash_less_than_bid() public {
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 10 ether);
        assertEq(vat.dai(gal),  0 ether);

        Gal(gal).kiss(1 ether);
        assertEq(Gal(gal).Ash(), 9 ether);

        Guy(ali).dent(id, 100 ether, 10 ether);
        // bid taken from bidder
        assertEq(vat.dai(ali), 190 ether);
        // gal receives payment
        assertEq(vat.dai(gal),   10 ether);
        assertEq(Gal(gal).Ash(), 0 ether);

        Guy(bob).dent(id, 80 ether, 10 ether);
        // bid taken from bidder
        assertEq(vat.dai(bob), 190 ether);
        // prev bidder refunded
        assertEq(vat.dai(ali), 200 ether);
        // gal receives no more
        assertEq(vat.dai(gal), 10 ether);

        hevm.warp(now + 5 weeks);
        assertEq(gem.totalSupply(),  0 ether);
        gem.setOwner(address(flop));
        Guy(bob).deal(id);
        // gems minted on demand
        assertEq(gem.totalSupply(), 80 ether);
        // bob gets the winnings
        assertEq(gem.balanceOf(bob), 80 ether);
    }

    function test_dent_same_bidder() public {
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 200 ether);

        Guy(ali).dent(id, 100 ether, 200 ether);
        assertEq(vat.dai(ali), 0);
        Guy(ali).dent(id, 50 ether, 200 ether);
    }

    function test_tick() public {
        // start an auction
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 10 ether);
        // check no tick
        assertTrue(!Guy(ali).try_tick(id));
        // run past the end
        hevm.warp(now + 2 weeks);
        // check not biddable
        assertTrue(!Guy(ali).try_dent(id, 100 ether, 10 ether));
        assertTrue( Guy(ali).try_tick(id));
        // check biddable
        (, uint _lot,,,) = flop.bids(id);
        // tick should increase the lot by pad (50%) and restart the auction
        assertEq(_lot, 300 ether);
        assertTrue( Guy(ali).try_dent(id, 100 ether, 10 ether));
    }

    function test_no_deal_after_end() public {
        // if there are no bids and the auction ends, then it should not
        // be refundable to the creator. Rather, it ticks indefinitely.
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 10 ether);
        assertTrue(!Guy(ali).try_deal(id));
        hevm.warp(now + 2 weeks);
        assertTrue(!Guy(ali).try_deal(id));
        assertTrue( Guy(ali).try_tick(id));
        assertTrue(!Guy(ali).try_deal(id));
    }

    function test_yank() public {
        // yanking the auction should refund the last bidder's dai, credit a
        // corresponding amount of sin to the caller of cage, and delete the auction.
        // in practice, gal == (caller of cage) == (vow address)
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 10 ether);

        // confrim initial state expectations
        assertEq(vat.dai(ali), 200 ether);
        assertEq(vat.dai(bob), 200 ether);
        assertEq(vat.dai(gal), 0);
        assertEq(vat.sin(gal), 0);

        Guy(ali).dent(id, 100 ether, 10 ether);
        Guy(bob).dent(id, 80 ether, 10 ether);

        // confirm the proper state updates have occurred
        assertEq(vat.dai(ali), 200 ether);  // ali's dai balance is unchanged
        assertEq(vat.dai(bob), 190 ether);
        assertEq(vat.dai(gal),  10 ether);
        assertEq(vat.sin(address(this)), 1000 ether);

        Gal(gal).cage(flop);
        flop.yank(id);

        // confirm final state
        assertEq(vat.dai(ali), 200 ether);
        assertEq(vat.dai(bob), 200 ether);  // bob's bid has been refunded
        assertEq(vat.dai(gal),  10 ether);
        assertEq(vat.sin(gal),  10 ether);  // sin assigned to caller of cage()
        (uint256 _bid, uint256 _lot, address _guy, uint48 _tic, uint48 _end) = flop.bids(id);
        assertEq(_bid, 0);
        assertEq(_lot, 0);
        assertEq(_guy, address(0));
        assertEq(uint256(_tic), 0);
        assertEq(uint256(_end), 0);
    }

    function test_yank_no_bids() public {
        // with no bidder to refund, yanking the auction should simply create equal
        // amounts of dai (credited to the gal) and sin (credited to the caller of cage)
        // in practice, gal == (caller of cage) == (vow address)
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 10 ether);

        // confrim initial state expectations
        assertEq(vat.dai(ali), 200 ether);
        assertEq(vat.dai(bob), 200 ether);
        assertEq(vat.dai(gal), 0);
        assertEq(vat.sin(gal), 0);

        Gal(gal).cage(flop);
        flop.yank(id);

        // confirm final state
        assertEq(vat.dai(ali), 200 ether);
        assertEq(vat.dai(bob), 200 ether);
        assertEq(vat.dai(gal),  10 ether);
        assertEq(vat.sin(gal),  10 ether);  // sin assigned to caller of cage()
        (uint256 _bid, uint256 _lot, address _guy, uint48 _tic, uint48 _end) = flop.bids(id);
        assertEq(_bid, 0);
        assertEq(_lot, 0);
        assertEq(_guy, address(0));
        assertEq(uint256(_tic), 0);
        assertEq(uint256(_end), 0);
    }
}
