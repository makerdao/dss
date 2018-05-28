// Copyright (C) 2018 AGPL

pragma solidity ^0.4.20;

contract GemLike {
    function move(address,address,uint) public;  // i.e. transferFrom
}

contract Fluxing {
    function flux(bytes32,address,int) public;
    function Gem(bytes32,address) public view returns (uint);
}

contract Adapter {
    Fluxing public vat;
    bytes32 public ilk;
    GemLike public gem;
    constructor(address vat_, bytes32 ilk_, address gem_) public {
        vat = Fluxing(vat_);
        ilk = ilk_;
        gem = GemLike(gem_);
    }
    function join(uint wad) public {
        gem.move(msg.sender, this, wad);
        vat.flux(ilk, msg.sender, int(wad));
    }
    function exit(uint wad) public {
        gem.move(this, msg.sender, wad);
        vat.flux(ilk, msg.sender, -int(wad));
    }
    function balanceOf(address guy) public view returns (uint) {
        return vat.Gem(ilk, guy);
    }
}
