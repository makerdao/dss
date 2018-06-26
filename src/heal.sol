pragma solidity ^0.4.23;

contract Fusspot {
    function kick(address gal, uint lot, uint bid) public returns (uint);
}

contract VatLike {
    function ilks(bytes32) public view returns (int,int);
    function urns(bytes32,address) public view returns (int,int,int);
    function dai(address) public view returns (int);
    function burn(uint) public;
    function grab(bytes32,address,address,int,int) public returns (uint);
}

contract Vow {
    address vat;
    address cow;  // flapper
    address row;  // flopper

    modifier auth {
        // todo: require(msg.sender == root);
        _;
    }

    function era() public view returns (uint48) { return uint48(now); }

    constructor(address vat_) public { vat = vat_; }

    mapping (uint48 => uint256) public sin; // debt queue
    uint256 public Sin;   // queued debt
    uint256 public Woe;   // pre-auction 'bad' debt
    uint256 public Ash;   // on-auction debt

    uint256 public wait;  // todo: flop delay
    uint256 public lump;  // fixed lot size
    uint256 public pad;   // surplus buffer

    function Awe() public view returns (uint) { return Sin + Woe + Ash; }
    function Joy() public view returns (uint) { return uint(VatLike(vat).dai(this)); }

    function file(bytes32 what, uint risk) public auth {
        if (what == "lump") lump = risk;
        if (what == "pad")  pad  = risk;
    }
    function file(bytes32 what, address fuss) public auth {
        if (what == "flap") cow = fuss;
        if (what == "flop") row = fuss;
    }
    function file(bytes32 ilk, bytes32 what, int risk) public auth {
        if (what == "chop") ilks[ilk].chop = risk;
    }
    function fuss(bytes32 ilk, address flip) public auth {
        ilks[ilk].flip = flip;
    }

    function heal(uint wad) public {
        require(wad <= Joy() && wad <= Woe);
        Woe -= wad;
        VatLike(vat).burn(wad);
    }
    function kiss(uint wad) public {
        require(wad <= Ash && wad <= Joy());
        Ash -= wad;
        VatLike(vat).burn(wad);
    }

    function flog(uint48 era_) public {
        Sin -= sin[era_];
        Woe += sin[era_];
        sin[era_] = 0;
    }

    function flop() public returns (uint) {
        require(Woe >= lump);
        require(Joy() == 0);
        Woe -= lump;
        Ash += lump;
        return Fusspot(row).kick(this, uint(-1), lump);
    }
    function flap() public returns (uint) {
        require(Joy() >= Awe() + lump + pad);
        require(Woe == 0);
        return Fusspot(cow).kick(this, lump, 0);
    }


    struct Ilk {
        int256  chop;
        address flip;
    }
    mapping (bytes32 => Ilk) public ilks;

    struct Flip {
        bytes32 ilk;
        address lad;
        uint256 ink;
        uint256 tab;
    }
    Flip[] public flips;

    function bite(bytes32 ilk, address lad) public returns (uint) {
        (int spot, int rate) = VatLike(vat).ilks(ilk);
        (int gem , int ink, int art) = VatLike(vat).urns(ilk, lad);
        gem;
        int tab = rmul(art, rate);

        require(rmul(ink, spot) < tab);  // !safe

        VatLike(vat).grab(ilk, lad, this, -ink, -art);

        sin[era()] += uint(tab);
        Sin += uint(tab);
        return flips.push(Flip(ilk, lad, uint(ink), uint(tab))) - 1;
    }

    function flip(uint n, uint wad) public returns (uint) {
        Flip storage f = flips[n];
        Ilk  storage i = ilks[f.ilk];

        require(wad <= f.tab);
        require(wad == lump || (wad < lump && wad == f.tab));

        uint tab = f.tab;
        uint ink = f.ink * wad / tab;

        f.tab -= wad;
        f.ink -= ink;

        return Flippy(i.flip).kick({ lad: f.lad
                                   , gal: this
                                   , tab: uint(rmul(int(wad), i.chop))
                                   , lot: uint(ink)
                                   , bid: uint(0)
                                   });
    }

    int constant RAY = 10 ** 27;
    function rmul(int x, int y) internal pure returns (int z) {
        z = x * y / RAY;
    }
}

contract Flippy{
    function kick(address lad, address gal, uint tab, uint lot, uint bid)
        public returns (uint);
}
