/// move.sol -- Basic token fungibility

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
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

pragma solidity ^0.4.24;

contract VatLike {
    function move(bytes32,bytes32,int) public;
    function flux(bytes32,bytes32,bytes32,int) public;
}

contract GemMove {
    VatLike public vat;
    bytes32 public ilk;
    constructor(address vat_, bytes32 ilk_) public {
        vat = VatLike(vat_);
        ilk = ilk_;
    }
    mapping(address => mapping (address => bool)) public can;
    function hope(address guy) public { can[msg.sender][guy] = true; }
    function nope(address guy) public { can[msg.sender][guy] = false; }
    function move(address src, address dst, uint wad) public {
        require(int(wad) >= 0);
        require(src == msg.sender || can[src][msg.sender]);
        vat.flux(ilk, bytes32(src), bytes32(dst), int(wad));
    }
    function push(bytes32 urn, uint wad) public {
        require(int(wad) >= 0);
        vat.flux(ilk, bytes32(msg.sender), urn, int(wad));
    }
}

contract DaiMove {
    VatLike public vat;
    constructor(address vat_) public {
        vat = VatLike(vat_);
    }
    uint constant ONE = 10 ** 27;
    function mul(uint x, uint y) internal pure returns (int z) {
        z = int(x * y);
        require(int(z) >= 0);
        require(y == 0 || uint(z) / y == x);
    }
    mapping(address => mapping (address => bool)) public can;
    function hope(address guy) public { can[msg.sender][guy] = true; }
    function nope(address guy) public { can[msg.sender][guy] = false; }
    function move(address src, address dst, uint wad) public {
        require(int(wad) >= 0);
        require(src == msg.sender || can[src][msg.sender]);
        vat.move(bytes32(src), bytes32(dst), mul(ONE, wad));
    }
}
