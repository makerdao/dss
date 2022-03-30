// SPDX-License-Identifier: AGPL-3.0-or-later

// flap.t.sol -- tests for flap.sol

// Copyright (C) 2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.12;

import "ds-test/test.sol";
import {DSToken} from "ds-token/token.sol";
import "../flap.sol";
import "../vat.sol";


interface Hevm {
    function warp(uint256) external;
}

contract Guy {
    Flapper flap;
    constructor(Flapper flap_) public {
        flap = flap_;
        Vat(address(flap.vat())).hope(address(flap));
        DSToken(address(flap.gem())).approve(address(flap));
    }
    function tend(uint id, uint lot, uint bid) public {
        flap.tend(id, lot, bid);
    }
    function deal(uint id) public {
        flap.deal(id);
    }
    function try_tend(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "tend(uint256,uint256,uint256)";
        (ok,) = address(flap).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_deal(uint id)
        public returns (bool ok)
    {
        string memory sig = "deal(uint256)";
        (ok,) = address(flap).call(abi.encodeWithSignature(sig, id));
    }
    function try_tick(uint id)
        public returns (bool ok)
    {
        string memory sig = "tick(uint256)";
        (ok,) = address(flap).call(abi.encodeWithSignature(sig, id));
    }
}

contract FlapTest is DSTest {
    Hevm hevm;

    Flapper flap;
    Vat     vat;
    DSToken gem;

    address ali;
    address bob;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        vat = new Vat();
        gem = new DSToken('');

        flap = new Flapper(address(vat), address(gem));
        flap.file("lid", 500 ether);

        ali = address(new Guy(flap));
        bob = address(new Guy(flap));

        vat.hope(address(flap));
        gem.approve(address(flap));

        vat.suck(address(this), address(this), 1000 ether);

        gem.mint(1000 ether);
        gem.setOwner(address(flap));

        gem.push(ali, 200 ether);
        gem.push(bob, 200 ether);
    }
    function test_kick() public {
        assertEq(vat.dai(address(this)), 1000 ether);
        assertEq(vat.dai(address(flap)),    0 ether);
        assertEq(flap.fill(),               0 ether);
        flap.kick({ lot: 100 ether
                  , bid: 0
                  });
        assertEq(vat.dai(address(this)),  900 ether);
        assertEq(vat.dai(address(flap)),  100 ether);
        assertEq(flap.fill(),             100 ether);
    }
    function test_tend() public {
        uint id = flap.kick({ lot: 100 ether
                            , bid: 0
                            });
        // lot taken from creator
        assertEq(vat.dai(address(this)), 900 ether);

        Guy(ali).tend(id, 100 ether, 1 ether);
        // bid taken from bidder
        assertEq(gem.balanceOf(ali), 199 ether);
        // payment remains in auction
        assertEq(gem.balanceOf(address(flap)),  1 ether);

        Guy(bob).tend(id, 100 ether, 2 ether);
        // bid taken from bidder
        assertEq(gem.balanceOf(bob), 198 ether);
        // prev bidder refunded
        assertEq(gem.balanceOf(ali), 200 ether);
        // excess remains in auction
        assertEq(gem.balanceOf(address(flap)),   2 ether);

        hevm.warp(now + 5 weeks);
        Guy(bob).deal(id);
        // high bidder gets the lot
        assertEq(vat.dai(address(flap)),  0 ether);
        assertEq(vat.dai(bob), 100 ether);
        // income is burned
        assertEq(gem.balanceOf(address(flap)),   0 ether);
    }
    function test_tend_same_bidder() public {
        uint id = flap.kick({ lot: 100 ether
                            , bid: 0
                            });
        Guy(ali).tend(id, 100 ether, 190 ether);
        assertEq(gem.balanceOf(ali), 10 ether);
        Guy(ali).tend(id, 100 ether, 200 ether);
        assertEq(gem.balanceOf(ali), 0);
    }
    function test_beg() public {
        uint id = flap.kick({ lot: 100 ether
                            , bid: 0
                            });
        assertTrue( Guy(ali).try_tend(id, 100 ether, 1.00 ether));
        assertTrue(!Guy(bob).try_tend(id, 100 ether, 1.01 ether));
        // high bidder is subject to beg
        assertTrue(!Guy(ali).try_tend(id, 100 ether, 1.01 ether));
        assertTrue( Guy(bob).try_tend(id, 100 ether, 1.07 ether));
    }
    function test_tick() public {
        // start an auction
        uint id = flap.kick({ lot: 100 ether
                            , bid: 0
                            });
        // check no tick
        assertTrue(!Guy(ali).try_tick(id));
        // run past the end
        hevm.warp(now + 2 weeks);
        // check not biddable
        assertTrue(!Guy(ali).try_tend(id, 100 ether, 1 ether));
        assertTrue( Guy(ali).try_tick(id));
        // check biddable
        assertTrue( Guy(ali).try_tend(id, 100 ether, 1 ether));
    }
    function testFail_kick_over_lid() public {
        flap.kick({ lot: 501 ether
                  , bid: 0
                  });
    }
    function testFail_kick_over_lid_2_auctions() public {
        // Just up to the lid
        flap.kick({ lot: 500 ether
                  , bid: 0
                  });
        // Just over the lid
        flap.kick({ lot: 1
                  , bid: 0
                  });
    }
    function test_deal() public {
        uint256 id = flap.kick({ lot: 400 ether
                  , bid: 0
                  });
        assertEq(flap.fill(), 400 ether);
        Guy(ali).tend(id, 400 ether, 1 ether);
        assertEq(flap.fill(), 400 ether);
        hevm.warp(block.timestamp + 30 days);
        flap.deal(id);
        assertEq(flap.fill(), 0);
        flap.kick({ lot: 400 ether
                  , bid: 0
                  });
        assertEq(flap.fill(), 400 ether);
    }
    function test_multiple_auctions() public {
        uint256 id1 = flap.kick({ lot: 200 ether
                  , bid: 0
                  });
        assertEq(flap.fill(), 200 ether);
        uint256 id2 = flap.kick({ lot: 200 ether
                  , bid: 0
                  });
        assertEq(flap.fill(), 400 ether);
        Guy(ali).tend(id1, 200 ether, 1 ether);
        assertEq(flap.fill(), 400 ether);
        hevm.warp(block.timestamp + 30 days);
        flap.deal(id1);
        assertEq(flap.fill(), 200 ether);
        flap.kick({ lot: 300 ether
                  , bid: 0
                  });
        assertEq(flap.fill(), 500 ether);
        flap.tick(id2);
        Guy(ali).tend(id2, 200 ether, 1 ether);
        assertEq(flap.fill(), 500 ether);
        hevm.warp(block.timestamp + 30 days);
        flap.deal(id2);
        assertEq(flap.fill(), 300 ether);
    }
    function test_mod_lid_in_flight() public {
        uint256 id = flap.kick({ lot: 400 ether
                  , bid: 0
                  });
        assertEq(flap.fill(), 400 ether);
        assertEq(flap.lid(), 500 ether);

        // Reduce lid while auction is active
        flap.file("lid", 300 ether);

        Guy(ali).tend(id, 400 ether, 1 ether);
        assertEq(flap.fill(), 400 ether);
        assertEq(flap.lid(), 300 ether);
        hevm.warp(block.timestamp + 30 days);
        flap.deal(id);
        assertEq(flap.fill(), 0);
        flap.kick({ lot: 300 ether
                  , bid: 0
                  });
        assertEq(flap.fill(), 300 ether);
    }

}
