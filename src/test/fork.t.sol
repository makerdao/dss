// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.12;

import "ds-test/test.sol";
import "ds-token/token.sol";

import {Vat} from '../vat.sol';

contract Usr {
    Vat public vat;
    constructor(Vat vat_) public {
        vat = vat_;
    }
    function try_call(address addr, bytes calldata data) external returns (bool) {
        bytes memory _data = data;
        assembly {
            let ok := call(gas(), addr, 0, add(_data, 0x20), mload(_data), 0, 0)
            let free := mload(0x40)
            mstore(free, ok)
            mstore(0x40, add(free, 32))
            revert(free, 32)
        }
    }
    function can_frob(bytes32 ilk, address u, address v, address w, int dink, int dart) public returns (bool) {
        string memory sig = "frob(bytes32,address,address,address,int256,int256)";
        bytes memory data = abi.encodeWithSignature(sig, ilk, u, v, w, dink, dart);

        bytes memory can_call = abi.encodeWithSignature("try_call(address,bytes)", vat, data);
        (bool ok, bytes memory success) = address(this).call(can_call);

        ok = abi.decode(success, (bool));
        if (ok) return true;
    }
    function can_fork(bytes32 ilk, address src, address dst, int dink, int dart) public returns (bool) {
        string memory sig = "fork(bytes32,address,address,int256,int256)";
        bytes memory data = abi.encodeWithSignature(sig, ilk, src, dst, dink, dart);

        bytes memory can_call = abi.encodeWithSignature("try_call(address,bytes)", vat, data);
        (bool ok, bytes memory success) = address(this).call(can_call);

        ok = abi.decode(success, (bool));
        if (ok) return true;
    }
    function frob(bytes32 ilk, address u, address v, address w, int dink, int dart) public {
        vat.frob(ilk, u, v, w, dink, dart);
    }
    function fork(bytes32 ilk, address src, address dst, int dink, int dart) public {
        vat.fork(ilk, src, dst, dink, dart);
    }
    function hope(address usr) public {
        vat.hope(usr);
    }
    function pass() public {}
}

contract ForkTest is DSTest {
    Vat vat;
    Usr ali;
    Usr bob;
    address a;
    address b;

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }

    function setUp() public {
        vat = new Vat();
        ali = new Usr(vat);
        bob = new Usr(vat);
        a = address(ali);
        b = address(bob);

        vat.init("gems");
        vat.file("gems", "spot", ray(0.5  ether));
        vat.file("gems", "line", rad(1000 ether));
        vat.file("Line",         rad(1000 ether));

        vat.slip("gems", a, 8 ether);
    }
    function test_fork_to_self() public {
        ali.frob("gems", a, a, a, 8 ether, 4 ether);
        assertTrue( ali.can_fork("gems", a, a, 8 ether, 4 ether));
        assertTrue( ali.can_fork("gems", a, a, 4 ether, 2 ether));
        assertTrue(!ali.can_fork("gems", a, a, 9 ether, 4 ether));
    }
    function test_give_to_other() public {
        ali.frob("gems", a, a, a, 8 ether, 4 ether);
        assertTrue(!ali.can_fork("gems", a, b, 8 ether, 4 ether));
        bob.hope(address(ali));
        assertTrue( ali.can_fork("gems", a, b, 8 ether, 4 ether));
    }
    function test_fork_to_other() public {
        ali.frob("gems", a, a, a, 8 ether, 4 ether);
        bob.hope(address(ali));
        assertTrue( ali.can_fork("gems", a, b, 4 ether, 2 ether));
        assertTrue(!ali.can_fork("gems", a, b, 4 ether, 3 ether));
        assertTrue(!ali.can_fork("gems", a, b, 4 ether, 1 ether));
    }
    function test_fork_dust() public {
        ali.frob("gems", a, a, a, 8 ether, 4 ether);
        bob.hope(address(ali));
        assertTrue( ali.can_fork("gems", a, b, 4 ether, 2 ether));
        vat.file("gems", "dust", rad(1 ether));
        assertTrue( ali.can_fork("gems", a, b, 2 ether, 1 ether));
        assertTrue(!ali.can_fork("gems", a, b, 1 ether, 0.5 ether));
    }
}
