pragma solidity >=0.5.0;

import {DSTest}  from "ds-test/test.sol";
import {DSToken} from "ds-token/token.sol";
import "../flop.sol";
import "../vat.sol";


contract Hevm {
    function warp(uint256) public;
}

contract Guy {
    Flopper fuss;
    constructor(Flopper fuss_) public {
        fuss = fuss_;
        Vat(address(fuss.vat())).hope(address(fuss));
        DSToken(address(fuss.gem())).approve(address(fuss));
    }
    function dent(uint id, uint lot, uint bid) public {
        fuss.dent(id, lot, bid);
    }
    function deal(uint id) public {
        fuss.deal(id);
    }
    function try_dent(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "dent(uint256,uint256,uint256)";
        (ok,) = address(fuss).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_deal(uint id)
        public returns (bool ok)
    {
        string memory sig = "deal(uint256)";
        (ok,) = address(fuss).call(abi.encodeWithSignature(sig, id));
    }
}

contract Gal {}

contract Vatish is DSToken('') {
    uint constant ONE = 10 ** 27;
    function move(address src, address dst, uint rad) public {
        super.move(src, dst, rad);
    }
    function hope(address usr) public {
         super.approve(usr);
    }
    function dai(address usr) public returns (uint) {
         return super.balanceOf(usr);
    }
}

contract FlopTest is DSTest {
    Hevm hevm;

    Flopper fuss;
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

        fuss = new Flopper(address(vat), address(gem));

        ali = address(new Guy(fuss));
        bob = address(new Guy(fuss));
        gal = address(new Gal());

        vat.hope(address(fuss));
        gem.approve(address(fuss));

        vat.suck(address(this), address(this), 1000 ether);

        vat.move(address(this), ali, 200 ether);
        vat.move(address(this), bob, 200 ether);
    }
    function test_kick() public {
        assertEq(vat.dai(address(this)), 600 ether);
        assertEq(gem.balanceOf(address(this)),   0 ether);
        fuss.kick({ lot: uint(-1)   // or whatever high starting value
                  , gal: gal
                  , bid: 0
                  });
        // no value transferred
        assertEq(vat.dai(address(this)), 600 ether);
        assertEq(gem.balanceOf(address(this)),   0 ether);
    }
    function test_dent() public {
        uint id = fuss.kick({ lot: uint(-1)   // or whatever high starting value
                            , gal: gal
                            , bid: 10 ether
                            });

        Guy(ali).dent(id, 100 ether, 10 ether);
        // bid taken from bidder
        assertEq(vat.dai(ali), 190 ether);
        // gal receives payment
        assertEq(vat.dai(gal),  10 ether);

        Guy(bob).dent(id, 80 ether, 10 ether);
        // bid taken from bidder
        assertEq(vat.dai(bob), 190 ether);
        // prev bidder refunded
        assertEq(vat.dai(ali), 200 ether);
        // gal receives no more
        assertEq(vat.dai(gal), 10 ether);

        hevm.warp(now + 5 weeks);
        assertEq(gem.totalSupply(),  0 ether);
        gem.setOwner(address(fuss));
        Guy(bob).deal(id);
        // gems minted on demand
        assertEq(gem.totalSupply(), 80 ether);
        // bob gets the winnings
        assertEq(gem.balanceOf(bob), 80 ether);
    }
}
