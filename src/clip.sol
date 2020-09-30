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

pragma solidity >=0.5.12;

interface VatLike {
    function move(address,address,uint256) external;
    function flux(bytes32,address,address,uint256) external;
}

interface PipLike {
    function peek() external returns (bytes32, bool);
}

interface SpotLike {
    function par() external returns (uint256);
    function ilks(bytes32) external returns (PipLike, uint256);
}

interface DogLike {
    function digs(bytes32, uint256) external;
}

interface ClipperCallee {
    function clipperCall(uint256, uint256, bytes calldata) external;
}

interface AbacusLike {
    function price(uint256, uint256) external view returns (uint256);
}

contract Clipper {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external /* note */ auth { wards[usr] = 1; }
    function deny(address usr) external /* note */ auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Clipper/not-authorized");
        _;
    }

    // --- Data ---
    bytes32 public ilk;  // Collateral type of this Clipper

    address    public vow;   // Recipient of dai raised in auctions
    VatLike    public vat;   // Core CDP Engine
    DogLike    public dog;   // Liquidation module
    SpotLike   public spot;  // Collateral price module
    AbacusLike public calc;  // Current price calculator

    uint256 public buf;   // Multiplicative factor to increase starting price  [ray]
    // TODO: read from the Vat instead?
    uint256 public dust;  // Minimum tab in an auction;                        [rad]
    uint256 public tail;  // Time elapsed before auction reset                 [seconds]
    uint256 public cusp;  // Percentage drop before auction reset              [ray]

    uint256   public kicks;   // Total auctions
    uint256[] public active;  // Array of active auction ids

    struct Sale {
        uint256 pos;  // Index in active array
        uint256 tab;  // Dai to raise       [rad]
        uint256 lot;  // ETH to sell        [wad]
        address usr;  // Liquidated CDP
        uint96  tic;  // Auction start time
        uint256 top;  // Starting price     [ray]
    }
    mapping(uint256 => Sale) public sales;

    uint256 internal locked;

    // --- Events ---
    event Kick(
        uint256  id,
        uint256 tab,
        uint256 lot,
        address indexed usr
    );

    event Warm(
        uint256  id,
        uint256 tab,
        uint256 lot,
        address indexed usr
    );

    // --- Init ---
    constructor(address vat_, address spot_, address dog_, bytes32 ilk_) public {
        vat  = VatLike(vat_);
        spot = SpotLike(spot_);
        dog  = DogLike(dog_);
        ilk  = ilk_;
        buf  = RAY;

        wards[msg.sender] = 1;
    }

    // --- Synchronization ---
    modifier lock {
        require(locked == 0, "Clipper/system-locked");
        locked = 1;
        _;
        locked = 0;
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external {
        if      (what ==  "buf") buf  = data;
        else if (what == "dust") dust = data;
        else if (what == "tail") tail = data; // Time elapsed    before auction reset
        else if (what == "cusp") cusp = data; // Percentage drop before auction reset
        else revert("Clipper/file-unrecognized-param");
    }
    function file(bytes32 what, address data) external auth {
        if      (what ==  "dog") dog  = DogLike(data);
        else if (what ==  "vow") vow  = data;
        else if (what == "calc") calc = AbacusLike(data);
        else revert("Clipper/file-unrecognized-param");
    }

    // --- Math ---
    uint256 constant RAY = 10 ** 27;
    uint256 constant BLN = 10 ** 9;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / RAY;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, RAY) / y;
    }

    // --- Auction ---

    // start an auction
    function kick(uint256 tab,  // Debt             [rad]
                  uint256 lot,  // Collateral       [wad]
                  address usr   // Liquidated CDP
    ) external auth returns (uint256 id) {
        require(kicks < uint256(-1), "Clipper/overflow");
        id = ++kicks;
        active.push(id);

        sales[id].pos = active.length - 1;

        sales[id].tab = tab;
        sales[id].lot = lot;
        sales[id].usr = usr;
        sales[id].tic = uint96(now);

        // Could get this from rmul(Vat.ilks(ilk).spot, Spotter.mat()) instead,
        // but if mat has changed since the last poke, the resulting value will
        // be incorrect.
        (PipLike pip, ) = spot.ilks(ilk);
        (bytes32 val, bool has) = pip.peek();
        require(has, "Clipper/invalid-price");
        sales[id].top = rmul(rdiv(mul(uint256(val), BLN), spot.par()), buf);

        emit Kick(id, tab, lot, usr);
    }

    // Reset an auction
    function warm(uint256 id) external {
        // Read auction data
        Sale memory sale = sales[id];
        require(sale.tab > 0, "Clipper/not-running-auction");

        // Compute current price [ray]
        uint256 price = calc.price(sale.top, sale.tic);

        // Check that auction needs reset
        require(sub(now, sale.tic) > tail || rdiv(price, sale.top) < cusp, "Clipper/cannot-reset");
        
        sales[id].tic = uint96(now);

        // Could get this from rmul(Vat.ilks(ilk).spot, Spotter.mat()) instead, but if mat has changed since the
        // last poke, the resulting value will be incorrect
        (PipLike pip, ) = spot.ilks(ilk);
        (bytes32 val, bool has) = pip.peek();
        require(has, "Clipper/invalid-price");
        sales[id].top = rmul(rdiv(mul(uint256(val), 10 ** 9), spot.par()), buf);

        emit Warm(id, sales[id].tab, sales[id].lot, sales[id].usr);
    }

    // Buy amt of collateral from auction indexed by id
    function take(uint256 id,           // Auction id
                  uint256 amt,          // Upper limit on amount of collateral to buy       [wad]
                  uint256 pay,          // Bid price (DAI / ETH)                            [ray]
                  address who,          // Who will receive the collateral and pay the debt
                  bytes calldata data   
    ) external lock {
        // Read auction data
        Sale memory sale = sales[id];
        require(sale.tab > 0, "Clipper/not-running-auction");

        // Compute current price [ray]
        uint256 price = calc.price(sale.top, sale.tic);

        // Check that auction doesn't need reset
        require(sub(now, sale.tic) <= tail && rdiv(price, sale.top) >= cusp, "Clipper/needs-reset");

        // Ensure price is acceptable to buyer
        require(pay >= price, "Clipper/too-expensive");

        // Purchase as much as possible, up to amt
        uint256 slice = min(sale.lot, amt);

        // DAI needed to buy a slice of this sale
        uint256 owe = mul(slice, pay);

        // Don't collect more than tab of DAI
        if (owe > sale.tab) {
            owe = sale.tab;

            // Readjust slice
            slice = owe / pay;
        }

        // Calculate remaining tab after operation
        sale.tab = sub(sale.tab, owe);
        require(sale.tab == 0 || sale.tab >= dust, "Clipper/dust");

        // Calculate remaining lot after operation
        sale.lot = sub(sale.lot, slice);
        // Send collateral to who
        vat.flux(ilk, address(this), who, slice);

        // Do external call (if defined)
        if (data.length > 0) {
            ClipperCallee(who).clipperCall(owe, slice, data);
        }

        // Get DAI from who address
        vat.move(who, vow, owe);

        // Removes Dai out for liquidation from accumulator
        dog.digs(ilk, owe);

        if (sale.lot == 0) {
            _remove(id);
        } else if (sale.tab == 0) {
            // Should we return collateral incrementally instead?
            vat.flux(ilk, address(this), sale.usr, sale.lot);
            _remove(id);
        } else {
            sales[id].tab = sale.tab;
            sales[id].lot = sale.lot;
        }

        // emit event?
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
    function getId(uint256 idx) external view returns (uint256) {
        return active[idx];
    }

    // --- Shutdown ---

    // Cancel an auction during ES
    function yank() external auth {
        // TODO
    }
}
