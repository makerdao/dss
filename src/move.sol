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

pragma solidity >=0.5.0;

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
    mapping(address => mapping (address => uint)) public can;
    function hope(address guy) public { can[msg.sender][guy] = 1; }
    function nope(address guy) public { can[msg.sender][guy] = 0; }
    function move(bytes32 src, bytes32 dst, uint wad) public {
        require(bytes20(src) == bytes20(msg.sender) || can[address(bytes20(src))][msg.sender] == 1);
        require(int(wad) >= 0);
        vat.flux(ilk, src, dst, int(wad));
    }
    function push(bytes32 urn, uint wad) public {
        bytes32 guy = bytes32(bytes20(msg.sender));
        require(int(wad) >= 0);
        vat.flux(ilk, guy, urn, int(wad));
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
    mapping(address => mapping (address => uint)) public can;
    function hope(address guy) public { can[msg.sender][guy] = 1; }
    function nope(address guy) public { can[msg.sender][guy] = 0; }
    function move(bytes32 src, bytes32 dst, uint wad) public {
        require(bytes20(src) == bytes20(msg.sender) || can[address(bytes20(src))][msg.sender] == 1);
        vat.move(src, dst, mul(ONE, wad));
    }
}
