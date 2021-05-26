// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.12;

import "ds-test/test.sol";
import {DSValue} from "ds-value/value.sol";
import {DSToken} from "ds-token/token.sol";
import {Clapper} from "../clap.sol";
import {Vat} from "../vat.sol";
import {Spotter} from "../spot.sol";
import {StairstepExponentialIncrease} from "../abaci.sol";
import {Spotter} from "../spot.sol";


interface Hevm {
    function warp(uint256) external;
}

contract Guy {
    Clapper clap;
    constructor(Clapper clap_) public {
        clap = clap_;
        Vat(address(clap.vat())).hope(address(clap));
        DSToken(address(clap.gem())).approve(address(clap));
    }
    function take(uint256 id, uint256 lot, uint256 min, address who, bytes calldata data) public {
        clap.take(id, lot, min, who, data);
    }
    function try_take(uint256 id, uint256 lot, uint256 min, address who, bytes calldata data)
        public returns (bool ok)
    {
        string memory sig = "take(uint256,uint256,uint256,address,bytes)";
        (ok,) = address(clap).call(abi.encodeWithSignature(sig, id, lot, min, who, data));
    }
}

contract ClapperTest is DSTest {
    Hevm hevm;

    Clapper clap;
    Vat     vat;
    Spotter spotter;
    DSValue pip;
    DSToken gem;

    address ali;
    address bob;

    uint256 constant mkrPrice = 5000 ether;

    function ray(uint256 wad) internal pure returns (uint256) {
        return wad * 10 ** 9;
    }

    function rad(uint256 wad) internal pure returns (uint256) {
        return wad * 10 ** 27;
    }

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        vat = new Vat();
        spotter = new Spotter(address(vat));
        vat.rely(address(spotter));
        gem = new DSToken('');

        pip = new DSValue();
        pip.poke(bytes32(mkrPrice));

        clap = new Clapper(address(vat), address(gem));

        StairstepExponentialIncrease calc = new StairstepExponentialIncrease();
        calc.file("gain", ray(1.01 ether));   // 1% increment
        calc.file("step", 90);                // Increment every 90 second

        clap.file("spotter", address(spotter));
        clap.file("pip", address(pip));
        clap.file("calc", address(calc));

        clap.file("buf",  ray(0.80 ether));   // 80% of current price as Initial
        clap.file("cusp", ray(1.3 ether));    // 30% increment before reset
        clap.file("tail", 1 hours);           // 1 hour before reset

        ali = address(new Guy(clap));
        bob = address(new Guy(clap));

        vat.hope(address(clap));
        gem.approve(address(clap));

        vat.suck(address(this), address(this), rad(100_000 ether));

        gem.mint(1000 ether);
        gem.setOwner(address(clap));

        gem.push(ali, 200 ether);
        gem.push(bob, 200 ether);
    }

    function test_kick() public {
        assertEq(vat.dai(address(this)), rad(100_000 ether));
        assertEq(vat.dai(address(clap)),    0 ether);
        uint256 id = clap.kick(rad(10_000 ether), 0);
        assertEq(vat.dai(address(this)),  rad(90_000 ether));
        assertEq(vat.dai(address(clap)),  rad(10_000 ether));
        (uint256 lot, uint256 dip, uint256 tic) = clap.sales(id);
        assertEq(lot, rad(10_000 ether));
        assertEq(dip, ray(4_000 ether)); // 5,000 (mkrPrice) * 0.8 (buf)
        assertEq(tic, block.timestamp);
    }

    function test_take() public {
        uint256 id = clap.kick(rad(10_000 ether), 0);

        Guy(ali).take({
            id:  id,
            lot: rad(6_000 ether),
            min: ray(4_000 ether), // starting price
            who: address(ali),
            data: ""
        });
        
        // bid taken from bidder
        assertEq(gem.balanceOf(ali), 200 ether - 6_000 ether / 4_000);
        assertEq(vat.dai(address(ali)), rad(6_000 ether));

        hevm.warp(block.timestamp + 90);

        (uint256 lot, uint256 dip, uint256 tic) = clap.sales(id);
        assertEq(lot, 4_000 * 10**45); // 10_000 - 6_000

        (bool needsRedo, uint256 price, uint256 lot2) = clap.getStatus(id);
        assertEq(lot2, lot);
        assertTrue(!needsRedo);
        assertEq(price, 4_040 * 10**27); // 4,000 * 1%^(90/90)

        Guy(bob).take({
            id:  id,
            lot: rad(4_000 ether),
            min: price,
            who: address(bob),
            data: ""
        });
        assertEq(gem.balanceOf(bob), 200 ether - 4_000 ether * 10 ** 27 / price);
        assertEq(vat.dai(address(bob)), rad(4_000 ether));

        (lot, dip, tic) = clap.sales(id);
        assertEq(lot, 0);
    }

    function test_redo_tail() public {
        clap.file("cusp", ray(2 ether)); // High limit so it triggers due tail and not cusp
        uint256 id = clap.kick(rad(10_000 ether), 0);

        (bool needsRedo, uint256 price,) = clap.getStatus(id);
        assertTrue(!needsRedo);
        assertEq(price, ray(mkrPrice * clap.buf() / 10**27));

        hevm.warp(block.timestamp + clap.tail());
        (needsRedo,,) = clap.getStatus(id);
        assertTrue(!needsRedo);

        hevm.warp(block.timestamp + 1);
        (needsRedo, price,) = clap.getStatus(id);
        assertTrue(needsRedo);
        (, uint256 dip,) = clap.sales(id);
        assertTrue(price * 10**27 / dip <= clap.cusp()); // Not failing due price/cusp

        pip.poke(bytes32(uint256(5_200 ether))); // 200 higher at the redo moment

        clap.redo(id);
        (needsRedo, price,) = clap.getStatus(id);
        assertTrue(!needsRedo);
        assertEq(price, ray(5_200 ether * clap.buf() / 10**27));
    }

    function test_redo_price() public {
        uint256 id = clap.kick(rad(10_000 ether), 0);

        (bool needsRedo, uint256 price,) = clap.getStatus(id);
        assertTrue(!needsRedo);
        assertEq(price, ray(mkrPrice * clap.buf() / 10**27));

        hevm.warp(block.timestamp + 30 minutes);
        (needsRedo,,) = clap.getStatus(id);
        assertTrue(!needsRedo);

        hevm.warp(block.timestamp + 20 minutes);
        (needsRedo, price,) = clap.getStatus(id);
        assertTrue(needsRedo);
        (, uint256 dip,) = clap.sales(id);
        assertTrue(price * 10**27 / dip > clap.cusp()); // Fails due price/cusp (time passed lower than tail)

        pip.poke(bytes32(uint256(5_200 ether))); // 200 higher at the redo moment

        clap.redo(id);
        (needsRedo, price,) = clap.getStatus(id);
        assertTrue(!needsRedo);
        assertEq(price, ray(5_200 ether * clap.buf() / 10**27));
    }

    function testFail_redo() public {
        uint256 id = clap.kick(rad(10_000 ether), 0);
        hevm.warp(block.timestamp + 30 minutes);
        clap.redo(id);
    }
}
