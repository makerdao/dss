// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.5.12;

contract VatLike {
    function hope(address) external;
}

contract GemJoinLike {
    function dec() external view returns (uint256);
    function gem() external view returns (TokenLike);
    function exit(address, uint256) external;
}

contract DaiJoinLike {
    function dai() external view returns (TokenLike);
    function vat() external view returns (VatLike);
    function join(address, uint256) external;
}

contract TokenLike {
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
}

contract OtcLike {
    function buyAllAmount(address, uint256, address, uint256) external returns (uint256);
    function sellAllAmount(address, uint256, address, uint256) external returns (uint256);
}

// Simple Callee Example to interact with MatchingMarket
contract CalleeMakerOtc {
    OtcLike         public otc;
    DaiJoinLike     public daiJoin;
    TokenLike       public dai;

    uint256         public constant RAY = 10 ** 27;

    constructor(address otc_, address oven_, address daiJoin_) public {
        otc = OtcLike(otc_);
        daiJoin = DaiJoinLike(daiJoin_);
        dai = daiJoin.dai();

        daiJoin.vat().hope(oven_);

        dai.approve(daiJoin_, uint(-1));
    }

    function _fromWad(address gemJoin, uint256 wad) internal returns (uint256 amt) {
        amt = wad / 10 ** (18 - GemJoinLike(gemJoin).dec());
    }
}

contract CalleeMakerOtcDai is CalleeMakerOtc {
    function ovenCall(
        uint256 daiAmt,         // Dai amount to payback[rad]
        uint256 gemAmt,         // Gem amount received [wad]
        bytes calldata data     // Extra data needed (gemJoin)
    ) external {
        // Get address to send remaining DAI, gemJoin adapter and minProfit in DAI to make
        (address to, address gemJoin, uint minProfit) = abi.decode(data, (address, address, uint256));

        // Convert gem amount to token precision
        gemAmt = _fromWad(gemJoin, gemAmt);

        // Exit collateral to token version
        GemJoinLike(gemJoin).exit(address(this), gemAmt);

        // Approve otc to take gem
        TokenLike gem = GemJoinLike(gemJoin).gem();
        gem.approve(address(otc), gemAmt);

        // Calculate amount of DAI to Join (as erc20 WAD value)
        uint256 daiToJoin = daiAmt / RAY;
        if (daiToJoin * RAY < daiAmt) {
            daiToJoin = daiToJoin + 1;
        }

        // Do operation and get dai amount bought (checking the profit is achieved)
        uint256 daiBought = otc.sellAllAmount(address(gem), gemAmt, address(dai), daiToJoin + minProfit);

        // Convert DAI bought to internal vat value
        daiJoin.join(address(this), daiToJoin);

        // Transfer remaining DAI to specified address
        dai.transfer(to, (daiBought - daiAmt) / RAY);
    }
}

contract CalleeMakerOtcGem is CalleeMakerOtc {
    function ovenCall(
        uint256 daiAmt,         // Dai amount to payback[rad]
        uint256 gemAmt,         // Gem amount received [wad]
        bytes calldata data     // Extra data needed (gemJoin)
    ) external {
        // Get address to send remaining Gem, gemJoin adapter and minProfit in Gem to make
        (address to, address gemJoin, uint minProfit) = abi.decode(data, (address, address, uint256));

        // Convert gem amount to token precision
        gemAmt = _fromWad(gemJoin, gemAmt);

        // Exit collateral to token version
        GemJoinLike(gemJoin).exit(address(this), gemAmt);

        // Approve otc to take gem
        TokenLike gem = GemJoinLike(gemJoin).gem();
        gem.approve(address(otc), gemAmt);

        // Calculate amount of DAI to Join (as erc20 WAD value)
        uint256 daiToJoin = daiAmt / RAY;
        if (daiToJoin * RAY < daiAmt) {
            daiToJoin = daiToJoin + 1;
        }

        // Do operation and get gem amount sold (checking the profit is achieved)
        uint256 gemSold = otc.buyAllAmount(address(dai), daiToJoin, address(gem), gemAmt - minProfit);
        // TODO: make sure daiToJoin is actually the amount received from buyAllAmount (due rounding)

        // Convert DAI bought to internal vat value
        daiJoin.join(address(this), daiToJoin);

        // Transfer remaining gem to specified address
        gem.transfer(to, gemAmt - gemSold);
    }
}

