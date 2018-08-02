/// heal.2.sol -- Dai settlement module

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

interface VowI {
  function wards(address guy) external returns (bool);
  function rely(address guy) external;
  function deny(address guy) external;
  function vat() external returns (address);
  function cow() external returns (address);
  function row() external returns (address);
  function sin(uint48 era_) external returns (uint256);
  function Sin() external returns (uint256);
  function Woe() external returns (uint256);
  function Ash() external returns (uint256);
  function wait() external returns (uint256);
  function sump() external returns (uint256);
  function bump() external returns (uint256);
  function hump() external returns (uint256);
  function era() external returns (uint48);
  function file(bytes32 what, uint256 data) external;
  function file(bytes32 what, address addr) external;
  function Awe() external returns (uint256);
  function Joy() external returns (uint256);
  function fess(uint256 tab) external;
  function flog(uint48 era_) external;
  function heal(uint256 wad) external;
  function kiss(uint256 wad) external;
  function flop() external returns (uint256);
  function flap() external returns (uint256);
}

contract Vow {
  constructor () public {
    assembly{
      let hash_0 := hash2(0, caller)

      // set wards[caller] = true
      sstore(hash_0, 1)

      // map[key] translates to hash(key ++ idx(map))
      function hash2(b, i) -> h {
        mstore(0, i)
        mstore(32, b)
        h := keccak256(0, 64)
      }
    }
  }
  function () public {
    assembly {
      let sig := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      if eq(sig, 0xbf353dbb /*   function wards(address guy) external returns (bool can); */) {
        let hash_0 := hash2(0, calldataload(4))
        mstore(64, sload(hash_0))
        return(64, 32)
      }
      if eq(sig, 0x65fae35e  /*   function rely(address guy) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(0, calldataload(4))

        // set wards[guy] = true
        sstore(hash_0, 1)

        stop()
      }
      if eq(sig, 0x9c52a7f1  /*   function deny(address guy) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(0, calldataload(4))

        // set wards[guy] = false
        sstore(hash_0, 0)

        stop()
      }
      if eq(sig, 0x36569e77 /*   function vat() external returns (address); */) {
        mstore(64, sload(1))
        return(64, 32)
      }
      if eq(sig, 0xdfbf306d /*   function cow() external returns (address); */) {
        mstore(64, sload(2))
        return(64, 32)
      }
      if eq(sig, 0x70904ded /*   function row() external returns (address); */) {
        mstore(64, sload(3))
        return(64, 32)
      }
      if eq(sig, 0x7f49edc4 /*   function sin(uint48 era_) external returns (uint256); */) {
        let hash_0 := hash2(4, calldataload(4))
        mstore(64, sload(hash_0))
        return(64, 32)
      }
      if eq(sig, 0xd0adc35f /*   function Sin() external returns (uint256); */) {
        mstore(64, sload(5))
        return(64, 32)
      }
      if eq(sig, 0x49dd5bb2 /*   function Woe() external returns (uint256); */) {
        mstore(64, sload(6))
        return(64, 32)
      }
      if eq(sig, 0x2a1d2b3c /*   function Ash() external returns (uint256); */) {
        mstore(64, sload(7))
        return(64, 32)
      }
      if eq(sig, 0x64bd7013 /*   function wait() external returns (uint256); */) {
        mstore(64, sload(8))
        return(64, 32)
      }
      if eq(sig, 0xc349d362 /*   function sump() external returns (uint256); */) {
        mstore(64, sload(9))
        return(64, 32)
      }
      if eq(sig, 0x68110b2f /*   function bump() external returns (uint256); */) {
        mstore(64, sload(10))
        return(64, 32)
      }
      if eq(sig, 0x1b8e8cfa /*   function hump() external returns (uint256); */) {
        mstore(64, sload(11))
        return(64, 32)
      }
      if eq(sig, 0x143e55e0 /*   function era() external returns (uint48); */) {
        mstore(64, timestamp)
        return(64, 32)
      }
      if eq(sig, 0x05db4538 /*   function Awe() external returns (uint256); */) {
        mstore(64, Awe())
        return(64, 32)
      }
      if eq(sig, 0x07a832b4 /*   function Joy() external returns (uint256); */) {
        mstore(64, Joy())
        return(64, 32)
      }
      if eq(sig, 0x29ae8114 /*   function file(bytes32 what, uint256 data) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        // if what == "wait" set wait = data
        if eq(calldataload(4), "wait") { sstore(8, calldataload(36)) }

        // if what == "sump" set sump = data
        if eq(calldataload(4), "sump") { sstore(9, calldataload(36)) }

        // if what == "bump" set bump = data
        if eq(calldataload(4), "bump") { sstore(10, calldataload(36)) }

        // if what == "hump" set hump = data
        if eq(calldataload(4), "hump") { sstore(11, calldataload(36)) }

        stop()
      }
      if eq(sig, 0xd4e8be83 /*   function file(bytes32 what, address addr) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        // if what == "flap" set cow = addr
        if eq(calldataload(4), "flap") { sstore(2, calldataload(36)) }

        // if what == "flop" set row = addr
        if eq(calldataload(4), "flop") { sstore(3, calldataload(36)) }

        // if what == "vat" set vat = addr
        if eq(calldataload(4), "vat") { sstore(1, calldataload(36)) }

        stop()
      }
      if eq(sig, 0xf37ac61c /*   function heal(uint256 wad) external; */) {

        // Woe_ := Woe
        let Woe_ := sload(6)

        // rad := wad * 10^27
        let rad := umul(calldataload(4), 1000000000000000000000000000)

        // iff wad <= Joy() && wad <= Woe && int(rad) >= 0
        if or(or(gt(calldataload(4), Joy()), gt(calldataload(4), Woe_)), slt(rad, 0)) { revert(0, 0) }

        // set Woe = Woe_ - wad
        sstore(5, usub(Woe_, calldataload(4)))

        // put bytes4(keccak256("heal(bytes32,bytes32,int256)")) << 28 bytes
        mstore(0, 0x990a5f6300000000000000000000000000000000000000000000000000000000)
        // put this
        mstore(4, address)
        // put this
        mstore(36, address)
        // put rad
        mstore(68, rad)
        // iff vat.call("heal(bytes32,bytes32,int256)", this, this, rad) != 0
        if iszero(call(gas, sload(1), 0, 0, 100, 0, 0)) { revert(0, 0) }

        stop()
      }
      if eq(sig, 0x2506855a /*   function kiss(uint256 wad) external; */) {
        // Ash_ := Ash
        let Ash_ := sload(7)

        // rad := wad * 10^27
        let rad := umul(calldataload(4), 1000000000000000000000000000)

        // iff wad <= Ash_ && wad <= Joy() && int(wad) >= 0
        if or(or(gt(calldataload(4), Ash_), gt(calldataload(4), Joy())), slt(rad, 0)) { revert(0, 0) }

        // set Ash = Ash_ - wad
        sstore(6, usub(Ash_, calldataload(4)))

        // put bytes4(keccak256("heal(bytes32,bytes32,int256)")) << 28 bytes
        mstore(0, 0x990a5f6300000000000000000000000000000000000000000000000000000000)
        // put this
        mstore(4, address)
        // put this
        mstore(36, address)
        // put rad
        mstore(68, rad)
        // iff vat.call("heal(bytes32,bytes32,int256)", this, this, rad) != 0
        if iszero(call(gas, sload(1), 0, 0, 100, 0, 0)) { revert(0, 0) }

        stop()
      }
      if eq(sig, 0x697efb78 /*   function fess(uint256 tab) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(4, era())

        // set sin[era()] += tab
        sstore(hash_0, uadd(sload(hash_0), calldataload(4)))

        // set Sin += tab
        sstore(5, uadd(sload(5), calldataload(4)))

        stop()
      }
      if eq(sig, 0x35aee16f /*   function flog(uint48 era_) external; */) {

        // iff era_ + wait <= era()
        if gt(uadd(calldataload(4), sload(8)), era()) { revert(0, 0) }

        let hash_0 := hash2(4, calldataload(4))

        // sin_era_ := sin[era_]
        let sin_era_ := sload(hash_0)

        // set Sin -= sin_era_
        sstore(5, usub(sload(5), sin_era_))

        // set Woe += sin_era_
        sstore(6, uadd(sload(6), sin_era_))

        // set sin[era_] = 0
        sstore(hash_0, 0)

        stop()
      }
      if eq(sig, 0xbbbb0d7b /*   function flop() external returns (uint256); */) {

        // Woe_ := Woe
        let Woe_ := sload(6)

        let sump := sload(9)

        // iff Woe_ >= sump
        if lt(Woe_, sump) { revert(0, 0) }

        // iff Joy() == 0
        if iszero(eq(Joy(), 0)) { revert(0, 0) }

        // set Woe -= sump
        sstore(6, usub(Woe_, sump))

        // set Ash += sump
        sstore(7, uadd(sload(7), sump))

        // put bytes4(keccak256("kick(address,uint256,uint256)")) << 28 bytes
        mstore(0, 0xb7e9cd2400000000000000000000000000000000000000000000000000000000)
        // put this
        mstore(4, address)
        // put uint(-1)
        mstore(36, 115792089237316195423570985008687907853269984665640564039457584007913129639935)
        // put sump
        mstore(68, sump)
        // iff row.call("kick(address,uint256, uint256)", this, uint(-1), sump) != 0
        if iszero(call(gas, sload(3), 0, 0, 100, 64, 32)) { revert(0, 0) }

        return(64, 32)
      }
      if eq(sig, 0x0e01198b /*   function flap() external returns (uint256); */) {
        // bump := bump
        let bump := sload(10)

        // iff Joy() >= Awe() + bump + hump
        if lt(Joy(), uadd(uadd(Awe(), bump), sload(11))) { revert(0, 0) }

        // iff Woe == 0
        if iszero(eq(sload(6), 0)) { revert(0, 0) }

        // put bytes4(keccak256("dai()")) << 28 bytes
        mstore(0, 0xf4b9fa7500000000000000000000000000000000000000000000000000000000)
        // iff cow.call("dai()") != 0
        if iszero(call(gas, sload(2), 0, 0, 4, 64, 32)) { revert(0, 0) }

        // cow_dai := cow.dai()
        let cow_dai := mload(64)

        // put bytes4(keccak256("hope(address)")) << 28 bytes
        mstore(0, 0xa3b22fc400000000000000000000000000000000000000000000000000000000)
        // put cow
        mstore(4, sload(2))
        // iff cow_dai.call("hope(address)", cow) != 0
        if iszero(call(gas, cow_dai, 0, 0, 36, 0, 0)) { revert(0, 0) }

        // put bytes4(keccak256("kick(address,uint256,uint256)")) << 28 bytes
        mstore(0, 0xb7e9cd2400000000000000000000000000000000000000000000000000000000)
        // put this
        mstore(4, 0)
        // put bump
        mstore(36, bump)
        // put 0
        mstore(68, 0)
        // iff cow.call("kick(address,uint256, uint256)", this, bump, 0) != 0
        if iszero(call(gas, sload(2), 0, 0, 100, 64, 32)) { revert(0, 0) }

        // id := cow.kick(this, bump, 0)
        let id := mload(64)

        // put bytes4(keccak256("nope(address)")) << 28 bytes
        mstore(0, 0xdc4d20fa00000000000000000000000000000000000000000000000000000000)
        // put cow
        mstore(4, sload(2))
        // iff cow_dai.call("nope(address)", cow) != 0
        if iszero(call(gas, cow_dai, 0, 0, 36, 0, 0)) { revert(0, 0) }

        mstore(64, id)
        return(64, 32)
      }

      // failed to select any of the public methods:
      revert(0, 0)

      function era() -> era_ {
        // era_ := timestamp
        // put bytes4(keccak256("era()")) << 28 bytes
        mstore(0, 0x143e55e000000000000000000000000000000000000000000000000000000000)
        // iff this.call("era()") != 0
        if iszero(call(gas, address, 0, 0, 4, 0, 32)) { revert(0, 0) }

        // era_ := this.era()
        era_ := mload(0)
      }
      function Awe() -> wad {
        // wad := Sin + Woe + Ash
        wad := uadd(uadd(sload(6), sload(6)), sload(7))
      }
      function Joy() -> wad {
        // put bytes4(keccak256("dai(bytes32)")) << 28 bytes
        mstore(0, 0xf53e4e6900000000000000000000000000000000000000000000000000000000)
        // put this
        mstore(4, address)
        // iff vat.call("dai(bytes32)", this) != 0
        if iszero(call(gas, sload(1), 0, 0, 36, 0, 32)) { revert(0, 0) }

        // vat_dai := vat.dai(this)
        let vat_dai := mload(0)

        // iff vat_dai >= 0
        if lt(vat_dai, 0) { revert(0, 0) }

        // wad := vat_dai / 10**27
        wad := div(vat_dai, 1000000000000000000000000000)
      }

      function pleb() -> x {
        x := iszero(eq(1, sload(hash2(0, caller))))
      }
      // map[key] translates to hash(key ++ idx(map))
      function hash2(b, i) -> h {
        mstore(0, i)
        mstore(32, b)
        h := keccak256(0, 64)
      }
      function uadd(x, y) -> z {
        z := add(x, y)
        if lt(z, x) { revert(0, 0) }
      }
      function usub(x, y) -> z {
        z := sub(x, y)
        if gt(z, x) { revert(0, 0) }
      }
      function umul(x, y) -> z {
        z := mul(x, y)
        // iff y == 0 || z / y == x
        if iszero(or(eq(y, 0), eq(div(z, y), x))) { revert(0, 0) }
      }
    }
  }
}
