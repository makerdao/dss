pragma solidity >=0.5.0;

import "ds-test/test.sol";
import {DSToken} from "ds-token/token.sol";
import "../flap.sol";
import "../vat.sol";


contract Hevm {
    function warp(uint256) public;
}

contract Guy {
    Flapper fuss;
    constructor(Flapper fuss_) public {
        fuss = fuss_;
        Vat(address(fuss.vat())).hope(address(fuss));
        DSToken(address(fuss.gem())).approve(address(fuss));
    }
    function tend(uint id, uint lot, uint bid) public {
        fuss.tend(id, lot, bid);
    }
    function deal(uint id) public {
        fuss.deal(id);
    }
    function try_tend(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "tend(uint256,uint256,uint256)";
        (ok,) = address(fuss).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_deal(uint id)
        public returns (bool ok)
    {
        string memory sig = "deal(uint256)";
        (ok,) = address(fuss).call(abi.encodeWithSignature(sig, id));
    }
}

contract FlapTest is DSTest {
    Hevm hevm;

    Flapper fuss;
    address flap;
    Vat     vat;
    DSToken gem;

    address ali;
    address bob;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        vat = new Vat();
        gem = new DSToken('');

        fuss = new Flapper(address(vat), address(gem));
        flap = address(fuss);

        ali = address(new Guy(fuss));
        bob = address(new Guy(fuss));

        vat.hope(address(fuss));
        gem.approve(address(fuss));

        vat.suck(address(this), address(this), 1000 ether);

        gem.mint(1000 ether);
        gem.setOwner(flap);

        gem.push(ali, 200 ether);
        gem.push(bob, 200 ether);
    }
    function test_kick() public {
        assertEq(vat.dai(address(this)), 1000 ether);
        assertEq(vat.dai(address(fuss)),    0 ether);
        fuss.kick({ lot: 100 ether
                  , bid: 0
                  });
        assertEq(vat.dai(address(this)),  900 ether);
        assertEq(vat.dai(address(fuss)),  100 ether);
    }
    function test_tend() public {
        uint id = fuss.kick({ lot: 100 ether
                            , bid: 0
                            });
        // lot taken from creator
        assertEq(vat.dai(address(this)), 900 ether);

        Guy(ali).tend(id, 100 ether, 1 ether);
        // bid taken from bidder
        assertEq(gem.balanceOf(ali), 199 ether);
        // payment remains in auction
        assertEq(gem.balanceOf(flap),  1 ether);

        Guy(bob).tend(id, 100 ether, 2 ether);
        // bid taken from bidder
        assertEq(gem.balanceOf(bob), 198 ether);
        // prev bidder refunded
        assertEq(gem.balanceOf(ali), 200 ether);
        // excess remains in auction
        assertEq(gem.balanceOf(flap),   2 ether);

        hevm.warp(now + 5 weeks);
        Guy(bob).deal(id);
        // high bidder gets the lot
        assertEq(vat.dai(address(fuss)),  0 ether);
        assertEq(vat.dai(bob), 100 ether);
        // income is burned
        assertEq(gem.balanceOf(flap),   0 ether);
    }
    function test_beg() public {
        uint id = fuss.kick({ lot: 100 ether
                            , bid: 0
                            });
        assertTrue( Guy(ali).try_tend(id, 100 ether, 1.00 ether));
        assertTrue(!Guy(bob).try_tend(id, 100 ether, 1.01 ether));
        // high bidder is subject to beg
        assertTrue(!Guy(ali).try_tend(id, 100 ether, 1.01 ether));
        assertTrue( Guy(bob).try_tend(id, 100 ether, 1.07 ether));
    }
}
