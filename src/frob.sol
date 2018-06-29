// Copyright (C) 2018 AGPL

pragma solidity ^0.4.23;

contract GemLike {
    function move(address,address,uint) public;
}

contract Vat {
    address public root;
    bool    public live;
    uint256 public forms;
    int256  public Line;
    int256  public vice;

    modifier auth {
        // todo: require(msg.sender == root);
        _;
    }

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
    mapping (bytes32 => Ilk)                      public ilks;
    mapping (bytes32 => mapping (address => Urn)) public urns;

    function Gem(bytes32 ilk, address lad) public view returns (int) {
        return urns[ilk][lad].gem;
    }
    function Ink(bytes32 ilk, address lad) public view returns (int) {
        return urns[ilk][lad].ink;
    }
    function Art(bytes32 ilk, address lad) public view returns (int) {
        return urns[ilk][lad].art;
    }
    int public Tab;

    function era() public view returns (uint48) { return uint48(now); }

    int constant RAY = 10 ** 27;
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
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    constructor() public {
        root = msg.sender;
        live = true;
    }

    // --- Administration Engine ---
    function form() public auth returns (bytes32 ilk) {
        ilk = bytes32(++forms);
        ilks[ilk].rate = RAY;
    }
    function file(bytes32 what, uint risk) public auth {
        if (what == "Line") Line = int256(risk);
    }
    function file(bytes32 ilk, bytes32 what, uint risk) public auth {
        if (what == "spot") ilks[ilk].spot = int256(risk);
        if (what == "rate") ilks[ilk].rate = int256(risk);
        if (what == "line") ilks[ilk].line = int256(risk);
    }
    function flux(bytes32 ilk, address lad, int wad) public auth {
        urns[ilk][lad].gem = add(urns[ilk][lad].gem, wad);
    }

    // --- Fungibility Engine ---
    function move(address src, address dst, uint256 wad) public auth {
        require(dai[src] >= int(wad));
        dai[src] -= int(wad);
        dai[dst] += int(wad);
    }

    // --- CDP Engine ---
    function frob(bytes32 ilk, int dink, int dart) public {
        Urn storage u = urns[ilk][msg.sender];
        Ilk storage i = ilks[ilk];

        u.gem = sub(u.gem, dink);
        u.ink = add(u.ink, dink);
        u.art = add(u.art, dart);
        i.Art = add(i.Art, dart);
        Tab   = add(  Tab, rmul(i.rate, dart));
        dai[msg.sender] = add(dai[msg.sender], rmul(i.rate, dart));

        bool calm = rmul(i.Art, i.rate) <= i.line && Tab < Line;
        bool cool = dart <= 0;
        bool firm = dink >= 0;
        bool safe = rmul(u.ink, i.spot) >= rmul(u.art, i.rate);

        require(( calm || cool ) && ( cool && firm || safe ) && live);
    }

    // --- Stability Engine ---
    function drip(int wad) public auth {
        dai[this] = add(dai[this], wad);
        Tab = add(Tab, wad);
    }

    // --- Liquidation Engine ---
    function grab(bytes32 ilk, address lad, address vow, int dink, int dart) public auth {
        Urn storage u = urns[ilk][lad];
        Urn storage v = urns[ilk][vow];
        Ilk storage i = ilks[ilk];

        u.ink = add(u.ink, dink);
        v.gem = sub(v.gem, dink);

        u.art = add(u.art, dart);
        i.Art = add(i.Art, dart);

        vice = sub(vice, rmul(i.rate, dart));
    }
    function heal(address vow, int wad) public auth {
        dai[vow] = sub(dai[vow], wad);
        vice = sub(vice, wad);
    }
}
