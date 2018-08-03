// Copyright (C) 2018 AGPL

pragma solidity ^0.4.24;

contract Vat {
    address public root;

    function era() public view returns (uint48) { return uint48(now); }
    modifier auth { _; }  // todo: require(msg.sender == root);

    struct Ilk {
        int256  rate;  // ray
        int256  Art;   // wad
    }
    struct Urn {
        int256 gem;
        int256 ink;
        int256 art;
    }

    mapping (address => int256)                   public dai;
    mapping (address => int256)                   public sin;
    mapping (bytes32 => Ilk)                      public ilks;
    mapping (bytes32 => mapping (address => Urn)) public urns;

    int256  public Tab;
    int256  public vice;

    function add(int x, int y) internal pure returns (int z) {
        z = x + y;
        require(y <= 0 || z > x);
        require(y >= 0 || z < x);
    }
    function sub(int x, int y) internal pure returns (int z) {
        require(y != -2**255);
        z = add(x, -y);
    }
    function mul(int x, int y) internal pure returns (int z) {
        z = x * y;
        require(y >= 0 || x != -2**255);
        require(y == 0 || z / y == x);
    }

    constructor() public {
        root = msg.sender;
    }

    // --- Administration Engine ---
    function file(bytes32 ilk, bytes32 what, int risk) public auth {
        if (what == "rate") ilks[ilk].rate = risk;
    }

    // --- Fungibility Engine ---
    int256 constant ONE = 10 ** 27;
    function move(address src, address dst, uint wad_) public auth {
        int wad = int(wad_) * ONE;
        require(dai[src] >= int(wad));
        dai[src] = sub(dai[src], int(wad));
        dai[dst] = add(dai[dst], int(wad));
    }
    function slip(bytes32 ilk, address guy, int256 wad) public auth {
        urns[ilk][guy].gem = add(urns[ilk][guy].gem, wad);
    }

    // --- CDP Engine ---
    function tune(bytes32 ilk, address lad, int dink, int dart) public auth {
        Urn storage u = urns[ilk][lad];
        Ilk storage i = ilks[ilk];

        u.gem = sub(u.gem, dink);
        u.ink = add(u.ink, dink);
        u.art = add(u.art, dart);
        i.Art = add(i.Art, dart);

        dai[lad] = add(dai[lad], mul(i.rate, dart));
        Tab      = add(Tab,      mul(i.rate, dart));
    }

    // --- Liquidation Engine ---
    function grab(bytes32 ilk, address lad, address vow, int dink, int dart) public auth {
        Urn storage u = urns[ilk][lad];
        Ilk storage i = ilks[ilk];

        u.ink = add(u.ink, dink);
        u.art = add(u.art, dart);
        i.Art = add(i.Art, dart);

        sin[vow] = sub(sin[vow], mul(i.rate, dart));
        vice     = sub(vice,     mul(i.rate, dart));
    }
    function heal(address u, address v, int wad) public auth {
        wad = wad * ONE;
        require(sin[u] >= wad);
        require(dai[v] >= wad);
        require(vice   >= wad);
        require(Tab    >= wad);

        sin[u] = sub(sin[u], wad);
        dai[v] = sub(dai[v], wad);

        vice = sub(vice, wad);
        Tab  = sub(Tab, wad);
    }

    // --- Stability Engine ---
    function fold(bytes32 ilk, address vow, int rate) public auth {
        Ilk storage i = ilks[ilk];
        i.rate   = add(i.rate, rate);
        int wad  = mul(i.Art, rate);
        dai[vow] = add(dai[vow], wad);
        Tab      = add(Tab, wad);
    }
}
