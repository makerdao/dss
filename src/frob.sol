// Copyright (C) 2018 AGPL

pragma solidity ^0.4.23;

contract Vat {
    address public root;
    bool    public live;
    int256  public Line;

    function era() public view returns (uint48) { return uint48(now); }
    modifier auth { _; }  // todo: require(msg.sender == root);

    struct Ilk {
        int256  spot;  // ray
        int256  rate;  // ray
        int256  line;  // wad
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

    function Gem(bytes32 ilk, address lad) public view returns (int) {
        return urns[ilk][lad].gem;
    }
    function Ink(bytes32 ilk, address lad) public view returns (int) {
        return urns[ilk][lad].ink;
    }
    function Art(bytes32 ilk, address lad) public view returns (int) {
        return urns[ilk][lad].art;
    }

    int256 constant RAY = 10 ** 27;
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
    function rmul(int x, int y) internal pure returns (int z) {
        z = mul(x, y) / RAY;
    }

    constructor() public {
        root = msg.sender;
        live = true;
    }

    // --- Administration Engine ---
    function file(bytes32 what, int risk) public auth {
        if (what == "Line") Line = risk;
    }
    function file(bytes32 ilk, bytes32 what, int risk) public auth {
        if (what == "spot") ilks[ilk].spot = risk;
        if (what == "rate") ilks[ilk].rate = risk;
        if (what == "line") ilks[ilk].line = risk;
    }

    // --- Fungibility Engine ---
    function move(address src, address dst, uint wad) public auth {
        require(dai[src] >= int(wad));
        dai[src] = sub(dai[src], int(wad));
        dai[dst] = add(dai[dst], int(wad));
    }
    function slip(bytes32 ilk, address guy, int256 wad) public auth {
        urns[ilk][guy].gem = add(urns[ilk][guy].gem, wad);
    }

    // --- CDP Engine ---
    function frob(bytes32 ilk, int dink, int dart) public {
        Urn storage u = urns[ilk][msg.sender];
        Ilk storage i = ilks[ilk];

        u.gem = sub(u.gem, dink);
        u.ink = add(u.ink, dink);
        u.art = add(u.art, dart);
        i.Art = add(i.Art, dart);

        dai[msg.sender] = add(dai[msg.sender], rmul(i.rate, dart));
        Tab             = add(Tab,             rmul(i.rate, dart));

        bool calm = rmul(i.Art, i.rate) <= i.line && Tab < Line;
        bool cool = dart <= 0;
        bool firm = dink >= 0;
        bool safe = rmul(u.ink, i.spot) >= rmul(u.art, i.rate);

        require(( calm || cool ) && ( cool && firm || safe ) && live);
        require(i.rate != 0);
    }

    // --- Liquidation Engine ---
    function grab(bytes32 ilk, address lad, address vow, int dink, int dart) public auth {
        Urn storage u = urns[ilk][lad];
        Ilk storage i = ilks[ilk];

        u.ink = add(u.ink, dink);
        u.art = add(u.art, dart);
        i.Art = add(i.Art, dart);

        sin[vow] = sub(sin[vow], rmul(i.rate, dart));
        vice     = sub(vice,     rmul(i.rate, dart));
    }
    function heal(address u, address v, int wad) public auth {
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
        int wad  = rmul(i.Art, rate);
        dai[vow] = add(dai[vow], wad);
        Tab      = add(Tab, wad);
    }

}
