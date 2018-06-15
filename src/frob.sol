// Copyright (C) 2018 AGPL

pragma solidity ^0.4.23;

contract GemLike {
    function move(address,address,uint) public;
}

contract Flippy{
    function kick(address lad, address gal, uint tab, uint lot, uint bid)
        public returns (uint);
}

contract Vat {
    address public root;
    bool    public live;
    uint256 public forms;

    int256  public Line;
    int256  public lump;
    uint48  public wait;

    modifier auth {
        // todo: require(msg.sender == root);
        _;
    }

    struct Ilk {
        int256  spot;  // ray
        int256  rate;  // ray
        int256  line;  // wad
        int256  chop;  // ray

        int256  Art;   // wad

        address  flip;
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
        ilks[ilk].chop = RAY;
    }
    function file(bytes32 what, uint risk) public auth {
        if (what == "wait") wait = uint48(risk);
        if (what == "lump") lump = int256(risk);
        if (what == "Line") Line = int256(risk);
    }
    function file(bytes32 ilk, bytes32 what, uint risk) public auth {
        if (what == "spot") ilks[ilk].spot = int256(risk);
        if (what == "rate") ilks[ilk].rate = int256(risk);
        if (what == "line") ilks[ilk].line = int256(risk);
        if (what == "chop") ilks[ilk].chop = int256(risk);
        if (what == "wait") wait = uint48(risk);
        if (what == "lump") lump = int256(risk);
        if (what == "Line") Line = int256(risk);
    }
    function fuss(bytes32 ilk, address flip) public auth {
        ilks[ilk].flip = Flippy(flip);
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
    function burn(uint wad) public {
        require(wad <= uint(dai[msg.sender]));
        dai[msg.sender] = sub(dai[msg.sender], int(wad));
        Tab = sub(Tab, int(wad));
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
    struct Flip {
        bytes32 ilk;
        address lad;
        int256  ink;
        int256  tab;
    }
    Flip[] public flips;

    function bite(bytes32 ilk, address lad) public returns (uint) {
        Urn storage u = urns[ilk][lad];
        Ilk storage i = ilks[ilk];

        int ink = u.ink;
        int art = u.art;
        int tab = rmul(art, i.rate);

        u.ink = 0;
        u.art = 0;
        i.Art = sub(i.Art, art);

        require(rmul(ink, i.spot) < tab);  // !safe

        sin[era()] = add(sin[era()], tab);
        return flips.push(Flip(ilk, lad, ink, tab)) - 1;
    }
    mapping (uint48 => int) public sin;

    function grab(uint48 era_) public returns (uint tab) {
        require(era() >= era_ + wait);
        tab = uint(sin[era_]);
        sin[era_] = 0;
    }

    function flip(uint n, int wad) public returns (uint) {
        Flip storage f = flips[n];
        Ilk  storage i = ilks[f.ilk];

        require(wad <= f.tab);
        require(wad == lump || (wad < lump && wad == f.tab));

        int tab = f.tab;
        int ink = f.ink * wad / tab;

        f.tab = sub(f.tab, wad);
        f.ink = sub(f.ink, ink);

        return Flippy(i.flip).kick({ lad: f.lad
                                   , gal: this
                                   , tab: uint(rmul(wad, i.chop))
                                   , lot: uint(ink)
                                   , bid: uint(0)
                                   });
    }
}
