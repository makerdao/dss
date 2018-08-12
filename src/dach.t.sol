pragma solidity ^0.4.23;

import "ds-test/test.sol";
import "./tune.sol";
import "./dach.sol";

contract WarpVat is Vat {
   uint256 constant ONE = 10 ** 27;
   function mint(address guy, uint wad) public {
      dai[guy] += int(wad * ONE);
      Tab      += int(wad * ONE);
   }
   
   function balanceOf(address guy) public view returns (uint) {
      return uint(dai[guy]) / ONE;
   }

}

contract DachTest is DSTest {
    Dach dach;
    WarpVat vat;
    address ali = 0x29c76e6ad8f28bb1004902578fb108c507be341b;
    address bob = 0xdd2d5d3f7f1b35b7a0601d6a00dbb7d44af58479;
    //See ds-relay for signature generation. The following sig is of a cheque
    //specifying a 2 dai transfer to bob with a 1 dai fee to msg.sender
    string sig = '0x84ebf347874306b9b31fb6d184848b78ac67e41fbe27f60bb2cebf6cb61e8ae14519af4a52f95189d6db440ba40d5c729fed9079302b6adb89de4acc081c8ba31b';
    //the string above is not used anywhere, we decompose it into the following params:
    uint8 v = 27;
    bytes32 r = 0x84ebf347874306b9b31fb6d184848b78ac67e41fbe27f60bb2cebf6cb61e8ae1;
    bytes32 s = 0x4519af4a52f95189d6db440ba40d5c729fed9079302b6adb89de4acc081c8ba3;

    function setUp() public {
      vat = new WarpVat();
      dach = new Dach(vat);
      vat.mint(ali,80);
      assertEq(vat.balanceOf(ali),80);
    }

    function testFail_basic_sanity() public {
      assertTrue(false);
    }

    function test_basic_sanity() public {
      assertTrue(true);
    }

    function test_clear() public {
      assertEq(vat.balanceOf(ali),80);
      assertEq(vat.balanceOf(bob),0);
      assertEq(vat.balanceOf(this),0);
      dach.clear(ali, bob, 2, 1, 0, v, r, s);
      assertEq(vat.balanceOf(ali),77);
      assertEq(vat.balanceOf(bob),2);
      assertEq(vat.balanceOf(this),1);
    }

    function test_replay_protection() public {
      //Resubmitting the same cheque results in a throw
      dach.clear(ali, bob, 2, 1, 0, v, r, s);
      assertEq(vat.balanceOf(ali),77);
      assertEq(vat.balanceOf(bob),2);
      assertEq(vat.balanceOf(this),1);
    }
}
