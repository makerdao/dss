// Copyright (C) 2018 AGPL

pragma solidity ^0.4.24;

contract VatLike {
    function dai(address) public view returns (int);
    function Tab() public view returns (uint);
    function move(address,address,uint) public;
}

contract Relay {
    VatLike public vat;
    constructor(address vat_) public  { vat = VatLike(vat_); }

    mapping (address => uint256) public nonces;

    //See ds-relay how these are generated.
    //DOMAIN_SEPARATOR as it now stands has verifyingContract hardcoded as 0xdeadbeef,
    //needs to be changed to the address of this contract
    bytes32 constant DOMAIN_SEPARATOR = 0xcefc3efd3e12749cf6849e637e99c71315209ccc419b8d6a6c967a71e7edd86b;
    bytes32 constant CHEQUE_TYPEHASH = 0x7eb02bee71261bc514e2fa911172c93f74df70e1e57befd4a626f0ab26784c42;

    struct EIP712Domain {
       string  name;
       string  version;
       uint256 chainId;
       address verifyingContract;
    }
    
    struct Cheque {
       address src;
       address dst;
       uint256 wad;
       uint256 fee;
       uint256 nonce;
    }

    function hash(Cheque cheque) internal pure returns (bytes32) {
       return keccak256(abi.encode(
          CHEQUE_TYPEHASH,
          cheque.src,
          cheque.dst,
          cheque.wad,
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
       return ecrecover(digest, v, r, s) == cheque.src;
    }


    function relay(address _src, address _dst, uint _wad, uint _fee, uint _nonce, uint8 v, bytes32 r, bytes32 s) public {
       Cheque memory cheque = Cheque({
          src : _src,
          dst : _dst,
          wad : _wad,
          fee : _fee,
          nonce : _nonce
       });
       require(verify(cheque, v, r, s));
       require(cheque.nonce == nonces[cheque.src]);
       vat.move(cheque.src, msg.sender, cheque.fee);
       vat.move(cheque.src, cheque.dst, cheque.wad);
       nonces[cheque.src]++;
    }
}
