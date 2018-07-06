pragma solidity ^0.4.24;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "./flop.sol";

contract Guy {
    Flopper fuss;
    constructor(Flopper fuss_) public {
        fuss = fuss_;
        DSToken(fuss.pie()).approve(fuss);
        DSToken(fuss.gem()).approve(fuss);
    }
    function dent(uint id, uint lot, uint bid) public {
        fuss.dent(id, lot, bid);
    }
    function deal(uint id) public {
        fuss.deal(id);
    }
    function try_dent(uint id, uint lot, uint bid)
        public returns (bool)
    {
        bytes4 sig = bytes4(keccak256("dent(uint256,uint256,uint256)"));
        return address(fuss).call(sig, id, lot, bid);
    }
    function try_deal(uint id)
        public returns (bool)
    {
        bytes4 sig = bytes4(keccak256("deal(uint256)"));
        return address(fuss).call(sig, id);
    }
}

contract Gal {}

contract WarpFlop is Flopper {
    uint48 _era; function warp(uint48 era_) public { _era = era_; }
    function era() public view returns (uint48) { return _era; }
    constructor(address pie_, address gem_) public Flopper(pie_, gem_) {}
}

contract FlopTest is DSTest {
    WarpFlop fuss;
    DSToken pie;
    DSToken gem;

    Guy  ali;
    Guy  bob;
    Gal  gal;

    function kiss(uint) public pure { }  // arbitrary callback

    function setUp() public {
        pie = new DSToken('pie');
        gem = new DSToken('gem');

        fuss = new WarpFlop(pie, gem);

        fuss.warp(1 hours);

        ali = new Guy(fuss);
        bob = new Guy(fuss);
        gal = new Gal();

        pie.approve(fuss);
        gem.approve(fuss);

        pie.mint(1000 ether);

        pie.push(ali, 200 ether);
        pie.push(bob, 200 ether);
    }
    function test_kick() public {
        assertEq(pie.balanceOf(this), 600 ether);
        assertEq(gem.balanceOf(this),   0 ether);
        fuss.kick({ lot: uint(-1)   // or whatever high starting value
                  , gal: gal
                  , bid: 0
                  });
        // no value transferred
        assertEq(pie.balanceOf(this), 600 ether);
        assertEq(gem.balanceOf(this),   0 ether);
    }
    function test_dent() public {
        uint id = fuss.kick({ lot: uint(-1)   // or whatever high starting value
                            , gal: gal
                            , bid: 10 ether
                            });

        ali.dent(id, 100 ether, 10 ether);
        // bid taken from bidder
        assertEq(pie.balanceOf(ali), 190 ether);
        // gal receives payment
        assertEq(pie.balanceOf(gal),  10 ether);

        bob.dent(id, 80 ether, 10 ether);
        // bid taken from bidder
        assertEq(pie.balanceOf(bob), 190 ether);
        // prev bidder refunded
        assertEq(pie.balanceOf(ali), 200 ether);
        // gal receives no more
        assertEq(pie.balanceOf(gal), 10 ether);

        fuss.warp(5 weeks);
        assertEq(gem.totalSupply(),  0 ether);
        gem.setOwner(fuss);
        bob.deal(id);
        // gems minted on demand
        assertEq(gem.totalSupply(), 80 ether);
        // bob gets the winnings
        assertEq(gem.balanceOf(bob), 80 ether);
    }
}
