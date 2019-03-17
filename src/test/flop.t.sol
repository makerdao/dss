pragma solidity >=0.5.0;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "../flop.sol";


contract Hevm {
    function warp(uint256) public;
}

contract Guy {
    Flopper fuss;
    constructor(Flopper fuss_) public {
        fuss = fuss_;
        DSToken(address(fuss.dai())).approve(address(fuss));
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

contract VatLike is DSToken('') {
    uint constant ONE = 10 ** 27;
    function move(bytes32 src, bytes32 dst, uint rad) public {
        move(address(bytes20(src)), address(bytes20(dst)), rad / ONE);
    }
}

contract FlopTest is DSTest {
    Hevm hevm;

    Flopper fuss;
    VatLike dai;
    DSToken gem;

    address ali;
    address bob;
    address gal;

    function kiss(uint) public pure { }  // arbitrary callback

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(1 hours);

        dai = new VatLike();
        gem = new DSToken('');

        fuss = new Flopper(address(dai), address(gem));

        ali = address(new Guy(fuss));
        bob = address(new Guy(fuss));
        gal = address(new Gal());

        dai.approve(address(fuss));
        gem.approve(address(fuss));

        dai.mint(1000 ether);

        dai.push(ali, 200 ether);
        dai.push(bob, 200 ether);
    }
    function test_kick() public {
        assertEq(dai.balanceOf(address(this)), 600 ether);
        assertEq(gem.balanceOf(address(this)),   0 ether);
        fuss.kick({ lot: uint(-1)   // or whatever high starting value
                  , gal: gal
                  , bid: 0
                  });
        // no value transferred
        assertEq(dai.balanceOf(address(this)), 600 ether);
        assertEq(gem.balanceOf(address(this)),   0 ether);
    }
    function test_dent() public {
        uint id = fuss.kick({ lot: uint(-1)   // or whatever high starting value
                            , gal: gal
                            , bid: 10 ether
                            });

        Guy(ali).dent(id, 100 ether, 10 ether);
        // bid taken from bidder
        assertEq(dai.balanceOf(ali), 190 ether);
        // gal receives payment
        assertEq(dai.balanceOf(gal),  10 ether);

        Guy(bob).dent(id, 80 ether, 10 ether);
        // bid taken from bidder
        assertEq(dai.balanceOf(bob), 190 ether);
        // prev bidder refunded
        assertEq(dai.balanceOf(ali), 200 ether);
        // gal receives no more
        assertEq(dai.balanceOf(gal), 10 ether);

        hevm.warp(5 weeks);
        assertEq(gem.totalSupply(),  0 ether);
        gem.setOwner(address(fuss));
        Guy(bob).deal(id);
        // gems minted on demand
        assertEq(gem.totalSupply(), 80 ether);
        // bob gets the winnings
        assertEq(gem.balanceOf(bob), 80 ether);
    }
}
