pragma solidity ^0.4.24;

import "ds-note/note.sol";

contract VatLike {
    function ilks(bytes32) public returns (uint,uint);
    function fold(bytes32,bytes32,int) public;
}

contract Drip is DSNote {
    // --- Administration ---
    mapping (address => bool) public wards;
    function rely(address guy) public auth { wards[guy] = true;  }
    function deny(address guy) public auth { wards[guy] = false; }
    modifier auth { require(wards[msg.sender]); _;  }

    // --- Data ---
    struct Ilk {
        bytes32 vow;
        uint256 tax;
        uint48  rho;
    }

    mapping (bytes32 => Ilk) public ilks;
    VatLike                  public vat;
    uint256                  public repo;

    function era() public view returns (uint48) { return uint48(now); }

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = true;
        vat = VatLike(vat_);
    }

    // --- Math ---
    function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
      assembly {
        switch x case 0 {switch n case 0 {z := base} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := base } default { z := x }
          let half := div(base, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, base)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, base)
            }
          }
        }
      }
    }
    uint256 constant ONE = 10 ** 27;
    function diff(uint x, uint y) internal pure returns (int z) {
        z = int(x) - int(y);
        require(int(x) >= 0 && int(y) >= 0);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / ONE;
    }

    // --- Administration ---
    function file(bytes32 ilk, bytes32 vow, uint tax) public note auth {
        Ilk storage i = ilks[ilk];
        require(i.rho == era() || i.tax == 0);
        i.vow = vow;
        i.tax = tax;
    }
    function file(bytes32 what, uint data) public note auth {
        if (what == "repo") repo = data;
    }

    // --- Stability Fee Collection ---
    function drip(bytes32 ilk) public note {
        Ilk storage i = ilks[ilk];
        require(era() >= i.rho);
        (uint rate, uint Art) = vat.ilks(ilk); Art;
        vat.fold(ilk, i.vow, diff(rmul(rpow(repo + i.tax, era() - i.rho, ONE), rate), rate));
        i.rho = era();
    }
}
