pragma solidity ^0.4.24;

contract PitLike {
    function file(bytes32, bytes32, uint) public;
}

contract PipLike {
    function peek() public returns (bytes32, bool);
}

contract Spotter {
    PitLike public pit;
    bytes32 public ilk;
    PipLike public pip;
    uint256 public mat;

    mapping (address => uint) public wards;
    function rely(address guy) public auth { wards[guy] = 1;  }
    function deny(address guy) public auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- Init ---
    constructor(address pit_, bytes32 ilk_) public {
        wards[msg.sender] = 1;
        pit = PitLike(pit_);
        ilk = ilk_;
    }

    // --- Math ---
    uint256 constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function file(address pip_) public auth {
        pip = PipLike(pip_);
    }
    function file(uint mat_) public auth {
        mat = mat_;
    }

    // --- Update value ---
    function poke() public {
        (bytes32 val, bool zzz) = pip.peek();
        if (zzz) {
            pit.file(ilk, "spot", mul(mul(uint(val), 10 ** 9), ONE) / mat);
        }
    }
}
