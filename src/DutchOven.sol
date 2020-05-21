pragma solidity ^0.5.12;

// VatLike, SpotLike, PipLike defined here

contract Oven {
  mapping (address => uint) public wards;
  function rely(address usr) external note auth { wards[usr] = 1; }
  function deny(address usr) external note auth { wards[usr] = 0; }
  modifier auth {
      require(wards[msg.sender] == 1, "Oven/not-authorized");
      _;
  }

  bytes32  public ilk;   // collateral type of this Oven

  address  public vow;   // recipient of dai raised in auctions
  VatLike  public vat;   // Core CDP Engine
  SpotLike public spot;  // Spotter
  uint256  public buf;   // multiplicative factor to increase starting price    [ray]
  uint256  public dust;  // minimum tab in an auction; read from Vat instead??? [rad]
  uint256  public step;  // length of time between price drops                  [seconds]
  uint256  public cut;   // per-step multiplicative decrease in price           [ray]

  Loaf {
    tab;  // dai to raise
    lot;  // eth to sell
    usr;  // liquidated CDP
    tic:  // auction start time
    top;  // starting price
  }
  mapping(uint256 => Loaf) public loaves;

  uint256 bakes;

  constructor(address vat_, bytes32 ilk_) public {
    vat = VatLike(vat_);
    ilk = ilk_;
    cut = ONE;
    wards[msg.sender] = 1;
  }

  // functions for setting parameters
  function file(bytes32 what, uint256 data) {
    if      (what ==  "cut") require((cut = data) <= ONE, "Oven/cut-greater-than-ONE");
    else if (what == "step") step = data;
    else if (what ==  "buf") buf  = data;
    else if (what == "dust") dust = data;
    else revert("Oven/file-unrecognized-param");
  }

  // math functions and constants
  uint256 constant ONE = 10 ** 27;
  sub
  rmul
  rpow

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
    loaves[id].tic = now;

    // could get this from rmul(Vat.ilks(ilk).spot, Spotter.mat()) instead, but if mat has changed since the
    // last poke, the resulting value will be incorrect
    (bytes32 val, bool has) = spot.ilks(ilk).pip.peek();
    require(has, "Oven/invalid-price");
    loaves[id].top = rmul(rdiv(mul(uint256(val), 10 ** 9), spot.par()), buf);

    // emit event
  }

  // buy amt of collateral from auction indexed by id
  function take(uint256 id,   // auction id
                uint256 amt,  // upper limit on amount of collateral to buy
                uint256 max   // maximum acceptable price (DAI / ETH)
  ) public {
    // read auction data
    (uint256 tab, uint256 lot, address usr, uint256 tic, uint256 top) = loaves[id];

    // compute current price
    uint256 pay = price(tic, top);

    // ensure price is acceptable to buyer
    require(pay <= max, "Oven/too-expensive");

    // purchase as much as possible, up to amt
    uint256 slice = min(bids[id].lot, amt);

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
    (,,, uint256 tic, uint256 top,) = loaves[id];
    return price(tic, top);
  }

  // returns the price adjusted for the amount of elapsed time since tic [ray]
  function price(uint256 tic, uint256 top) public returns (uint256) {
    return rmul(top, rpow(cut, sub(now, tic) / step, ONE));
  }

  // cancel an auction during ES
  function yank() public auth {
    // TODO
  }
}
