pragma solidity ^0.4.23;

contract Fusspot {
    function kick(address gal, uint lot, uint bid) public returns (uint);
}

contract VatLike {
    function dai(address guy) public view returns (int);
    function burn(uint wad) public;
    function grab(uint48 era_) public returns (uint);
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

    function grab(uint48 era_) public {
        uint tab = VatLike(vat).grab(era_);
        sin[era_] += tab;
        Sin += tab;
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
}
