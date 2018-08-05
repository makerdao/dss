// Copyright (C) 2018 AGPL

pragma solidity ^0.4.24;

import './tune.sol';

contract Lad {
    Vat   public  vat;
    int   public Line;
    bool  public live;

    constructor(address vat_) public { vat = Vat(vat_); live = true; }

    modifier auth { _; }  // todo

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

    function mul(int x, int y) internal pure returns (int z) {
        z = x * y;
        require(y >= 0 || x != -2**255);
        require(y == 0 || z / y == x);
    }

    int256 constant ONE = 10 ** 27;

    function frob(bytes32 ilk, int dink, int dart) public {
        vat.tune(ilk, msg.sender, dink, dart);
        Ilk storage i = ilks[ilk];

        (int rate, int Art)           = vat.ilks(ilk);
        (int gem,  int ink,  int art) = vat.urns(ilk, msg.sender); gem;
        bool calm = mul(Art, rate) <= mul(ilks[ilk].line, ONE) &&
                        vat.Tab()  <  mul(Line, ONE);
        bool cool = dart <= 0;
        bool firm = dink >= 0;
        bool safe = mul(ink, i.spot) >= mul(art, rate);

        require(( calm || cool ) && ( cool && firm || safe ) && live);
        require(rate != 0);
    }
}
