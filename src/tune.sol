// Copyright (C) 2018 AGPL

pragma solidity ^0.4.24;

contract Vat {
    modifier auth { _; }  // todo

    struct Ilk {
        int256  rate;  // ray
        int256  Art;   // wad
    }
    struct Urn {
        int256 gem;    // wad
        int256 ink;    // wad
        int256 art;    // wad
    }

    mapping (address => int256)                   public dai;  // rad
    mapping (address => int256)                   public sin;  // rad
    mapping (bytes32 => Ilk)                      public ilks;
    mapping (bytes32 => mapping (address => Urn)) public urns;

    int256  public Tab;   // rad
    int256  public vice;  // rad

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

    // --- Administration Engine ---
    function file(bytes32 ilk, bytes32 what, int risk) public auth {
        if (what == "rate") ilks[ilk].rate = risk;
    }

    // --- Fungibility Engine ---
    int256 constant ONE = 10 ** 27;
    function move(address src, address dst, uint wad) public auth {
        require(int(wad) >= 0);
        move(src, dst, int(wad));
    }
    function move(address src, address dst, int wad) public auth {
        int rad = mul(wad, ONE);
        dai[src] = sub(dai[src], rad);
        dai[dst] = add(dai[dst], rad);
        require(dai[src] >= 0 && dai[dst] >= 0);
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
        int rad = mul(wad, ONE);

        sin[u] = sub(sin[u], rad);
        dai[v] = sub(dai[v], rad);
        vice   = sub(vice,   rad);
        Tab    = sub(Tab,    rad);

        require(sin[u] >= 0 && dai[v] >= 0);
        require(vice   >= 0 && Tab    >= 0);
    }

    // --- Stability Engine ---
    function fold(bytes32 ilk, address vow, int rate) public auth {
        Ilk storage i = ilks[ilk];
        i.rate   = add(i.rate, rate);
        int rad  = mul(i.Art, rate);
        dai[vow] = add(dai[vow], rad);
        Tab      = add(Tab, rad);
    }
}
