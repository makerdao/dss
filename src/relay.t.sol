pragma solidity ^0.4.23;

import "ds-test/test.sol";
import "./tune.sol";
import "./relay.sol";

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

contract RelayTest is DSTest {
      Relay relay;
      WarpVat vat;
      address ali = 0x29c76e6ad8f28bb1004902578fb108c507be341b;
      address bob = 0xdd2d5d3f7f1b35b7a0601d6a00dbb7d44af58479;
      //See ds-relay for signature generation. The following sig is of a cheque
      //specifying a 2 dai transfer to bob with a 1 dai fee to msg.sender
      string sig = '0x657e67032cfa3b1efd231d5b046e07bb2ecf1547b9d32551c3793fe156516ad00a811c31e50e64adea6a7209836fc22d7746a67d3953a342453857daf26704841b';
      //the string above is not used anywhere, we decompose it into the following params:
      uint8 v = 27;
      bytes32 r = 0x657e67032cfa3b1efd231d5b046e07bb2ecf1547b9d32551c3793fe156516ad0;
      bytes32 s = 0x0a811c31e50e64adea6a7209836fc22d7746a67d3953a342453857daf2670484;
      
      function setUp() public {
          vat = new WarpVat();
          relay = new Relay(vat);
          vat.mint(ali,80);
          assertEq(vat.balanceOf(ali),80);
      }

      function testFail_basic_sanity() public {
         assertTrue(false);
      }
      
      function test_basic_sanity() public {
         assertTrue(true);
      }


      function test_relay() public {
         assertEq(vat.balanceOf(ali),80);
         assertEq(vat.balanceOf(bob),0);
         assertEq(vat.balanceOf(this),0);
         relay.relay(ali, bob, 2, 1, 0, v, r, s);
         assertEq(vat.balanceOf(ali),77);
         assertEq(vat.balanceOf(bob),2);
         assertEq(vat.balanceOf(this),1);
      }

      function test_replay_protection() public {
         //Resubmitting the same cheque results in a throw
         relay.relay(ali, bob, 2, 1, 0, v, r, s);
         assertEq(vat.balanceOf(ali),77);
         assertEq(vat.balanceOf(bob),2);
         assertEq(vat.balanceOf(this),1);
      }
}
