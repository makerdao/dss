// Copyright (C) 2018 AGPL

pragma solidity ^0.4.23;

contract VatLike {
    function dai(address) public view returns (int);
    function Tab() public view returns (uint);
    function move(address,address,uint) public;
}

contract Dai20 {    /* erc20 is just, like, your opinion, bro */
    VatLike public vat;
    constructor(address vat_) public  { vat = VatLike(vat_); }

    function balanceOf(address guy) public view returns (uint) {
        return uint(vat.dai(guy));
    }
    function totalSupply() public view returns (uint) {
        return vat.Tab();
    }

    mapping (address => mapping (address => uint)) public allowance;
    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] += wad;
        return true;
    }

    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }
        vat.move(src, dst, wad);
        return true;
    }
    function transfer(address guy, uint wad) public returns (bool) {
        vat.move(msg.sender, guy, wad);
        return true;
    }

    function approve(address guy) public { approve(guy, uint(-1)); }
    function push(address guy, uint wad) public { transfer(guy, wad); }
    function move(address src, address dst, uint wad) public {
        transferFrom(src, dst, wad);
    }
}
