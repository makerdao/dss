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
    function transferFrom(address,address,uint) public returns (bool);
    function mint(address,uint) public;
    function burn(address,uint) public;
}

contract VatLike {
    function slip(bytes32,bytes32,int) public;
    function move(bytes32,bytes32,uint) public;
}

contract Adapter {
    VatLike public vat;
    bytes32 public ilk;
    GemLike public gem;
    constructor(address vat_, bytes32 ilk_, address gem_) public {
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = GemLike(gem_);
    }
    function join(uint wad) public {
        require(int(wad) >= 0);
        require(gem.transferFrom(msg.sender, this, wad));
        vat.slip(ilk, bytes32(msg.sender), int(wad));
    }
    function exit(uint wad) public {
        require(int(wad) >= 0);
        require(gem.transferFrom(this, msg.sender, wad));
        vat.slip(ilk, bytes32(msg.sender), -int(wad));
    }
}

contract ETHAdapter {
    VatLike public vat;
    bytes32 public ilk;
    constructor(address vat_, bytes32 ilk_) public {
        vat = VatLike(vat_);
        ilk = ilk_;
    }
    function join() public payable {
        vat.slip(ilk, bytes32(msg.sender), int(msg.value));
    }
    function exit(uint wad) public {
        require(int(wad) >= 0);
        vat.slip(ilk, bytes32(msg.sender), -int(wad));
        msg.sender.transfer(wad);
    }
}

contract DaiAdapter {
    VatLike public vat;
    GemLike public dai;
    constructor(address vat_, address dai_) public {
        vat = VatLike(vat_);
        dai = GemLike(dai_);
    }
    uint constant ONE = 10 ** 27;
    function join(uint wad) public {
        vat.move(bytes32(address(this)), bytes32(msg.sender), wad * ONE);
        dai.burn(msg.sender, wad);
    }
    function exit(uint wad) public {
        vat.move(bytes32(msg.sender), bytes32(address(this)), wad * ONE);
        dai.mint(msg.sender, wad);
    }
}
