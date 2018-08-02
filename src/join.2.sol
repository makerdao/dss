/// join.2.sol -- Basic token adapters

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
// Copyright (C) 2018 Lev Livnev <lev@liv.nev.org.uk>
// Copyright (C) 2018 Denis Erfurt <denis@dapp.org>
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

// Copyright (C) 2018 AGPL

pragma solidity ^0.4.24;

interface GemJoinI {
  function vat() external returns (address);
  function ilk() external returns (bytes32);
  function gem() external returns (address);
  function join(bytes32 urn, uint256 wad) external;
  function exit(address guy, uint256 wad) external;
}

contract GemJoin {
  constructor (address vat_, bytes32 ilk_, address gem_) public {
    assembly {
      codecopy(0, sub(codesize, 96), 96)

      // set vat = vat_
      sstore(0, mload(0))

      // set ilk = ilk_
      sstore(1, mload(32))

      // set gem = gem_
      sstore(2, mload(64))
    }
  }
  function () public {
    assembly {
      let sig := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      if eq(sig, 0x36569e77 /*   function vat() external returns (address); */) {
        mstore(64, sload(0))
        return(64, 32)
      }
      if eq(sig, 0xc5ce281e /*   function ilk() external returns (bytes32); */) {
        mstore(64, sload(1))
        return(64, 32)
      }
      if eq(sig, 0x7bd2bea7 /*   function gem() external returns (address); */) {
        mstore(64, sload(2))
        return(64, 32)
      }
      if eq(sig, 0xe5009bb6 /*   function join(bytes32 urn, uint256 wad) external; */) {

        let rad := umul(calldataload(36), 1000000000000000000000000000)

        // put bytes4(keccak256("transferFrom(address,address,uint256)")) << 28 bytes
        mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
        // put msg.sender
        mstore(4, caller)
        // put this
        mstore(36, address)
        // put wad
        mstore(68, calldataload(36))
        // iff gem.call("transferFrom(address,address,uint256)", msg.sender, this, wad) != 0
        if iszero(call(gas, sload(2), 0, 0, 100, 0, 0)) { revert(0, 0) }

        // put bytes4(keccak256("slip(bytes32,bytes32,int256)")) << 28 bytes
        mstore(0, 0x42066cbb00000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, sload(1))
        // put urn
        mstore(36, calldataload(4))
        // put rad
        mstore(68, rad)
        // iff vat.call("slip(bytes32,bytes32,int256)", ilk, msg.sender, rad) != 0
        if iszero(call(gas, sload(0), 0, 0, 100, 0, 0)) { revert(0, 0) }

        stop()
      }
      if eq(sig, 0xef693bed /*   function exit(address guy, uint256 wad) external; */) {

        let rad := umul(calldataload(36), 1000000000000000000000000000)

        // put bytes4(keccak256("transferFrom(address,address,uint256)")) << 28 bytes
        mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
        // put this
        mstore(4, address)
        // put guy
        mstore(36, calldataload(4))
        // put wad
        mstore(68, calldataload(36))
        // iff gem.call("transferFrom(address,address,uint256)", this, msg.sender, wad) != 0
        if iszero(call(gas, sload(2), 0, 0, 100, 0, 0)) { revert(0, 0) }

        // put bytes4(keccak256("slip(bytes32,bytes32,int256)")) << 28 bytes
        mstore(0, 0x42066cbb00000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, sload(1))
        // put msg.sender
        mstore(36, caller)
        // put -rad
        mstore(68, sub(0, rad))
        // iff vat.call("slip(bytes32,bytes32,int256)", ilk, msg.sender, -rad) != 0
        if iszero(call(gas, sload(0), 0, 0, 100, 0, 0)) { revert(0, 0) }

        stop()
      }

      // failed to select any of the public methods:
      revert(0, 0)

      function umul(x, y) -> z {
        z := mul(x, y)
        // max_int := 2**255 - 1
        let max_int := 57896044618658097711785492504343953926634992332820282019728792003956564819967
        // iff int(z) >= 0
        if gt(z, max_int) { revert(0, 0) }
        // iff y == 0 || z / y == x
        if iszero(or(eq(y, 0), eq(div(z, y), x))) { revert(0, 0) }
      }
    }
  }
}

interface ETHJoinI {
  function vat() external returns (address);
  function ilk() external returns (bytes32);
  function join(bytes32 urn) external payable;
  function exit(address guy, uint256 wad) external;
}

contract ETHJoin {
  constructor (address vat_, bytes32 ilk_) public {
    assembly {
      codecopy(0, sub(codesize, 64), 64)

      // set vat = vat_
      sstore(0, mload(0))

      // set ilk = ilk_
      sstore(1, mload(32))
    }
  }
  function () public payable {
    assembly {
      let sig := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      if eq(sig, 0x36569e77 /*   function vat() external returns (address); */) {
        mstore(64, sload(0))
        return(64, 32)
      }
      if eq(sig, 0xc5ce281e /*   function ilk() external returns (bytes32); */) {
        mstore(64, sload(1))
        return(64, 32)
      }
      if eq(sig, 0xad677d0b /*   function join(bytes32 urn) external; */) {

        // set rad = wad * one
        let rad := umul(callvalue, 1000000000000000000000000000)

        // put bytes4(keccak256("slip(bytes32,bytes32,int256)")) << 28 bytes
        mstore(0, 0x42066cbb00000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, sload(1))
        // put urn
        mstore(36, calldataload(4))
        // put rad
        mstore(68, rad)
        // iff vat.call("slip(bytes32,bytes32,int256)", ilk, msg.sender, rad) != 0
        if iszero(call(gas, sload(0), 0, 0, 100, 0, 0)) { revert(0, 0) }

        stop()
      }
      if eq(sig, 0xef693bed /*   function exit(address guy, uint256 wad) external; */) {

        // set rad = wad * ONE
        let rad := umul(calldataload(36), 1000000000000000000000000000)

        // put 0
        mstore(0, 0)
        // iff call(2500, guy, wad, 0, 0, 0, 0) != 0
        if iszero(call(2500, calldataload(4), calldataload(36), 0, 0, 0, 0)) { revert(0, 0) }

        // put bytes4(keccak256("slip(bytes32,bytes32,int256)")) << 28 bytes
        mstore(0, 0x42066cbb00000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, sload(1))
        // put msg.sender
        mstore(36, caller)
        // put -rad
        mstore(68, sub(0, rad))
        // iff vat.call("slip(bytes32,bytes32,int256)", ilk, msg.sender, -rad) != 0
        if iszero(call(gas, sload(0), 0, 0, 100, 0, 0)) { revert(0, 0) }

        stop()
      }

      // failed to select any of the public methods:
      revert(0, 0)

      function umul(x, y) -> z {
        z := mul(x, y)
        // max_int := 2**255 - 1
        let max_int := 57896044618658097711785492504343953926634992332820282019728792003956564819967
        // iff int(z) >= 0
        if gt(z, max_int) { revert(0, 0) }
        // iff y == 0 || z / y == x
        if iszero(or(eq(y, 0), eq(div(z, y), x))) { revert(0, 0) }
      }
    }
  }
}

interface DaiJoinI {
  function vat() external returns (address);
  function ilk() external returns (bytes32);
  function gem() external returns (address);
  function join(bytes32 urn, uint256 wad) external;
  function exit(address guy, uint256 wad) external;
}

contract DaiJoin {
  constructor (address vat_, address dai_) public {
    assembly {
      codecopy(0, sub(codesize, 64), 64)

      // set vat = vat_
      sstore(0, mload(0))

      // set dai = dai_
      sstore(1, mload(32))
    }
  }
  function () public {
    assembly {
      let sig := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      if eq(sig, 0x36569e77 /*   function vat() external returns (address); */) {
        mstore(64, sload(0))
        return(64, 32)
      }
      if eq(sig, 0xf4b9fa75 /*   function dai() external returns (bytes32); */) {
        mstore(64, sload(1))
        return(64, 32)
      }
      if eq(sig, 0xe5009bb6 /*   function join(bytes32 urn, uint256 wad) external; */) {

        let rad := umul(calldataload(36), 1000000000000000000000000000)

        // put bytes4(keccak256("move(bytes32,bytes32,int256)")) << 28 bytes
        mstore(0, 0x78f1947000000000000000000000000000000000000000000000000000000000)
        // put this
        mstore(4, address)
        // put urn
        mstore(36, calldataload(4))
        // put rad
        mstore(68, rad)
        // iff vat.call("move(bytes32,bytes32,int256)", this, urn, rad) != 0
        if iszero(call(gas, sload(0), 0, 0, 100, 0, 0)) { revert(0, 0) }

        // put bytes4(keccak256("burn(address,uint256)")) << 28 bytes
        mstore(0, 0x9dc29fac00000000000000000000000000000000000000000000000000000000)
        // put msg.sender
        mstore(4, caller)
        // put wad
        mstore(36, calldataload(36))
        // iff gem.call("burn(address,uint256)", msg.sender, wad) != 0
        if iszero(call(gas, sload(1), 0, 0, 68, 0, 0)) { revert(0, 0) }

        stop()
      }
      if eq(sig, 0xef693bed /*   function exit(address guy, uint256 wad) external; */) {

        let rad := umul(calldataload(36), 1000000000000000000000000000)

        // put bytes4(keccak256("move(bytes32,bytes32,int256)")) << 28 bytes
        mstore(0, 0x78f1947000000000000000000000000000000000000000000000000000000000)
        // put msg.sender
        mstore(4, caller)
        // put this
        mstore(36, address)
        // put rad
        mstore(68, rad)
        // iff vat.call("move(bytes32,bytes32,int256)", msg.sender, this, rad) != 0
        if iszero(call(gas, sload(0), 0, 0, 100, 0, 0)) { revert(0, 0) }

        // put bytes4(keccak256("mint(address,uint256)")) << 28 bytes
        mstore(0, 0x40c10f1900000000000000000000000000000000000000000000000000000000)
        // put msg.sender
        mstore(4, caller)
        // put wad
        mstore(36, calldataload(36))
        // iff gem.call("mint(address,uint256)", msg.sender, wad) != 0
        if iszero(call(gas, sload(1), 0, 0, 68, 0, 0)) { revert(0, 0) }

        stop()
      }

      // failed to select any of the public methods:
      revert(0, 0)

      function umul(x, y) -> z {
        z := mul(x, y)
        // max_int := 2**255 - 1
        let max_int := 57896044618658097711785492504343953926634992332820282019728792003956564819967
        // iff int(z) >= 0
        if gt(z, max_int) { revert(0, 0) }
        // iff y == 0 || z / y == x
        if iszero(or(eq(y, 0), eq(div(z, y), x))) { revert(0, 0) }
      }
    }
  }
}
