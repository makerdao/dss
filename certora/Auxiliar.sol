pragma solidity 0.5.12;

interface IERC1271 {
    function isValidSignature(
        bytes32,
        bytes calldata
    ) external view returns (bytes4);
}

contract Auxiliar {    
    function computeDigestForDai(
        bytes32 domain_separator,
        bytes32 permit_typehash,
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed
    ) public pure returns (bytes32 digest){
        digest =
        keccak256(abi.encodePacked(
            "\x19\x01",
            domain_separator,
            keccak256(abi.encode(
                permit_typehash,
                holder,
                spender,
                nonce,
                expiry,
                allowed
            ))
        ));
    }

    function call_ecrecover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address signer) {
        signer = ecrecover(digest, v, r, s);
    }
}
