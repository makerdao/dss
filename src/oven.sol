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
    function digs(uint256) external;
}

interface OvenCallee {
    function ovenCall(uint256, uint256, bytes calldata) external;
}

interface Abacus {
    function price(uint256, uint256) external view returns (uint256);
}

contract Oven {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external /* note */ auth { wards[usr] = 1; }
    function deny(address usr) external /* note */ auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Oven/not-authorized");
        _;
    }

    // --- Data ---
    bytes32   public ilk;     // Collateral type of this Oven

    address   public vow;     // Recipient of dai raised in auctions
    VatLike   public vat;     // Core CDP Engine
    DogLike   public dog;     // Dog liquidation module
    SpotLike  public spot;    // Spotter
    Abacus    public calc;    // Helper contract to calculate current price of an auction
    uint256   public buf;     // Multiplicative factor to increase starting price    [ray]
    uint256   public dust;    // Minimum tab in an auction; read from Vat instead??? [rad]
    uint256   public step;    // Length of time between price drops                  [seconds]
    uint256   public cut;     // Per-step multiplicative decrease in price           [ray]
    uint256   public tail;    // Time elapsed before auction reset                   [seconds]
    uint256   public cusp;    // Percentage drop before auction reset                [ray]
    uint256   public bakes;   // Bake count
    uint256[] public baking;  // Array of current auctions

    struct Loaf {
        uint256 pos;  // Index in baking array
        uint256 tab;  // Dai to raise       [rad]
        uint256 lot;  // ETH to sell        [wad]
        address usr;  // Liquidated CDP
        uint96  tic;  // Auction start time
        uint256 top;  // Starting price     [ray]
    }
    mapping(uint256 => Loaf) public loaves;

    uint256 internal locked;

    // --- Events ---
    event Bake(
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
        vat = VatLike(vat_);
        spot = SpotLike(spot_);
        dog = DogLike(dog_);
        ilk = ilk_;
        cut = RAY;
        step = 1;
        wards[msg.sender] = 1;
        buf = RAY;
    }

    modifier lock {
        require(locked == 0, "Oven/system-locked");
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
        else revert("Oven/file-unrecognized-param");
    }
    function file(bytes32 what, address data) external auth {
        if      (what ==  "dog") dog  = DogLike(data);
        else if (what ==  "vow") vow  = data;
        else if (what == "calc") calc = Abacus(data);
        else revert("Oven/file-unrecognized-param");
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
    function bake(uint256 tab,  // debt             [rad]
                  uint256 lot,  // collateral       [wad]
                  address usr   // liquidated vault
    ) external auth returns (uint256 id) {
        require(bakes < uint256(-1), "Oven/overflow");
        id = ++bakes;
        baking.push(id);

        loaves[id].pos = baking.length - 1;

        loaves[id].tab = tab;
        loaves[id].lot = lot;
        loaves[id].usr = usr;
        loaves[id].tic = uint96(now);

        // Could get this from rmul(Vat.ilks(ilk).spot, Spotter.mat()) instead,
        // but if mat has changed since the last poke, the resulting value will
        // be incorrect.
        (PipLike pip, ) = spot.ilks(ilk);
        (bytes32 val, bool has) = pip.peek();
        require(has, "Oven/invalid-price");
        loaves[id].top = rmul(rdiv(mul(uint256(val), BLN), spot.par()), buf);

        emit Bake(id, tab, lot, usr);
    }

    // Reset an auction
    function warm(uint256 id) external {
        // Read auction data
        Loaf memory loaf = loaves[id];
        require(loaf.tab > 0, "Oven/not-running-auction");

        // Compute current price [ray]
        uint256 price = calc.price(loaf.top, loaf.tic);

        // Check that auction needs reset
        require(sub(now, loaf.tic) > tail || rdiv(price, loaf.top) < cusp, "Oven/cannot-reset");
        
        loaves[id].tic = uint96(now);

        // Could get this from rmul(Vat.ilks(ilk).spot, Spotter.mat()) instead, but if mat has changed since the
        // last poke, the resulting value will be incorrect
        (PipLike pip, ) = spot.ilks(ilk);
        (bytes32 val, bool has) = pip.peek();
        require(has, "Oven/invalid-price");
        loaves[id].top = rmul(rdiv(mul(uint256(val), 10 ** 9), spot.par()), buf);

        emit Warm(id, loaves[id].tab, loaves[id].lot, loaves[id].usr);
    }

    // Buy amt of collateral from auction indexed by id
    function take(uint256 id,           // Auction id
                  uint256 amt,          // Upper limit on amount of collateral to buy       [wad]
                  uint256 pay,          // Bid price (DAI / ETH)                            [ray]
                  address who,          // Who will receive the collateral and pay the debt
                  bytes calldata data   
    ) external lock {
        // Read auction data
        Loaf memory loaf = loaves[id];
        require(loaf.tab > 0, "Oven/not-running-auction");

        // Compute current price [ray]
        uint256 price = calc.price(loaf.top, loaf.tic);

        // Check that auction doesn't need reset
        require(sub(now, loaf.tic) <= tail && rdiv(price, loaf.top) >= cusp, "Oven/needs-reset");

        // Ensure price is acceptable to buyer
        require(pay >= price, "Oven/too-expensive");

        // Purchase as much as possible, up to amt
        uint256 slice = min(loaf.lot, amt);

        // DAI needed to buy a slice of this loaf
        uint256 owe = mul(slice, pay);

        // Don't collect more than tab of DAI
        if (owe > loaf.tab) {
            owe = loaf.tab;

            // Readjust slice
            slice = owe / pay;
        }

        // Calculate remaining tab after operation
        loaf.tab = sub(loaf.tab, owe);
        require(loaf.tab == 0 || loaf.tab >= dust, "Oven/dust");

        // Calculate remaining lot after operation
        loaf.lot = sub(loaf.lot, slice);
        // Send collateral to who
        vat.flux(ilk, address(this), who, slice);

        // Do external call (if defined)
        if (data.length > 0) {
            OvenCallee(who).ovenCall(owe, slice, data);
        }

        // Get DAI from who address
        vat.move(who, vow, owe);

        // Removes Dai out for liquidation from accumulator
        dog.digs(owe);

        if (loaf.lot == 0) {
            _remove(id);
        } else if (loaf.tab == 0) {
            // Should we return collateral incrementally instead?
            vat.flux(ilk, address(this), loaf.usr, loaf.lot);
            _remove(id);
        } else {
            loaves[id].tab = loaf.tab;
            loaves[id].lot = loaf.lot;
        }

        // emit event?
    }

    function _remove(uint256 id) internal {
        uint256 _index     = loaves[id].pos;
        uint256 _move      = baking[baking.length - 1];
        baking[_index]     = _move;
        loaves[_move].pos  = _index;
        baking.pop();
        delete loaves[id];
    }

    // The number of active auctions
    function count() external view returns (uint256) {
        return baking.length;
    }

    // Return an array of the live auction id's
    function list() external view returns (uint256[] memory) {
        return baking;
    }

    // Returns auction id for a live auction in the active auction array
    function getId(uint256 idx) external view returns (uint256) {
        return baking[idx];
    }

    // --- Shutdown ---

    // Cancel an auction during ES
    function yank() external auth {
        // TODO
    }
}
