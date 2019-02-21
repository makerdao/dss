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

pragma solidity >=0.5.0;

import "ds-note/note.sol";

contract GemLike {
    function transfer(address,uint) public returns (bool);
    function transferFrom(address,address,uint) public returns (bool);
}

contract DSToken {
    function mint(address,uint) public;
    function burn(address,uint) public;
}

contract VatLike {
    function slip(bytes32,bytes32,int) public;
    function move(bytes32,bytes32,int) public;
    function flux(bytes32,bytes32,bytes32,int) public;
}

/*
    Here we provide *adapters* to connect the Vat to arbitrary external
    token implementations, creating a bounded context for the Vat. The
    adapters here are provided as working examples:

      - `GemJoin`: For well behaved ERC20 tokens, with simple transfer
                   semantics.

      - `ETHJoin`: For native Ether.

      - `DaiJoin`: For connecting internal Dai balances to an external
                   `DSToken` implementation.

    In practice, adapter implementations will be varied and specific to
    individual collateral types, accounting for different transfer
    semantics and token standards.

*/

contract GemJoin is DSNote {
    VatLike public vat;
    bytes32 public ilk;
    GemLike public gem;
    constructor(address vat_, bytes32 ilk_, address gem_) public {
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = GemLike(gem_);
    }
    uint constant ONE = 10 ** 27;
    function mul(uint x, uint y) internal pure returns (int z) {
        z = int(x * y);
        require(int(z) >= 0);
        require(y == 0 || uint(z) / y == x);
    }
    function join(bytes32 urn, uint wad) public note {
        vat.slip(ilk, urn, mul(ONE, wad));
        require(gem.transferFrom(msg.sender, address(this), wad));
    }
    function exit(bytes32 urn, address guy, uint wad) public note {
        require(bytes20(urn) == bytes20(msg.sender));
        vat.slip(ilk, urn, -mul(ONE, wad));
        require(gem.transfer(guy, wad));
    }
}

contract ETHJoin is DSNote {
    VatLike public vat;
    bytes32 public ilk;
    constructor(address vat_, bytes32 ilk_) public {
        vat = VatLike(vat_);
        ilk = ilk_;
    }
    uint constant ONE = 10 ** 27;
    function mul(uint x, uint y) internal pure returns (int z) {
        z = int(x * y);
        require(int(z) >= 0);
        require(y == 0 || uint(z) / y == x);
    }
    function join(bytes32 urn) public payable note {
        vat.slip(ilk, urn, mul(ONE, msg.value));
    }
    function exit(bytes32 urn, address payable guy, uint wad) public note {
        require(bytes20(urn) == bytes20(msg.sender));
        vat.slip(ilk, urn, -mul(ONE, wad));
        guy.transfer(wad);
    }
}

contract DaiJoin is DSNote {
    VatLike public vat;
    DSToken public dai;
    constructor(address vat_, address dai_) public {
        vat = VatLike(vat_);
        dai = DSToken(dai_);
    }
    uint constant ONE = 10 ** 27;
    function mul(uint x, uint y) internal pure returns (int z) {
        z = int(x * y);
        require(int(z) >= 0);
        require(y == 0 || uint(z) / y == x);
    }
    function join(bytes32 urn, uint wad) public note {
        vat.move(bytes32(bytes20(address(this))), urn, mul(ONE, wad));
        dai.burn(msg.sender, wad);
    }
    function exit(bytes32 urn, address guy, uint wad) public note {
        require(bytes20(urn) == bytes20(msg.sender));
        vat.move(urn, bytes32(bytes20(address(this))), mul(ONE, wad));
        dai.mint(guy, wad);
    }
}
