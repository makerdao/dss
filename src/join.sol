// SPDX-License-Identifier: AGPL-3.0-or-later

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

pragma solidity ^0.6.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

interface GemLike {
    function decimals() external view returns (uint);
    function transfer(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
}

interface DSTokenLike {
    function mint(address,uint) external;
    function burn(address,uint) external;
}

interface VatLike {
    function slip(bytes32,address,int) external;
    function move(address,address,uint) external;
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

    Adapters need to implement two basic methods:

      - `join`: enter collateral into the system
      - `exit`: remove collateral from the system

*/

contract GemJoin {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "GemJoin/not-authorized");
        _;
    }

    VatLike public vat;   // CDP Engine
    bytes32 public ilk;   // Collateral Type
    GemLike public gem;
    uint    public dec;
    uint    public live;  // Active Flag

    // Events
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);
    event Cage();

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = GemLike(gem_);
        dec = gem.decimals();
        emit Rely(msg.sender);
    }
    function cage() external auth {
        live = 0;
        emit Cage();
    }
    function join(address usr, uint wad) external {
        require(live == 1, "GemJoin/not-live");
        require(int(wad) >= 0, "GemJoin/overflow");
        vat.slip(ilk, usr, int(wad));                                                           // DAM: Update collateral balance.
        require(gem.transferFrom(msg.sender, address(this), wad), "GemJoin/failed-transfer");   // DAM: Transfer tokens here.
        emit Join(usr, wad);
    }
    function exit(address usr, uint wad) external {
        require(wad <= 2 ** 255, "GemJoin/overflow");
        vat.slip(ilk, msg.sender, -int(wad));                                                   // DAM: Update collateral balance.
        require(gem.transfer(usr, wad), "GemJoin/failed-transfer");                             // DAM: Transfer tokens to user.
        emit Exit(usr, wad);
    }
}

contract DaiJoin {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "DaiJoin/not-authorized");
        _;
    }

    VatLike public vat;      // CDP Engine
    DSTokenLike public dai;  // Stablecoin Token
    uint    public live;     // Active Flag

    // Events
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);
    event Cage();

    constructor(address vat_, address dai_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        dai = DSTokenLike(dai_);
    }
    function cage() external auth {
        live = 0;
        emit Cage();
    }
    uint constant ONE = 10 ** 27;
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function join(address usr, uint wad) external {
        vat.move(address(this), usr, mul(ONE, wad));                    // DAM: Debit the join contract's balance and credit the user's balance.
        dai.burn(msg.sender, wad);                                      // DAM: Burn the DAI sent to this contract.
        emit Join(usr, wad);
    }
    function exit(address usr, uint wad) external {
        require(live == 1, "DaiJoin/not-live");
        vat.move(msg.sender, address(this), mul(ONE, wad));             // DAM: Credit the join contract's DAI balance and debit the user's balance.
        dai.mint(usr, wad);                                             // DAM: Mint the DAI equivelant to the amount the user wants to withdraw.
        emit Exit(usr, wad);
    }
}
