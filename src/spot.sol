/// spot.sol -- Spotter

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

pragma solidity >=0.5.0;

import "./lib.sol";

contract VatLike {
    function file(bytes32, bytes32, uint) external;
}

contract PipLike {
    function peek() external returns (bytes32, bool);
}

contract Spotter is DSNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external note auth { wards[guy] = 1;  }
    function deny(address guy) external note auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- Data ---
    struct Ilk {
        PipLike pip;
        uint256 mat;
    }

    mapping (bytes32 => Ilk) public ilks;

    VatLike public vat;
    uint256 public par; // ref per dai

    // --- Events ---
    event Poke(
      bytes32 ilk,
      bytes32 val,
      uint256 spot
    );

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        par = ONE;
    }

    // --- Math ---
    uint constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, ONE) / y;
    }

    // --- Administration ---
    function file(bytes32 ilk, address pip_) external note auth {
        ilks[ilk].pip = PipLike(pip_);
    }
    function file(bytes32 what, uint data) external note auth {
        if (what == "par") par = data;
    }
    function file(bytes32 ilk, bytes32 what, uint data) external note auth {
        if (what == "mat") ilks[ilk].mat = data;
    }

    // --- Update value ---
    function poke(bytes32 ilk) external {
        (bytes32 val, bool zzz) = ilks[ilk].pip.peek();
        if (zzz) {
            uint256 spot = rdiv(rdiv(mul(uint(val), 10 ** 9), par), ilks[ilk].mat);
            vat.file(ilk, "spot", spot);
            emit Poke(ilk, val, spot);
        }
    }
}
