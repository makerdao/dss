pragma solidity >=0.5.0;

import "ds-note/note.sol";

contract VatLike {
    function ilks(bytes32) public returns (uint,uint,uint,uint);
    function fold(bytes32,bytes32,int) public;
}

contract Jug is DSNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) public note auth { wards[guy] = 1; }
    function deny(address guy) public note auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- Data ---
    struct Ilk {
        uint256 tax;
        uint48  rho;
    }

    mapping (bytes32 => Ilk) public ilks;
    VatLike                  public vat;
    bytes32                  public vow;
    uint256                  public repo;

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
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
    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }
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
    function init(bytes32 ilk) public note auth {
        Ilk storage i = ilks[ilk];
        require(i.tax == 0);
        i.tax = ONE;
        i.rho = uint48(now);
    }
    function file(bytes32 ilk, bytes32 what, uint data) public note auth {
        Ilk storage i = ilks[ilk];
        if (what == "tax") i.tax = data;
    }
    function file(bytes32 what, uint data) public note auth {
        if (what == "repo") repo = data;
    }
    function file(bytes32 what, bytes32 data) public note auth {
        if (what == "vow") vow = data;
    }

    // --- Stability Fee Collection ---
    function drip(bytes32 ilk) public note {
        Ilk storage i = ilks[ilk];
        require(now >= i.rho);
        (uint take, uint rate, uint Ink, uint Art) = vat.ilks(ilk); Art; Ink; take;
        vat.fold(ilk, vow, diff(rmul(rpow(add(repo, i.tax), now - i.rho, ONE), rate), rate));
        i.rho = uint48(now);
    }
}
