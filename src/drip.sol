pragma solidity ^0.4.24;

contract VatLike {
    function ilks(bytes32) public returns (uint,uint);
    function fold(bytes32,bytes32,int) public;
}

contract Drip {
    VatLike vat;
    struct Ilk {
        bytes32 vow;
        uint256 tax;
        uint48  rho;
    }
    mapping (bytes32 => Ilk) public ilks;

    modifier auth { _; }  // todo

    function era() public view returns (uint48) { return uint48(now); }

    constructor(address vat_) public { vat = VatLike(vat_); }

    function file(bytes32 ilk, bytes32 vow, uint tax) public auth {
        Ilk storage i = ilks[ilk];
        require(i.rho == era());
        i.vow = vow;
        i.tax = tax;
    }

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
    function drip(bytes32 ilk) public {
        Ilk storage i = ilks[ilk];
        if ( i.rho == era() ) return;
        if ( i.tax == ONE   ) return;
        require(era() >= i.rho);
        (uint rate, uint Art) = vat.ilks(ilk); Art;
        vat.fold(ilk, i.vow, diff(rmul(rpow(i.tax, era() - i.rho, ONE), rate), rate));
        i.rho = era();
    }
}
