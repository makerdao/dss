// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.11;

import { DSTest } from "ds-test/test.sol";
import { Vat } from "../vat.sol";
import { Dog } from "../dog.sol";

contract DogTest is DSTest {

    Vat vat;
    bytes32 constant ilk = "gold";
    address constant vow = address(0);
    address constant usr = address(1);
    uint256 constant THOUSAND = 1E3;
    uint256 constant WAD = 1E18;
    uint256 constant RAY = 1E27;
    uint256 constant RAD = 1E45;
    Dog dog;

    function setUp() public {
        vat = new Vat();
        vat.init(ilk);
        vat.file(ilk, "spot", THOUSAND * RAY);
        vat.file(ilk, "dust", 100 * RAD);
        dog = new Dog(address(vat));
    }

    function setUrn(uint256 ink, uint256 art) internal {
        vat.slip(ilk, usr, int256(ink));
        vat.suck(vow, vow, art * RAY);
        vat.grab(ilk, usr, usr, vow, int256(ink), int256(art));
    }

    function setHoles(uint256 Hole, uint256 hole) internal {
        dog.file("Hole", Hole);
        dog.file(ilk, "hole", hole);
    }

    function test_dog() public {
        setUrn(WAD, 2 * THOUSAND * WAD);
        setHoles(10 * THOUSAND * RAD, 10 * THOUSAND * RAD);
        dog.bark(ilk, usr, usr);
    }
}
