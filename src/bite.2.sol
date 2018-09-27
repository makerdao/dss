/// bite.2.sol -- Dai liquidation module

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

interface CatI {
  function wards(address guy) external returns (bool);
  function rely(address guy) external;
  function deny(address guy) external;
  function ilks(bytes32 ilk) external returns (address flip, uint256 chop, uint256 lump);
  function flips(uint256 n) external returns (bytes32 ilk, bytes32 lad, uint256 ink, uint256 tab);
  function nflip() external returns (uint256);
  function live() external returns (uint256);
  function vat() external returns (address);
  function pit() external returns (address);
  function vow() external returns (address);
  function file(bytes32 what, address data) external;
  function file(bytes32 ilk, bytes32 what, uint256 data) external;
  function file(bytes32 ilk, bytes32 what, address flip) external;
  function bite(bytes32 ilk, bytes32 urn) external returns (uint256);
  function flip(uint256 n, uint256 wad) external returns (uint256);
}

contract Cat {
  constructor (address vat_) public {
    assembly {
      let hash_0 := hash2(0, caller)

      // set wards[caller] = true
      sstore(hash_0, 1)

      codecopy(0, sub(codesize, 32), 32)

      // set vat = vat_
      sstore(5, mload(0))

      // set live = 1
      sstore(4, 1)

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
      if eq(sig, 0xd9638d36 /*   function ilks(bytes32 ilk) external returns (address flip, uint256 chop, uint256 lump); */) {
        let hash_0 := hash2(1, calldataload(4))

        mstore(64, sload(hash_0))
        mstore(96, sload(add(hash_0, 1)))
        mstore(128, sload(add(hash_0, 2)))
        return(64, 96)
      }
      if eq(sig, 0x70d9235a /*   function flips(uint256 n) external returns (bytes32 ilk, bytes32 urn, uint256 ink, uint256 tab); */) {
        let hash_0 := hash2(2, calldataload(4))

        mstore(64, sload(hash_0))
        mstore(96, sload(add(hash_0, 1)))
        mstore(128, sload(add(hash_0, 2)))
        mstore(160, sload(add(hash_0, 3)))
        return(64, 128)
      }
      if eq(sig, 0x76181a51 /*   function nflip() external returns (uint256); */) {
        mstore(64, sload(3))
        return(64, 32)
      }
      if eq(sig, 0x957aa58c /*   function live() external returns (uint256); */) {
        mstore(64, sload(4))
        return(64, 32)
      }
      if eq(sig, 0x36569e77 /*   function vat() external returns (address); */) {
        mstore(64, sload(5))
        return(64, 32)
      }
      if eq(sig, 0x56cebd18 /*   function pit() external returns (address); */) {
        mstore(64, sload(6))
        return(64, 32)
      }
      if eq(sig, 0x626cb3c5 /*   function vow() external returns (address); */) {
        mstore(64, sload(7))
        return(64, 32)
      }
      if eq(sig, 0xd4e8be83 /*   function file(bytes32 what, address data) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        // if what == "pit" set pit = data
        if eq(calldataload(4), "pit") { sstore(6, calldataload(36)) }

        // if what == "vow" set vow = data
        if eq(calldataload(4), "vow") { sstore(7, calldataload(36)) }

        stop()
      }
      if eq(sig, 0x1a0b287e /*   function file(bytes32 ilk, bytes32 what, uint256 data) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(1, calldataload(4))

        // if what == "chop" set ilks[ilk].chop = data
        if eq(calldataload(36), "chop") { sstore(add(hash_0, 1), calldataload(68)) }

        // if what == "lump" set ilks[ilk].lump = data
        if eq(calldataload(36), "lump") { sstore(add(hash_0, 2), calldataload(68)) }

        stop()
      }
      if eq(sig, 0xebecb39d /*   function file(bytes32 ilk, bytes32 what, address flip) external; */) {

        // iff auth
        if pleb() { revert(0, 0) }

        let hash_0 := hash2(1, calldataload(4))

        // if what == "flip" set ilks[ilk].flip = flip
        if eq(calldataload(36), "flip") { sstore(hash_0, calldataload(68)) }

        stop()
      }
      if eq(sig, 0x72f7b593 /*   function bite(bytes32 ilk, bytes32 urn) external returns (uint256); */) {

        // iff live == 1
        if iszero(eq(sload(4), 1)) { revert(0, 0) }

        // put bytes4(keccak256("ilks(bytes32)")) << 28 bytes
        mstore(0, 0xd9638d3600000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, calldataload(4))
        // iff vat.call("ilks(bytes32)", ilk) != 0
        if iszero(call(gas, sload(5), 0, 0, 36, 0, 128)) { revert(0, 0) }

        // rate, Art := vat.ilks(ilk)
        let rate := mload(32)
        let Art := mload(96)

        // put bytes4(keccak256("ilks(bytes32)")) << 28 bytes
        mstore(0, 0xd9638d3600000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, calldataload(4))
        // iff pit.call("ilks(bytes32)", ilk) != 0
        if iszero(call(gas, sload(6), 0, 0, 36, 0, 64)) { revert(0, 0) }

        // spot, line := pit.ilks(ilk)
        let spot := mload(0)
        let line := mload(32)

        // put bytes4(keccak256("urns(bytes32,bytes32)")) << 28 bytes
        mstore(0, 0x26e2748200000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, calldataload(4))
        // put urn
        mstore(36, calldataload(36))
        // iff vat.call("urns(bytes32,bytes32)", ilk, urn) != 0
        if iszero(call(gas, sload(5), 0, 0, 68, 0, 64)) { revert(0, 0) }

        // ink, art := vat.urns(ilk, msg.sender)
        let ink := mload(0)
        let art := mload(32)

        // tab := rmul(art, rate)
        let tab := rmul(art, rate)

        // vow := vow
        let vow := sload(7)

        // iff rmul(ink, spot) < tab
        if iszero(lt(rmul(ink, spot), tab)) { revert(0, 0) }

        // put bytes4(keccak256("grab(bytes32,bytes32,bytes32,int256,int256)")) << 28 bytes
        mstore(0, 0x3690ae4c00000000000000000000000000000000000000000000000000000000)
        // put ilk
        mstore(4, calldataload(4))
        // put urn
        mstore(36, calldataload(36))
        // put this
        mstore(68, address)
        // put vow
        mstore(100, vow)
        // put -ink
        mstore(132, sub(0, ink))
        // put -art
        mstore(164, sub(0, art))
        // iff vat.call("grab(bytes32,bytes32,bytes32,bytes32,int256,int256)", ilk, urn, this, vow, -ink, -art) != 0
        if iszero(call(gas, sload(5), 0, 0, 196, 0, 0)) { revert(0, 0) }

        // put bytes4(keccak256("fess(uint256)")) << 28 bytes
        mstore(0, 0x697efb7800000000000000000000000000000000000000000000000000000000)
        // put tab
        mstore(4, tab)
        // iff vow.call("fess(uint256)", tab) != 0
        if iszero(call(gas, vow, 0, 0, 36, 0, 0)) { revert(0, 0) }

        // nflip_ := nflip
        let nflip_ := sload(3)

        let hash_0 := hash2(2, nflip_)

        // set flips[nflip] = (ilk, urn, ink, tab)
        sstore(hash_0, calldataload(4))
        sstore(add(hash_0, 1), calldataload(36))
        sstore(add(hash_0, 2), ink)
        sstore(add(hash_0, 3), tab)

        // nflip++
        sstore(5, uadd(nflip_, 1))

        mstore(64, nflip_)
        return(64, 32)
      }
      if eq(sig, 0xe6f95917 /*   function flip(uint256 n, uint256 wad) external returns (uint256); */) {

        // iff live == 1
        if iszero(eq(sload(4), 1)) { revert(0, 0) }

        let hash_0 := hash2(2, calldataload(4))

        // tab = flips[n].tab
        let tab := sload(add(hash_0, 3))

        // iff wad <= tab
        if gt(calldataload(36), tab) { revert(0, 0) }

        let hash_1 := hash2(1, sload(hash_0))

        // lump := ilks[ilk].lump
        let lump := sload(add(hash_1, 2))

        // iff (wad == lump || (wad < lump && wad == tab))
        if iszero(or(eq(calldataload(36), lump), and(lt(calldataload(36), lump), eq(calldataload(36), tab)))) { revert(0, 0) }

        // ink_ = flips[n].ink
        let ink_ := sload(add(hash_0, 2))

        // ink := ink_ * wad / tab
        let ink := div(umul(ink_, calldataload(36)), tab)

        // set f.tab -= wad
        sstore(add(hash_0, 3), sub(tab, calldataload(36)))

        // set f.ink -= ink
        sstore(add(hash_0, 2), sub(ink_, ink))

        // flip := ilks[ilk].flip
        let flip := sload(hash_1)

        // put bytes4(keccak256("gem()")) << 28 bytes
        mstore(0, 0x7bd2bea700000000000000000000000000000000000000000000000000000000)
        // iff flip.call("gem()") != 0
        if iszero(call(gas, flip, 0, 0, 4, 64, 32)) { revert(0, 0) }

        // flip_gem := ilks[ilk].flip.gem()
        let flip_gem := mload(64)

        // put bytes4(keccak256("hope(address)")) << 28 bytes
        mstore(0, 0xa3b22fc400000000000000000000000000000000000000000000000000000000)
        // put flip
        mstore(4, flip)
        // iff flip_gem.call("hope(address)", flip) != 0
        if iszero(call(gas, flip_gem, 0, 0, 36, 0, 0)) { revert(0, 0) }

        // put bytes4(keccak256("kick(bytes32,address,uint256,uint256,uint256)")) << 28 bytes
        mstore(0, 0xeae19d9e00000000000000000000000000000000000000000000000000000000)
        // put flips[n].urn
        mstore(4, sload(add(hash_0, 1)))
        // put vow
        mstore(36, sload(7))
        // put rmul(wad, ilks[flips[n].ilk].chop)
        mstore(68, rmul(calldataload(36), sload(add(hash_1, 1))))
        // put ink
        mstore(100, ink)
        // put 0
        mstore(132, 0)
        // iff ilks[flips[n].ilk].flip.call("kick(bytes32,address,uint256,uint256,uint256)", flips[n].urn, vow, rmul(wad, ilks[flips[n].ilk].chop), ink, 0) != 0
        if iszero(call(gas, flip, 0, 0, 164, 64, 32)) { revert(0, 0) }

        let id := mload(64)

        // put bytes4(keccak256("nope(address)")) << 28 bytes
        mstore(0, 0xdc4d20fa00000000000000000000000000000000000000000000000000000000)
        // put flip
        mstore(4, flip)
        // iff cow_dai.call("nope(address)", flip) != 0
        if iszero(call(gas, flip_gem, 0, 0, 36, 0, 0)) { revert(0, 0) }

        mstore(64, id)
        return(64, 32)
      }

      // failed to select any of the public methods:
      revert(0, 0)

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
      function umul(x, y) -> z {
        z := mul(x, y)
        if iszero(or(eq(y, 0), eq(div(z, y), x))) { revert(0, 0) }
      }
      function rmul(x, y) -> z {
        z := mul(x, y)
        if iszero(eq(y, 0)) { if iszero(eq(div(z, y), x)) { revert(0, 0) } }
        z := div(z, 1000000000000000000000000000)
      }
    }
  }
}
