const { expect } = require('chai');

describe("Homework3 contract", function () {
    let owner, hw3;

    before("deploy the contract", async function () {
        [owner] = await ethers.getSigners();
        hw3 = await ethers.deployContract("Homework3");
    })

    it("check if pt is on curve", async function() {
        const A = [1, 2]
        expect(await hw3.isOnCurve(A)).to.equal(true);
    })

    it("performs modular inverse", async function() {
        expect(await hw3.modInverse(27, 392)).to.equal(363);
    })

    it("returns true if A + B == (num / den) mod curve_order * G1", async function() {
        // Rational numbers anum/aden, bnum/bden add up to num / den
        // 1/2 + 3/4 = 5/4
        const Ax = BigInt("10296210423881459776936787717049993391325552021605413991699412493845789633013")
        const Ay = BigInt("16532533273964472383651167452754510965928658867757334670578445799571582196663")
        const Bx = BigInt("2857625431839718922471812833357737477490018756027287331750692909542658596388")
        const By = BigInt("1911129795864509240059974873783816568594673160967429852131769465429209708149")
        const A = [Ax, Ay];
        const B = [Bx, By];
        const num = 5
        const den = 4
        expect(await hw3.rationalAdd(A, B, num, den)).to.equal(true);
    })

    it("matmul", async function(){
        // Let's solve for the system equation
        // 2x + 8y = 7944
        // 5x + 3y = 4764
        // Thus x=420 and y=888
        const matrix = [2, 8, 5, 3];
        const n = 2;
        // sx = 420 G1, sy = 888 G1 
        const sx = [BigInt("14272123054654457709936604042122767711746368495379248511670154852957621272879"), BigInt("5390793356463663377023184148570679692566494850099183968889446432602329490088")];
        const sy = [BigInt("16760028444954030715126837513142897443651137261182029666892102559655800691858"), BigInt("12495712043539181555106178299219046652619546681353186672747926470895059430081")];
        const s = [sx, sy];
        const o = [7944, 4764];
        expect(await hw3.matmul(matrix, n, s, o)).to.equal(true);
    })

})