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

import "ds-note/note.sol";

contract GemLike {
    function transferFrom(address,address,uint) public returns (bool);
    function mint(address,uint) public;
    function burn(address,uint) public;
}

contract VatLike {
    function slip(bytes32,bytes32,int) public;
    function move(bytes32,bytes32,int) public;
    function flux(bytes32,bytes32,bytes32,int) public;
}

contract Adapter is DSNote {
    VatLike public vat;
    bytes32 public ilk;
    GemLike public gem;
    constructor(address vat_, bytes32 ilk_, address gem_) public {
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = GemLike(gem_);
    }
    function join(bytes32 urn, uint wad) public note {
        require(int(wad) >= 0);
        require(gem.transferFrom(msg.sender, this, wad));
        vat.slip(ilk, urn, int(wad));
    }
    function exit(address guy, uint wad) public note {
        require(int(wad) >= 0);
        require(gem.transferFrom(this, guy, wad));
        vat.slip(ilk, bytes32(msg.sender), -int(wad));
    }

    mapping(address => mapping (address => bool)) public can;
    function hope(address guy) public {
        can[msg.sender][guy] = true;
    }
    function move(address src, address dst, uint wad) public {
        require(int(wad) >= 0);
        require(can[src][msg.sender]);
        vat.flux(ilk, bytes32(src), bytes32(dst), int(wad));
    }
    function push(bytes32 urn, uint wad) public {
        require(int(wad) >= 0);
        vat.flux(bytes32(msg.sender), urn, int(wad));
    }
}

contract ETHAdapter is DSNote {
    VatLike public vat;
    bytes32 public ilk;
    constructor(address vat_, bytes32 ilk_) public {
        vat = VatLike(vat_);
        ilk = ilk_;
    }
    function join(bytes32 urn) public payable note {
        vat.slip(ilk, urn, int(msg.value));
    }
    function exit(address guy, uint wad) public note {
        require(int(wad) >= 0);
        vat.slip(ilk, bytes32(msg.sender), -int(wad));
        guy.transfer(wad);
    }

    mapping(address => mapping (address => bool)) public can;
    function hope(address guy, bool ok) public {
        can[msg.sender][guy] = ok;
    }
    function move(address src, address dst, uint wad) public {
        require(int(wad) >= 0);
        require(can[src][msg.sender]);
        vat.flux(ilk, bytes32(src), bytes32(dst), int(wad));
    }
}

contract DaiAdapter is DSNote {
    VatLike public vat;
    GemLike public dai;
    constructor(address vat_, address dai_) public {
        vat = VatLike(vat_);
        dai = GemLike(dai_);
    }
    uint constant ONE = 10 ** 27;
    function join(bytes32 urn, uint wad) public note {
        require(int(wad * ONE) >= 0);
        vat.move(bytes32(address(this)), urn, int(wad * ONE));
        dai.burn(msg.sender, wad);
    }
    function exit(address guy, uint wad) public note {
        require(int(wad * ONE) >= 0);
        vat.move(bytes32(msg.sender), bytes32(address(this)), int(wad * ONE));
        dai.mint(guy, wad);
    }

    mapping(address => mapping (address => bool)) public can;
    function hope(address guy, bool ok) public {
        can[msg.sender][guy] = ok;
    }
    function move(address src, address dst, uint wad) public {
        require(int(wad) >= 0);
        require(can[src][msg.sender]);
        vat.move(bytes32(src), bytes32(dst), int(wad));
    }
}
