/// join.sol -- Basic token adapters

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

pragma solidity ^0.4.20;

contract GemLike {
    function move(address,address,uint) public;  // i.e. transferFrom
}

contract Fluxing {
    function slip(bytes32,bytes32,int) public;
}

contract Adapter {
    Fluxing public vat;
    bytes32 public ilk;
    GemLike public gem;
    constructor(address vat_, bytes32 ilk_, address gem_) public {
        vat = Fluxing(vat_);
        ilk = ilk_;
        gem = GemLike(gem_);
    }
    function join(uint wad) public {
        require(int(wad) >= 0);
        gem.move(msg.sender, this, wad);
        vat.slip(ilk, bytes32(msg.sender), int(wad));
    }
    function exit(uint wad) public {
        require(int(wad) >= 0);
        gem.move(this, msg.sender, wad);
        vat.slip(ilk, bytes32(msg.sender), -int(wad));
    }
}
