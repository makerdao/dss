pragma solidity >=0.5.0;

import "ds-math/math.sol";
import "ds-note/note.sol";

contract VatLike {
    function file(bytes32, bytes32, uint) public;
}

contract PipLike {
    function peek() public returns (bytes32, bool);
}

contract Spotter is DSMath, DSNote {
    VatLike public vat;
    mapping (bytes32 => Ilk) public ilks;
    uint256 public par = RAY; // ref per dai

    struct Ilk {
        PipLike pip;
        uint256 mat;
    }

    event Poke(
      bytes32 ilk,
      bytes32 val,
      uint256 spot
    );

    mapping (address => uint) public wards;
    function rely(address guy) public note auth { wards[guy] = 1;  }
    function deny(address guy) public note auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
    }

    // --- Administration ---
    function file(bytes32 ilk, address pip_) public note auth {
        ilks[ilk].pip = PipLike(pip_);
    }

    function file(bytes32 what, uint data) public note auth {
        if (what == "par") par = data;
    }

    function file(bytes32 ilk, bytes32 what, uint data) public note auth {
        if (what == "mat") ilks[ilk].mat = data;
    }

    // --- Update value ---
    function poke(bytes32 ilk) public {
        (bytes32 val, bool zzz) = ilks[ilk].pip.peek();
        if (zzz) {
            uint256 spot = rdiv(rdiv(mul(uint(val), 10 ** 9), par), ilks[ilk].mat);
            vat.file(ilk, "spot", spot);
            emit Poke(ilk, val, spot);
        }
    }
}
