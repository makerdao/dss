// Copyright (C) 2018 AGPL

pragma solidity ^0.4.24;

import './tune.sol';

contract Lad {
    Vat   public  vat;
    int   public Line;
    bool  public live;

    constructor(address vat_) public { vat = Vat(vat_); live = true; }

    modifier auth { _; }  // todo: require(msg.sender == root);

    struct Ilk {
        int256  spot;  // ray
        int256  line;  // wad
    }

    mapping (bytes32 => Ilk) public ilks;

    function file(bytes32 what, int risk) public auth {
        if (what == "Line") Line = risk;
    }
    function file(bytes32 ilk, bytes32 what, int risk) public auth {
        if (what == "spot") ilks[ilk].spot = risk;
        if (what == "line") ilks[ilk].line = risk;
    }

    int256 constant ONE = 10 ** 27;
    function rmul(int x, int y) internal pure returns (int z) {
        z = x * y;
        require(y >= 0 || x != -2**255);
        require(y == 0 || z / y == x);
        z = z / ONE;
    }

    function frob(bytes32 ilk, int dink, int dart) public {
        vat.tune(ilk, msg.sender, dink, dart);
        Ilk storage i = ilks[ilk];

        (int rate, int Art)           = vat.ilks(ilk);
        (int gem,  int ink,  int art) = vat.urns(ilk, msg.sender); gem;
        bool calm = rmul(Art, rate) <= ilks[ilk].line && vat.Tab() < Line;
        bool cool = dart <= 0;
        bool firm = dink >= 0;
        bool safe = rmul(ink, i.spot) >= rmul(art, rate);

        require(( calm || cool ) && ( cool && firm || safe ) && live);
        require(rate != 0);
    }
}
