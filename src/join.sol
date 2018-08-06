// Copyright (C) 2018 AGPL

pragma solidity ^0.4.20;

contract GemLike {
    function move(address,address,uint) public;  // i.e. transferFrom
}

contract Fluxing {
    function slip(bytes32,address,int) public;
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
        vat.slip(ilk, msg.sender, int(wad));
    }
    function exit(uint wad) public {
        gem.move(this, msg.sender, wad);
        vat.slip(ilk, msg.sender, -int(wad));
    }
}
