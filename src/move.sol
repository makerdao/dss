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
    function move(bytes32 src, bytes32 dst, uint rad) public {
        require(bytes20(src) == bytes20(msg.sender) || can[address(bytes20(src))][msg.sender] == 1);
        require(int(rad) >= 0);
        vat.flux(ilk, src, dst, int(rad));
    }
    function push(bytes32 urn, uint rad) public {
        require(int(rad) >= 0);
        bytes32 guy = bytes32(bytes20(msg.sender));
        vat.flux(ilk, guy, urn, int(rad));
    }
}

contract DaiMove {
    VatLike public vat;
    constructor(address vat_) public {
        vat = VatLike(vat_);
    }
    mapping(address => mapping (address => uint)) public can;
    function hope(address guy) public { can[msg.sender][guy] = 1; }
    function nope(address guy) public { can[msg.sender][guy] = 0; }
    function move(bytes32 src, bytes32 dst, uint rad) public {
        require(bytes20(src) == bytes20(msg.sender) || can[address(bytes20(src))][msg.sender] == 1);
        require(int(rad) >= 0);
        vat.move(src, dst, int(rad));
    }
}
