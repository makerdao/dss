pragma solidity ^0.4.24;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "./flap.sol";

contract Guy {
    Flapper fuss;
    constructor(Flapper fuss_) public {
        fuss = fuss_;
        DSToken(fuss.dai()).approve(fuss);
        DSToken(fuss.gem()).approve(fuss);
    }
    function tend(uint id, uint lot, uint bid) public {
        fuss.tend(id, lot, bid);
    }
    function deal(uint id) public {
        fuss.deal(id);
    }
    function try_tend(uint id, uint lot, uint bid)
        public returns (bool)
    {
        bytes4 sig = bytes4(keccak256("tend(uint256,uint256,uint256)"));
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

contract WarpFlap is Flapper {
    uint48 _era; function warp(uint48 era_) public { _era = era_; }
    function era() public view returns (uint48) { return _era; }
    constructor(address dai_, address gem_) public Flapper(dai_, gem_) {}
}

contract VatLike is DSToken('') {
    uint constant ONE = 10 ** 27;
    function move(bytes32 src, bytes32 dst, int wad) public {
        move(address(src), address(dst), uint(wad) / ONE);
    }
}

contract FlapTest is DSTest {
    WarpFlap fuss;
    VatLike dai;
    DSToken gem;

    Guy  ali;
    Guy  bob;
    Gal  gal;

    function setUp() public {
        dai = new VatLike();
        gem = new DSToken('');

        fuss = new WarpFlap(dai, gem);

        fuss.warp(1 hours);

        ali = new Guy(fuss);
        bob = new Guy(fuss);
        gal = new Gal();

        dai.approve(fuss);
        gem.approve(fuss);

        dai.mint(1000 ether);
        gem.mint(1000 ether);

        gem.push(ali, 200 ether);
        gem.push(bob, 200 ether);
    }
    function test_kick() public {
        assertEq(dai.balanceOf(this), 1000 ether);
        assertEq(dai.balanceOf(fuss),    0 ether);
        fuss.kick({ lot: 100 ether
                  , gal: gal
                  , bid: 0
                  });
        assertEq(dai.balanceOf(this),  900 ether);
        assertEq(dai.balanceOf(fuss),  100 ether);
    }
    function test_tend() public {
        uint id = fuss.kick({ lot: 100 ether
                            , gal: gal
                            , bid: 0
                            });
        // lot taken from creator
        assertEq(dai.balanceOf(this), 900 ether);

        ali.tend(id, 100 ether, 1 ether);
        // bid taken from bidder
        assertEq(gem.balanceOf(ali), 199 ether);
        // gal receives payment
        assertEq(gem.balanceOf(gal),   1 ether);

        bob.tend(id, 100 ether, 2 ether);
        // bid taken from bidder
        assertEq(gem.balanceOf(bob), 198 ether);
        // prev bidder refunded
        assertEq(gem.balanceOf(ali), 200 ether);
        // gal receives excess
        assertEq(gem.balanceOf(gal),   2 ether);

        fuss.warp(5 weeks);
        bob.deal(id);
        // bob gets the winnings
        assertEq(dai.balanceOf(fuss),  0 ether);
        assertEq(dai.balanceOf(bob), 100 ether);
    }
    function test_beg() public {
        uint id = fuss.kick({ lot: 100 ether
                            , gal: gal
                            , bid: 0
                            });
        assertTrue( ali.try_tend(id, 100 ether, 1.00 ether));
        assertTrue(!bob.try_tend(id, 100 ether, 1.01 ether));
        // high bidder is subject to beg
        assertTrue(!ali.try_tend(id, 100 ether, 1.01 ether));
        assertTrue( bob.try_tend(id, 100 ether, 1.07 ether));
    }
}
