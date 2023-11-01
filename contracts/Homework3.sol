//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;
import "hardhat/console.sol";

contract Homework3 {
    struct ECPoint {
        uint256 x;
        uint256 y;
    }

    // Curve is y^2 = x^3 + 3
    // field modulus 21888242871839275222246405745257275088696311157297823662689037894645226208583
    uint256 p = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    // curve order 
    uint256 curve_order = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    function isOnCurve(ECPoint calldata pt) public view returns (bool) {
        // TODO: This results in too big a number
        // We need to implement this is with precompile modexp
        // address MODEXP = address(0x05);
        return ((pt.y**2 % p) == (pt.x**3 + 3) % p);
    }

    // From ChatGPT
    // TODO: To verify
    function modInverse(uint256 a, uint256 m) public pure returns (uint256){
        // Computes the modular multiplicative inverse of a modulo m using the Extended Euclidean algorithm
        // Returns the inverse, assuming that a and m are coprime
        if (a == 0) {
            revert("No inverse exists for zero.");
        }

        if (a > m) {
            // Normalize a in case a >= m
            a = a % m;
        }

        int256 t = 0;
        int256 newT = 1;
        uint256 r = m;
        uint256 newR = a;
        uint256 q;
        int256 tempT;
        uint256 tempR;

        while (newR != 0) {
            q = r / newR;

            tempT = newT;
            newT = t - int256(q) * newT;
            t = tempT;

            tempR = newR;
            newR = r - q * newR;
            r = tempR;
        }

        if (t < 0) {
            // If t is negative, make it positive by adding m
            t = int256(m) + t;
        }

        return uint256(t);
    }

    function rationalAdd(ECPoint calldata A, ECPoint calldata B, uint256 num, uint256 den) public view returns (bool verified) {
        // check if A and B are on EC
        // require (isOnCurve(A), "Point A is not on curve");
        // require (isOnCurve(B), "Point B is not on curve");
        // check if den is 0
        ECPoint memory C = ecadd(A, B);

        // compute num * mod_inv(den) * G1 
        uint256 s = mulmod(num, modInverse(den, curve_order), curve_order);

        ECPoint memory G1 = ECPoint(1, 2);
        ECPoint memory sG = ecmul(s, G1);

        // return true if the prover knows two numbers that add up to num/den
        return (C.x == sG.x && C.y == sG.y);
    }

    function ecadd(ECPoint memory A, ECPoint memory B) public view returns (ECPoint memory) {
        address ECADD = address(0x06);
        bytes memory data = abi.encodePacked(A.x, A.y, B.x, B.y);
        (bool success, bytes memory returnData) = ECADD.staticcall{gas:150}(data);
        require(success, "EC addition failed");
        ECPoint memory C;
        (C.x, C.y) = abi.decode(returnData, (uint256, uint256));
        return C;
    }

    function ecmul(uint256 s, ECPoint memory pt) public view returns (ECPoint memory) {
        address ECMUL = address(0x07);
        bytes memory data = abi.encodePacked(pt.x, pt.y, s);
        (bool success, bytes memory returnData) = ECMUL.staticcall{gas:6000}(data);

        require(success, "EC multiplication failed");
        ECPoint memory sG;
        (sG.x, sG.y) = abi.decode(returnData, (uint256, uint256));
        return sG;
    }

    function matmul(uint256[] calldata matrix,
                uint256 n, // n x n for the matrix
                ECPoint[] calldata s, // n elements
                uint256[] calldata o // n elements
               ) public view returns (bool verified) {

        // revert if dimensions don't make sense or the matrices are empty
        require(matrix.length == n*n, "matrix has the wrong dimension");
        require(s.length == n, "s has the wrong dimension");
        require(o.length == n, "o has the wrong dimension");

        // console.log(matrix.length, matrix[0]);
        // console.log(n);
        // console.log(s[0].x, s[0].y, s[1].x, s[1].y);
        // console.log(o[0], o[1]);

        uint rowStartIndex = 0;
        ECPoint[] memory Ms = new ECPoint[](n);
        ECPoint[] memory products = new ECPoint[](n);
        ECPoint memory G1 = ECPoint(1, 2);

        for (uint i=0; i<n; i++) {
            rowStartIndex = i*n;
            for (uint j=0; j<n; j++) {
                products[j] = ecmul(matrix[rowStartIndex+j], s[j]);
                
                if (j == 0) {
                    Ms[i] = products[j];
                } else {
                    Ms[i] = ecadd(Ms[i], products[j]);
                }

                if (j == n-1) {
                    ECPoint memory oG = ecmul(o[i], G1);
                    console.log(Ms[i].x, oG.x, Ms[i].y, oG.y);

                    if (Ms[i].x != oG.x ||
                        Ms[i].y != oG.y)
                        return false;
                }
            }
        }

        return true;
    }
}