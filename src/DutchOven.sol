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

pragma solidity ^0.5.12;

contract VatLike {
    function move(address,address,uint) external;
    function flux(bytes32,address,address,uint) external;
}

contract PipLike {
    function peek() external returns (bytes32, bool);
}

contract SpotLike {
    function par() public returns (uint256);
    function ilks(bytes32) public returns (PipLike, uint256);
}

contract Oven {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external /* note */ auth { wards[usr] = 1; }
    function deny(address usr) external /* note */ auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Oven/not-authorized");
        _;
    }

    // --- Data ---
    bytes32  public ilk;   // collateral type of this Oven

    address  public vow;   // recipient of dai raised in auctions
    VatLike  public vat;   // Core CDP Engine
    SpotLike public spot;  // Spotter
    uint256  public buf;   // multiplicative factor to increase starting price    [ray]
    uint256  public dust;  // minimum tab in an auction; read from Vat instead??? [rad]
    uint256  public step;  // length of time between price drops                  [seconds]
    uint256  public cut;   // per-step multiplicative decrease in price           [ray]

    struct Loaf {
        uint256 tab;  // dai to raise
        uint256 lot;  // eth to sell
        address usr;  // liquidated CDP
        uint96  tic;  // auction start time
        uint256 top;  // starting price
    }
    mapping(uint256 => Loaf) public loaves;

    uint256 bakes;

    // --- Events ---
    event Bake(
        uint256  id,
        uint256 tab,
        uint256 lot,
        address indexed usr
    );

    // --- Init ---
    constructor(address vat_, bytes32 ilk_) public {
        vat = VatLike(vat_);
        ilk = ilk_;
        cut = ONE;
        wards[msg.sender] = 1;
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external {
        if      (what ==  "cut") require((cut = data) <= ONE, "Oven/cut-greater-than-ONE");
        else if (what == "step") step = data;
        else if (what ==  "buf") buf  = data;
        else if (what == "dust") dust = data;
        else revert("Oven/file-unrecognized-param");
    }

    // --- Math ---
    uint256 constant ONE = 10 ** 27;
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        z = x - uint(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / ONE;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, ONE) / y;
    }
    // optimized version from dss PR #78
    function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
        assembly {
            switch n case 0 { z := b }
            default {
                switch x case 0 { z := 0 }
                default {
                    switch mod(n, 2) case 0 { z := b } default { z := x }
                    let half := div(b, 2)  // for rounding.
                    for { n := div(n, 2) } n { n := div(n,2) } {
                        let xx := mul(x, x)
                        if shr(128, x) { revert(0,0) }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) { revert(0,0) }
                        x := div(xxRound, b)
                        if mod(n,2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) { revert(0,0) }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }

    // --- Auction ---

    // start an auction
    function bake(uint256 tab,  // debt
                  uint256 lot,  // collateral
                  address usr   // liquidated vault
    ) public auth returns (uint256 id) { 
        require(bakes < uint(-1), "Oven/overflow");
        id = ++bakes;

        // Caller must hope on the Oven
        vat.flux(ilk, msg.sender, address(this), lot);

        // TODO: require tab non-dusty? might get into an annoying situation where some CDPs cannot be liquidated
        loaves[id].tab = tab;
        loaves[id].lot = lot;
        loaves[id].usr = usr;
        loaves[id].tic = uint96(now);

        // could get this from rmul(Vat.ilks(ilk).spot, Spotter.mat()) instead, but if mat has changed since the
        // last poke, the resulting value will be incorrect
        (PipLike pip, ) = spot.ilks(ilk);
        (bytes32 val, bool has) = pip.peek();
        require(has, "Oven/invalid-price");
        loaves[id].top = rmul(rdiv(mul(uint256(val), 10 ** 9), spot.par()), buf);

        emit Bake(id, tab, lot, usr);
    }

    // buy amt of collateral from auction indexed by id
    function take(uint256 id,   // auction id
                  uint256 amt,  // upper limit on amount of collateral to buy
                  uint256 max   // maximum acceptable price (DAI / ETH)
    ) public {
        // read auction data
        (uint256 tab, uint256 lot, address usr, uint96 tic, uint256 top) = this.loaves(id);

        // compute current price
        uint256 pay = price(tic, top);

        // ensure price is acceptable to buyer
        require(pay <= max, "Oven/too-expensive");

        // purchase as much as possible, up to amt
        uint256 slice = min(lot, amt);

        // DAI needed to buy a slice of this loaf
        uint256 owe = slice * pay;

        // don't collect more than tab of DAI
        if (owe > tab) {
            owe = tab;

            // readjust slice
            slice = owe / pay;
        }

        vat.move(msg.sender, vow, owe);
        tab = sub(tab, owe);

        vat.flux(ilk, address(this), msg.sender, slice);
        lot = sub(lot, slice);

        if (tab == 0) {
            // should we return collateral incrementally instead?
            vat.flux(ilk, address(this), usr, lot);
            delete loaves[id];
        } else {
            require(tab <= dust, "Oven/dust");
            loaves[id].tab = tab;
            loaves[id].lot = lot;
        }

        // emit event?
    }

    // returns the current price of the specified auction [ray]
    function price(uint256 id) public returns (uint256) {
        (,,, uint96 tic, uint256 top) = this.loaves(id);
        return price(tic, top);
    }

    // returns the price adjusted for the amount of elapsed time since tic [ray]
    function price(uint96 tic, uint256 top) public returns (uint256) {
        return rmul(top, rpow(cut, sub(now, uint256(tic)) / step, ONE));
    }

    // --- Shutdown ---

    // cancel an auction during ES
    function yank() public auth {
        // TODO
    }
}
