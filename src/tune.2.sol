// Copyright (C) 2018 AGPL

pragma solidity ^0.4.24;

interface VatI {
  function grab(bytes32 ilk, address lad, address vow, int256 dink, int256 dart) external;
  function era() external returns (uint48);
  function urns(bytes32 ilk, address lad) external returns (int256 gem, int256 ink, int256 art);
  function vice() external returns (int256);
  function ilks(bytes32 ilk) external returns (int256 rate, int256 Art);
  function dai(address lad) external returns (int256);
  function slip(bytes32 ilk, address guy, int256 wad) external;
  function file(bytes32 ilk, bytes32 what, int256 risk) external;
  function tune(bytes32 ilk, address lad, int256 dink, int256 dart) external;
  function fold(bytes32 ilk, address vow, int256 rate) external;
  function move(address src, address dst, int256 rad) external;
  function Tab() external returns (int256);
  function root() external returns (address);
  function heal(address u, address v, int256 rad) external;
  function sin(address lad) external returns (int256);
}

contract Vat is VatI {
  constructor () public {
    assembly {
      sstore(0, caller)
    }
  }   
  function () public {
    assembly {
      let sig := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      if lt(sig, 0x7cdd3fde/*   function slip(bytes32 ilk, address guy, int256 wad) external; */) {
        if lt(sig, 0x3af39c21/*   function undefined() external; */) {
          if lt(sig, 0x2424be5c/*   function urns(bytes32 , address ) external returns (int256 gem, int256 ink, int256 art); */) {
            if eq(sig, 0x11045bee /*   function grab(bytes32 ilk, address lad, address vow, int256 dink, int256 dart) external; */)
	    {
                let hash_0 := hash3(4, calldataload(4), calldataload(36))

		// set urns[ilk][lad].ink += dink
		sstore(add(hash_0, 1), iadd(sload(add(hash_0, 1)), calldataload(100)))

		// set urns[ilk][lad].art += dart
		sstore(add(hash_0, 2), iadd(sload(add(hash_0, 2)), calldataload(132)))

		let hash_1 := hash2(3, calldataload(4))

		// set ilks[ilk].Art += dart
		sstore(add(hash_1, 1), iadd(sload(add(hash_1, 1)), calldataload(132)))

		let hash_2 := hash2(2, calldataload(68))

		// set sin[vow] -= i.rate * dart
		sstore(hash_2, iadd(sload(hash_2), imul(sload(hash_1), calldataload(132))))

		// set vice -= i.rate * dart
		sstore(6, iadd(sload(6), imul(sload(hash_1), calldataload(132))))

		stop()
            }
            if eq(sig, 0x143e55e0 /*   function era() external returns (uint48); */) {
	      mstore(64, timestamp)
	      return(64, 6)
            }
          }
          if eq(sig, 0x2424be5c /*   function urns(bytes32 , address ) external returns (int256 gem, int256 ink, int256 art); */)
	  {
	      let hash_0 := hash2(4, calldataload(4))
	      mstore(64, sload(hash_0))
	      mstore(96, sload(add(hash_0, 1)))
	      mstore(128, sload(add(hash_0, 2)))
	      return(64, 96)
          }
          if eq(sig, 0x2d61a355 /*   function vice() external returns (int256); */) {
	     mstore(64, sload(6))
	     return(64, 32)
          }
        }
        if lt(sig, 0x673c17da/*   function Art(bytes32 ilk, address lad) external returns (int256); */) {
        }
        if eq(sig, 0x6c25b346 /*   function dai(address ) external returns (int256); */) {
	    let hash_0 := hash2(1, calldataload(4))
	    mstore(64, sload(hash_0))
	    return(64, 32)
        }
      }
      if lt(sig, 0xd9638d36/*   function ilks(bytes32 ) external returns (int256 rate, int256 Art); */) {
        if lt(sig, 0xa4593c52/*   function tune(bytes32 ilk, address lad, int256 dink, int256 dart) external; */) {
          if eq(sig, 0x7cdd3fde /*   function slip(bytes32 ilk, address guy, int256 wad) external; */)
	  {
	    let hash_0 := hash3(4, calldataload(4), calldataload(36))

	    // set urns[ilk][guy].gem = urns[ilk][guy].gem + wad
	    sstore(hash_0, iadd(sload(hash_0), calldataload(68)))

	    stop()
	  }
          if eq(sig, 0x815d245d /*   function file(bytes32 ilk, bytes32 what, int256 risk) external; */)
	  {
	    let hash_0 := hash2(3, calldataload(4))
	    // if what == "rate" set ilks[ilk].rate = risk
	    if eq(calldataload(36), "rate") { sstore(hash_0, calldataload(68)) }

	    stop()
          }
        }
        if eq(sig, 0xa4593c52 /*   function tune(bytes32 ilk, address lad, int256 dink, int256 dart) external; */)
	{
            let hash_0 := hash3(4, calldataload(4), calldataload(36))

	    // set urns[ilk][lad].gem -= dink
	    sstore(hash_0, isub(sload(hash_0), calldataload(68)))

	    // set urns[ilk][lad].ink += dink
	    sstore(add(hash_0, 1), iadd(sload(add(hash_0, 1)), calldataload(68)))

	    // set urns[ilk][lad].art += dart
	    sstore(add(hash_0, 2), iadd(sload(add(hash_0, 2)), calldataload(100)))

	    let hash_1 := hash2(3, calldataload(4))

	    // set ilks[ilk].Art += dart
	    sstore(add(hash_1, 1), iadd(sload(add(hash_1, 1)), calldataload(100)))

	    let hash_2 := hash2(1, calldataload(36))

	    // set dai[lad] += i.rate * dart
	    sstore(hash_2, iadd(sload(hash_2), imul(sload(hash_1), calldataload(100))))

	    // set Tab += i.rate * dart
	    sstore(5, iadd(sload(5), imul(sload(hash_1), calldataload(100))))

	    stop()
        }
        if eq(sig, 0xb65337df /*   function fold(bytes32 ilk, address vow, int256 rate) external; */)
	{
	    let hash_0 := hash2(3, calldataload(4))

	    // set i.rate += rate
	    sstore(hash_0, iadd(sload(hash_0), calldataload(68)))

	    // rad := i.Art * rate
	    let rad := imul(sload(add(hash_0, 1)), calldataload(68))

	    let hash_1 := hash2(1, calldataload(36))

	    // set dai[vow] += rad
	    sstore(hash_1, iadd(sload(hash_1), rad))

	    // set Tab += rad
	    sstore(5, iadd(sload(5), rad))

	    stop()
        }
        if eq(sig, 0xbb35783b /*   function move(address src, address dst, int256 rad) external; */) {

	   let hash_0 := hash2(1, calldataload(4))

	   // dai_src := dai[src] - rad
	   let dai_src := isub(sload(hash_0), calldataload(68))

	   // iff dai_src >= 0
	   if slt(dai_src, 0) { revert(0, 0) }

	   // set dai[src] = dai_src
	   sstore(hash_0, dai_src)

	   let hash_1 := hash2(1, calldataload(36))

	   // dai_dst := dai[dst] + rad
	   let dai_dst := iadd(sload(hash_1), calldataload(68))
	   
	   // iff dai_dst >= 0
	   if slt(dai_dst, 0) { revert(0, 0) }

	   // set dai[dst] = dai_dst
	   sstore(hash_1, dai_dst)

	   stop()
        }
      }
      if lt(sig, 0xebf0c717/*   function root() external returns (address); */) {
        if eq(sig, 0xd9638d36 /*   function ilks(bytes32 ) external returns (int256 rate, int256 Art); */)
	{
	    let hash_0 := hash2(3, calldataload(4))
	    mstore(64, sload(hash_0))
	    mstore(96, sload(add(hash_0, 1)))
	    return(64, 64)
        }
        if eq(sig, 0xdc42e309 /*   function Tab() external returns (int256); */) {
	   mstore(64, sload(5))
	   return (64, 32)
        }
      }
      if eq(sig, 0xebf0c717 /*   function root() external returns (address); */) {
      	 mstore(64, sload(0))
	 return (64, 32)
      }
      if eq(sig, 0xee8cd748 /*   function heal(address u, address v, int256 rad) external; */) {
      	 let hash_0 := hash2(2, calldataload(4))

	 // sin_u := sin[u]
	 let sin_u := sload(hash_0)

	 // iff sin_u >= rad
	 if slt(sin_u, calldataload(68)) { revert(0, 0) }

	 let hash_1 := hash2(1, calldataload(36))

	 // dai_v := dai[v]
	 let dai_v := sload(hash_1)

	 // iff dai_v >= rad
	 if slt(dai_v, calldataload(68)) { revert(0, 0) }

	 // _vice := vice
	 let _vice := sload(6)

	 // iff _vice >= rad
	 if slt(_vice, calldataload(68)) { revert(0, 0) }

	 // _Tab := Tab
	 let _Tab := sload(5)

	 // iff _Tab >= rad
	 if slt(_Tab, calldataload(68)) { revert(0, 0) }

	 // set sin[u] = sin_u - rad
	 sstore(hash_0, isub(sin_u, calldataload(68)))

	 // set dai[v] = sin_u - rad
	 sstore(hash_1, isub(dai_v, calldataload(68)))

	 // set vice = _vice - rad
	 sstore(6, isub(_vice, calldataload(68)))

	 // set Tab = _Tab - rad
	 sstore(5, isub(_Tab, calldataload(68)))

	 stop()
      }
      if eq(sig, 0xf059212a /*   function sin(address ) external returns (int256); */) {
	 let hash_0 := hash2(2, calldataload(4))
	 mstore(64, sload(hash_0))
	 return(64, 32)
      }
      function hash2(b, i) -> h {
        mstore(0, b)
        mstore(32, i)
        h := keccak256(0, 64)
      }
      function hash3(b, i, j) -> h {
        mstore(0, b)
        mstore(32, i)
        mstore(0, keccak256(0, 64))
        mstore(32, j)
        h := keccak256(0, 64)
      }
      function iadd(x, y) -> z {
        z := add(x, y)
        if iszero(or(iszero(sgt(y, 0)), sgt(z, x))) { revert(0, 0) }
        if iszero(or(iszero(slt(y, 0)), slt(z, x))) { revert(0, 0) }
      }
      function isub(x, y) -> z {
        let minus_pow255 := sub(0, 57896044618658097711785492504343953926634992332820282019728792003956564819968)
      	if eq(y, minus_pow255) { revert(0, 0) }
	z := iadd(x, sub(0, y))
      }
      function imul(x, y) -> z {
        z := mul(x, y)
	let minus_pow255 := sub(0, 57896044618658097711785492504343953926634992332820282019728792003956564819968)
	if iszero(or(iszero(slt(y, 0)), iszero(eq(x, minus_pow255)))) { revert(0, 0) }
	if iszero(or(eq(y, 0), eq(div(z, y), x))) { revert(0, 0) }
    }
  }
}
}
