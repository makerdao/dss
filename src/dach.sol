/// dach.sol -- Dai automated clearing house

// Copyright (C) 2018 Martin Lundfall <martin@dapp.org>
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
    function dai(address) public view returns (int);
    function Tab() public view returns (uint);
    function move(address,address,uint) public;
}

contract Dach {
    
    VatLike public vat;
    constructor(address vat_) public  { vat = VatLike(vat_); }

    mapping (address => uint256) public nonces;
    //EIP712 typed signature data
    //See ds-relay how these are generated.
    //DOMAIN_SEPARATOR as it now stands has verifyingContract hardcoded as 0xdeadbeef,
    //needs to be changed to the address of this contract
    bytes32 constant DOMAIN_SEPARATOR = 0x29bef1ce195b339669d5fb9ef64a866a66aac1d21c45db1f6388c6c92d280808;
    bytes32 constant CHEQUE_TYPEHASH = 0x3f2386d9e00bfe3dbbdeb444816f2d701398001e2c2b9051190e2198f4f46caa;
    
    struct Cheque {
       address sender;
       address receiver;
       uint256 amount;
       uint256 fee;
       uint256 nonce;
    }

    function hash(Cheque cheque) internal pure returns (bytes32) {
       return keccak256(abi.encode(
          CHEQUE_TYPEHASH,
          cheque.sender,
          cheque.receiver,
          cheque.amount,
          cheque.fee,
          cheque.nonce
       ));
    }

    function verify(Cheque cheque, uint8 v, bytes32 r, bytes32 s) internal returns (bool) {
       bytes32 digest = keccak256(abi.encodePacked(
                             "\x19\x01",
                             DOMAIN_SEPARATOR,
                             hash(cheque)
                         ));
       return ecrecover(digest, v, r, s) == cheque.sender;
    }


    function clear(address _sender, address _receiver, uint _amount, uint _fee, uint _nonce, uint8 v, bytes32 r, bytes32 s) public {
       Cheque memory cheque = Cheque({
          sender   : _sender,
          receiver : _receiver,
          amount   : _amount,
          fee      : _fee,
          nonce    : _nonce
       });
       require(verify(cheque, v, r, s));
       require(cheque.nonce == nonces[cheque.sender]);
       vat.move(cheque.sender, msg.sender, cheque.fee);
       vat.move(cheque.sender, cheque.receiver, cheque.amount);
       nonces[cheque.sender]++;
    }
}
