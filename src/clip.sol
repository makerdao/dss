// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.6.11;

interface VatLike {
    function move(address,address,uint256) external;
    function flux(bytes32,address,address,uint256) external;
    function ilks(bytes32) external returns (uint256, uint256, uint256, uint256, uint256);
    function suck(address,address,uint256) external;
}

interface PipLike {
    function peek() external returns (bytes32, bool);
}

interface SpotterLike {
    function par() external returns (uint256);
    function ilks(bytes32) external returns (PipLike, uint256);
}

interface DogLike {
    function digs(bytes32, uint256) external;
}

interface ClipperCallee {
    function clipperCall(address, uint256, uint256, bytes calldata) external;
}

interface AbacusLike {
    function price(uint256, uint256) external view returns (uint256);
}

contract Clipper {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "Clipper/not-authorized");
        _;
    }

    // --- Data ---
    bytes32  immutable public ilk;   // Collateral type of this Clipper
    VatLike  immutable public vat;   // Core CDP Engine
    DogLike  immutable public dog;   // Liquidation module

    address     public vow;      // Recipient of dai raised in auctions
    SpotterLike public spotter;  // Collateral price module
    AbacusLike  public calc;     // Current price calculator

    uint256 public buf;   // Multiplicative factor to increase starting price  [ray]
    uint256 public tail;  // Time elapsed before auction reset                 [seconds]
    uint256 public cusp;  // Percentage drop before auction reset              [ray]

    uint256   public kicks;   // Total auctions
    uint256[] public active;  // Array of active auction ids

    struct Sale {
        uint256 pos;  // Index in active array
        uint256 tab;  // Dai to raise       [rad]
        uint256 lot;  // collateral to sell [wad]
        address usr;  // Liquidated CDP
        uint96  tic;  // Auction start time
        uint256 top;  // Starting price     [ray]
    }
    mapping(uint256 => Sale) public sales;

    uint256 internal locked;

    // Levels for circuit breaker
    // 0: no breaker
    // 1: no new kick()
    // 2: no new redo() or take()
    uint256 public stopped = 0;

    uint256 public chip; // Percentage of tab to suck from vow to incentivize keepers [wad]
    uint256 public tip;  // Flat fee to suck from vow to incentivize keepers          [rad]

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event FileUint256(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);

    event Kick(
        uint256 indexed id,
        uint256 top,
        uint256 tab,
        uint256 lot,
        address indexed usr
    );
    event Take(
        uint256 indexed id,
        uint256 max,
        uint256 price,
        uint256 owe,
        uint256 tab,
        uint256 lot,
        address indexed usr
    );
    event Redo(
        uint256 indexed id,
        uint256 top,
        uint256 tab,
        uint256 lot,
        address indexed usr
    );

    event SetBreaker(uint256 level);
    event Yank(uint256 id);

    // --- Init ---
    constructor(address vat_, address spotter_, address dog_, bytes32 ilk_) public {
        vat     = VatLike(vat_);
        spotter = SpotterLike(spotter_);
        dog     = DogLike(dog_);
        ilk     = ilk_;
        buf     = RAY;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Synchronization ---
    modifier lock {
        require(locked == 0, "Clipper/system-locked");
        locked = 1;
        _;
        locked = 0;
    }

    modifier isStopped(uint256 level) {
        require(stopped < level, "Clipper/stopped-incorrect");
        _;
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth {
        if      (what ==  "buf") buf  = data;
        else if (what == "tail") tail = data; // Time elapsed before auction reset
        else if (what == "cusp") cusp = data; // Percentage drop before auction reset
        else if (what == "chip") chip = data; // Percentage of tab to incentivize
        else if (what == "tip")   tip = data; // Flat fee to incentivize keepers
        else revert("Clipper/file-unrecognized-param");
        emit FileUint256(what, data);
    }
    function file(bytes32 what, address data) external auth {
        if (what == "spotter") spotter = SpotterLike(data);
        else if (what == "vow")    vow = data;
        else if (what == "calc")  calc = AbacusLike(data);
        else revert("Clipper/file-unrecognized-param");
        emit FileAddress(what, data);
    }

    // --- Math ---
    uint256 constant BLN = 10 **  9;
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / WAD;                                                            }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / RAY;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, RAY) / y;
    }


    // --- Auction ---

    // start an auction
    // note: trusts the caller to transfer collateral to the contract
    function kick(
        uint256 tab,  // Debt                   [rad]
        uint256 lot,  // Collateral             [wad]
        address usr,  // Liquidated CDP
        address kpr   // Keeper that called dog.bark()
    ) external auth isStopped(1) returns (uint256 id) {
        // Input validation
        require(tab    >           0, "Clipper/zero-tab");
        require(lot    >           0, "Clipper/zero-lot");
        require(usr   !=  address(0), "Clipper/zero-usr");
        require(kicks  < uint256(-1), "Clipper/overflow");

        id = ++kicks;
        active.push(id);

        sales[id].pos = active.length - 1;

        sales[id].tab = tab;
        sales[id].lot = lot;
        sales[id].usr = usr;
        sales[id].tic = uint96(block.timestamp);

        // Could get this from rmul(Vat.ilks(ilk).spot, Spotter.mat()) instead,
        // but if mat has changed since the last poke, the resulting value will
        // be incorrect.
        (PipLike pip, ) = spotter.ilks(ilk);
        (bytes32 val, bool has) = pip.peek();
        require(has, "Clipper/invalid-price");
        sales[id].top = rmul(rdiv(mul(uint256(val), BLN), spotter.par()), buf);

        // incentive to kick auction
        if (tip > 0 || chip > 0) {
            vat.suck(vow, kpr, add(tip, wmul(tab, chip)));
        }

        emit Kick(id, sales[id].top, tab, lot, usr);
    }

    // Reset an auction
    function redo(uint256 id, address kpr) external lock isStopped(2) {
        // Read auction data
        address usr = sales[id].usr;
        uint96  tic = sales[id].tic;
        uint256 top = sales[id].top;

        require(usr != address(0), "Clipper/not-running-auction");

        // Check that auction needs reset
        // and compute current price [ray]
        (bool done,) = status(tic, top);
        require(done, "Clipper/cannot-reset");

        uint256 tab   = sales[id].tab;
        uint256 lot   = sales[id].lot;
        sales[id].tic = uint96(block.timestamp);

        // Could get this from rmul(Vat.ilks(ilk).spot, Spotter.mat()) instead, but if mat has changed since the
        // last poke, the resulting value will be incorrect
        (PipLike pip, ) = spotter.ilks(ilk);
        (bytes32 val, bool has) = pip.peek();
        require(has, "Clipper/invalid-price");
        uint256 price = rdiv(mul(uint256(val), BLN), spotter.par());
        sales[id].top = top = rmul(price, buf);

        // incentive to redo auction
        if (tip > 0 || chip > 0) {
            (,,,, uint256 dust) = vat.ilks(ilk);
            if (tab >= dust && mul(lot, price) >= dust) {
                vat.suck(vow, kpr, add(tip, wmul(tab, chip)));
            }
        }

        emit Redo(id, top, tab, lot, usr);
    }

    // Buy amt of collateral from auction indexed by id
    function take(
        uint256 id,           // Auction id
        uint256 amt,          // Upper limit on amount of collateral to buy  [wad]
        uint256 max,          // Maximum acceptable price (DAI / collateral) [ray]
        address who,          // Receiver of collateral, payer of DAI, and external call address
        bytes calldata data   // Data to pass in external call; if length 0, no call is done
    ) external lock isStopped(2) {

        address usr = sales[id].usr;
        uint96  tic = sales[id].tic;

        require(usr != address(0), "Clipper/not-running-auction");

        uint256 price;
        {
            bool done;
            (done, price) = status(tic, sales[id].top);

            // Check that auction doesn't need reset
            require(!done, "Clipper/needs-reset");
        }

        // Ensure price is acceptable to buyer
        require(max >= price, "Clipper/too-expensive");

        uint256 lot = sales[id].lot;
        uint256 tab = sales[id].tab;
        uint256 owe;

        {
            // Purchase as much as possible, up to amt
            uint256 slice = min(lot, amt);  // slice <= lot

            // DAI needed to buy a slice of this sale
            owe = mul(slice, price);

            // Don't collect more than tab of DAI
            if (owe > tab) {
                // Total debt will be paid
                owe = tab;                  // owe' <= owe
                // Adjust slice
                slice = owe / price;        // slice' = owe' / price <= owe / price == slice <= lot
            } else if (owe < tab && slice < lot) {
                // if slice == lot => auction completed => dust doesn't matter
                (,,,, uint256 dust) = vat.ilks(ilk);
                if (tab - owe < dust) {     // safe as owe < tab
                    // if tab <= dust, buyers have to buy the whole thing
                    require(tab > dust, "Clipper/no-partial-purchase");
                    // Adjust amount to pay
                    owe = tab - dust;       // owe' <= owe
                    // Adjust slice
                    slice = owe / price;    // slice' = owe' / price < owe / price == slice < lot
                }
            }

            // Calculate remaining tab after operation
            tab = tab - owe;  // safe since owe <= tab
            // Calculate remaining lot after operation
            lot = lot - slice;

            // Send collateral to who
            vat.flux(ilk, address(this), who, slice);

            // Do external call (if data is defined) but to be
            // extremely careful we don't allow to do it to the two
            // contracts which the Clipper needs to be authorized
            if (data.length > 0 && who != address(vat) && who != address(dog)) {
                ClipperCallee(who).clipperCall(msg.sender, owe, slice, data);
            }
        }

        // Get DAI from caller
        vat.move(msg.sender, vow, owe);

        // Removes Dai out for liquidation from accumulator
        dog.digs(ilk, owe);

        if (lot == 0) {
            _remove(id);
        } else if (tab == 0) {
            vat.flux(ilk, address(this), usr, lot);
            _remove(id);
        } else {
            sales[id].tab = tab;
            sales[id].lot = lot;
        }

        emit Take(id, max, price, owe, tab, lot, usr);
    }

    function _remove(uint256 id) internal {
        uint256 _index   = sales[id].pos;
        uint256 _move    = active[active.length - 1];
        active[_index]   = _move;
        sales[_move].pos = _index;
        active.pop();
        delete sales[id];
    }

    // The number of active auctions
    function count() external view returns (uint256) {
        return active.length;
    }

    // Return an array of the live auction id's
    function list() external view returns (uint256[] memory) {
        return active;
    }

    // Returns auction id for a live auction in the active auction array
    function getId(uint256 id) external view returns (uint256) {
        return active[id];
    }

    // Externally returns boolean for if an auction needs a redo and also the current price
    function getStatus(uint256 id) external view returns (bool needsRedo, uint256 price) {
        // Read auction data
        address usr = sales[id].usr;
        uint96  tic = sales[id].tic;

        bool done;
        (done, price) = status(tic, sales[id].top);

        needsRedo = usr != address(0) && done;
    }

    // Internally returns boolean for if an auction needs a redo
    function status(uint96 tic, uint256 top) internal view returns (bool done, uint256 price) {
        price = calc.price(top, sub(block.timestamp, tic));
        done  = (sub(block.timestamp, tic) > tail || rdiv(price, top) < cusp);
    }

    // --- Shutdown ---
    function setBreaker(uint256 level) external auth {
        stopped = level;
        emit SetBreaker(level);
    }

    // Cancel an auction during ES or via governance action.
    function yank(uint id) external auth {
        require(sales[id].usr != address(0), "Clipper/not-running-auction");
        dog.digs(ilk, sales[id].tab);
        vat.flux(ilk, address(this), msg.sender, sales[id].lot);
        _remove(id);
        emit Yank(id);
    }
}
