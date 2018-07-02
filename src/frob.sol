// Copyright (C) 2018 AGPL

pragma solidity ^0.4.23;

import "src/logEvents.sol";

contract GemLike {
    function move(address,address,uint) public;
}

contract Flippy{
    function kick(address lad, address gal, uint tab, uint lot, uint bid)
        public returns (uint);
}

contract Fusspot {
    function kick(address gal, uint lot, uint bid) public returns (uint);
}

contract Vat is LogEvents {
    address public root;
    bool    public live;
    uint256 public forms;

    address public flapper;
    address public flopper;

    uint256 public Line;
    uint256 public lump;
    uint48  public wait;

    struct Ilk {
        uint256  spot;  // ray
        uint256  rate;  // ray
        uint256  line;  // wad
        uint256  chop;  // ray

        uint256  Art;   // wad

        address  flip;
    }
    struct Urn {
        uint256 gem;
        uint256 ink;
        uint256 art;
    }

    mapping (address => int256)                   public dai;
    mapping (bytes32 => Ilk)                      public ilks;
    mapping (bytes32 => mapping (address => Urn)) public urns;

    function Gem(bytes32 ilk, address lad) public view returns (uint) {
        return urns[ilk][lad].gem;
    }
    function Ink(bytes32 ilk, address lad) public view returns (uint) {
        return urns[ilk][lad].ink;
    }
    function Art(bytes32 ilk, address lad) public view returns (uint) {
        return urns[ilk][lad].art;
    }
    uint public Tab;

    function era() public view returns (uint48) { return uint48(now); }

    uint constant RAY = 10 ** 27;
    uint constant MAXINT = uint(-1) / 2;
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function rmuli(uint x, int y) internal pure returns (int z) {
        return y > 0 ? int(rmul(x, uint(y))) : -int(rmul(x, uint(-y)));
    }
    function addi(uint x, int y) internal pure returns (uint z) {
        z = uint(int(x) + y);  // todo safety
    }
    function subi(uint x, int y) internal pure returns (uint z) {
        z = uint(int(x) - y);  // todo safety
    }

    constructor() public {
        root = msg.sender;
        live = true;
    }

    // --- Administration Engine ---
    function form() public returns (bytes32 ilk) {   // todo auth
        ilk = bytes32(++forms);
        ilks[ilk].rate = RAY;
        ilks[ilk].chop = RAY;
    }
    function file(bytes32 what, uint risk) public {  // todo auth
        if (what == "wait") wait = uint48(risk);
        if (what == "lump") lump = risk;
        if (what == "Line") Line = risk;
    }
    function file(bytes32 ilk, bytes32 what, uint risk) public {  // todo auth
        if (what == "spot") ilks[ilk].spot = risk;
        if (what == "rate") ilks[ilk].rate = risk;
        if (what == "line") ilks[ilk].line = risk;
        if (what == "chop") ilks[ilk].chop = risk;
        if (what == "wait") wait = uint48(risk);
        if (what == "lump") lump = risk;
        if (what == "Line") Line = risk;
    }
    function tiff(bytes32 ilk, address flip) public {       // todo auth
        ilks[ilk].flip = Flippy(flip);
    }
    function taff(address flap) public { flapper = flap; }  // todo auth
    function toff(address flop) public { flopper = flop; }  // todo auth

    function flux(bytes32 ilk, address lad, int wad) public {  // todo auth
        urns[ilk][lad].gem = addi(urns[ilk][lad].gem, wad);
    }

    // --- Fungibility Engine ---
    function move(address src, address dst, uint256 wad) public {  // todo auth
        require(dai[src] >= int(wad));
        dai[src] -= int(wad);
        dai[dst] += int(wad);
    }

    // --- CDP Engine ---
    function frob(bytes32 ilk, int dink, int dart) public {
        Urn storage u = urns[ilk][msg.sender];
        Ilk storage i = ilks[ilk];

        u.gem = addi(u.gem, -dink);
        u.ink = addi(u.ink,  dink);

        dai[msg.sender] += rmuli(i.rate, dart);
        u.art = addi(u.art, dart);
        i.Art = addi(i.Art, dart);
        Tab   = addi(  Tab, rmuli(i.rate, dart));

        bool calm = rmul(i.Art, i.rate) <= i.line && Tab < Line;

        bool cool = dart <= 0;
        bool firm = dink >= 0;
        bool safe = rmul(u.ink, i.spot) >= rmul(u.art, i.rate);

        require(( calm || cool ) && ( cool && firm || safe ) && live);

        emit LogFrob(ilk, msg.sender, u.gem, u.ink, u.art, i.Art, uint48(now));
    }

    // --- Stability Engine ---
    function drip(int wad) public {  // todo auth
        dai[this] += wad;
        Tab = addi(Tab, wad);
    }

    // --- Liquidation Engine ---
    struct Flip {
        bytes32 ilk;
        address lad;
        uint256 ink;
        uint256 tab;
    }
    Flip[] public flips;
    mapping (uint48 => uint) public sin;

    function bite(bytes32 ilk, address lad) public returns (uint) {
        Urn storage u = urns[ilk][lad];
        Ilk storage i = ilks[ilk];

        uint ink = u.ink;
        uint art = u.art;
        uint tab = rmul(art, i.rate);

        u.ink = 0;
        u.art = 0;
        i.Art = sub(i.Art, art);

        require(rmul(ink, i.spot) < tab);  // !safe

        sin[era()] = add(sin[era()], tab);

        emit LogBite(ilk, lad, ink, art, tab, i.Art);

        return flips.push(Flip(ilk, lad, ink, tab)) - 1;
    }
    function flog(uint48 tic) public {
        require(tic + wait <= era());
        dai[this] -= int(sin[tic]);
        Tab = sub(Tab, sin[tic]);
        sin[tic] = 0;
    }

    function flip(uint n, uint wad) public returns (uint) {
        Flip storage f = flips[n];
        Ilk  storage i = ilks[f.ilk];

        require(wad <= f.tab);
        require(wad == lump || (wad < lump && wad == f.tab));

        uint tab = f.tab;
        uint ink = f.ink * wad / tab;

        f.tab = sub(f.tab, wad);
        f.ink = sub(f.ink, ink);

        return Flippy(i.flip).kick({ lad: f.lad
                                   , gal: this
                                   , tab: rmul(wad, i.chop)
                                   , lot: ink
                                   , bid: 0
                                   });
    }
    function flap() public returns (uint) {
        require(dai[this] >= int(lump));
        return Fusspot(flapper).kick(this, lump, 0);
    }
    function flop() public returns (uint) {
        require(dai[this] <= -int(lump));
        return Fusspot(flopper).kick(this, uint(-1), lump);
    }
}
