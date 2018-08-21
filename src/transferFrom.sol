/// transferFrom.sol -- Basic ERC20 interface

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.4.24;

contract VatLike {
    function dai(bytes32) public view returns (uint);
    function Tab() public view returns (uint);
    function move(bytes32,bytes32,uint) public;
}

contract Dai20 {
    VatLike public vat;
    constructor(address vat_) public  { vat = VatLike(vat_); }

    uint256 constant ONE = 10 ** 27;

    function balanceOf(address guy) public view returns (uint) {
        return vat.dai(bytes32(guy)) / ONE;
    }
    function totalSupply() public view returns (uint) {
        return vat.Tab() / ONE;
    }

    event Approval(address src, address dst, uint wad);
    event Transfer(address src, address dst, uint wad);

    mapping (address => mapping (address => uint)) public allowance;
    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] += wad;
        emit Approval(msg.sender, guy, wad * uint(-1));
        return true;
    }
    function approve(address guy) public {
        approve(guy, uint(-1));
    }

    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }
        vat.move(bytes32(src), bytes32(dst), wad * ONE);
        emit Transfer(src, dst, wad);
        return true;
    }
    function transfer(address guy, uint wad) public returns (bool) {
        transferFrom(msg.sender, guy, wad);
        return true;
    }

    function move(address src, address dst, uint wad) public {
        transferFrom(src, dst, wad);
    }
    function push(address dst, uint wad) public {
        transferFrom(msg.sender, dst, wad);
    }
    function pull(address src, uint wad) public {
        transferFrom(src, msg.sender, wad);
    }
}
