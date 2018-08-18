pragma solidity ^0.4.24;

contract PitLike2 {
    function file(bytes32, bytes32, int) public;
}

contract PipLike {
    function peek() public returns (bytes32, bool);
}

contract Price {
    PitLike2 public pit;
    bytes32 public ilk;
    PipLike public pip;
    uint public mat;

    constructor(address pit_, bytes32 ilk_) public {
        pit = PitLike2(pit_);
        ilk = ilk_;
    }

    function setPip(address pip_) public /*auth*/ {
        pip = PipLike(pip_);
    }

    function setMat(uint mat_) public /*auth*/ {
        mat = mat_;
    }

    function poke() public {
        (bytes32 val, bool zzz) = pip.peek();
        if (zzz) {
            pit.file(ilk, "spot", int(uint(val) * 1 ether / mat));
        }
    }
}
