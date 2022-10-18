// Vat.spec

methods {
    can(address, address) returns (uint256) envfree
    dai(address) returns (uint256) envfree
    debt() returns (uint256) envfree
    gem(bytes32, address) returns (uint256) envfree
    ilks(bytes32) returns (uint256, uint256, uint256, uint256, uint256) envfree
    Line() returns (uint256) envfree
    live() returns (uint256) envfree
    sin(address) returns (uint256) envfree
    urns(bytes32, address) returns (uint256, uint256) envfree
    vice() returns (uint256) envfree
    wards(address) returns (uint256) envfree
}

// definition WAD() returns uint256 = 10^18;
definition RAY() returns uint256 = 10^27;

definition min_int256() returns mathint = -1 * 2^255;
definition max_int256() returns mathint = 2^255 - 1;

// Verify fallback always reverts
// In this case is pretty important as we are filtering it out from some invariants/rules
rule fallback_revert(method f) filtered { f -> f.isFallback } {
    env e;

    calldataarg arg;
    f@withrevert(e, arg);

    assert(lastReverted, "Fallback did not revert");
}

// Verify that wards behaves correctly on rely
rule rely(address usr) {
    env e;

    address other;
    require(other != usr);
    uint256 wardOtherBefore = wards(other);

    rely(e, usr);

    uint256 wardAfter = wards(usr);
    uint256 wardOtherAfter = wards(other);

    assert(wardAfter == 1, "rely did not set wards as expected");
    assert(wardOtherAfter == wardOtherBefore, "rely affected other wards which was not expected");
}

// Verify revert rules on rely
rule rely_revert(address usr) {
    env e;

    uint256 ward = wards(e.msg.sender);
    uint256 live = live();

    rely@withrevert(e, usr);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;
    bool revert3 = live != 1;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");

    assert(lastReverted => revert1 || revert2 || revert3, "Revert rules are not covering all the cases");
}

// Verify that wards behaves correctly on deny
rule deny(address usr) {
    env e;

    address other;
    require(other != usr);
    uint256 wardOtherBefore = wards(other);

    deny(e, usr);

    uint256 wardAfter = wards(usr);
    uint256 wardOtherAfter = wards(other);

    assert(wardAfter == 0, "deny did not set wards as expected");
    assert(wardOtherAfter == wardOtherBefore, "deny affected other wards which was not expected");
}

// Verify revert rules on deny
rule deny_revert(address usr) {
    env e;

    uint256 ward = wards(e.msg.sender);
    uint256 live = live();

    deny@withrevert(e, usr);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;
    bool revert3 = live != 1;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");

    assert(lastReverted => revert1 || revert2 || revert3, "Revert rules are not covering all the cases");
}

// Verify that rate behaves correctly on init
rule init(bytes32 ilk) {
    env e;

    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(ilk);

    init(e, ilk);

    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(ilk);

    assert(rateAfter == RAY(), "init did not set rate as expected");
    assert(ArtAfter == ArtBefore, "init did not keep Art as expected");
    assert(spotAfter == spotBefore, "init did not keep spot as expected");
    assert(lineAfter == lineBefore, "init did not keep line as expected");
    assert(dustAfter == dustBefore, "init did not keep dust as expected");
}

// Verify revert rules on init
rule init_revert(bytes32 ilk) {
    env e;

    uint256 Art; uint256 rate; uint256 spot; uint256 line; uint256 dust;
    Art, rate, spot, line, dust = ilks(ilk);

    uint256 ward = wards(e.msg.sender);

    init@withrevert(e, ilk);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;
    bool revert3 = rate != 0;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");

    assert(lastReverted => revert1 || revert2 || revert3, "Revert rules are not covering all the cases");
}

// Verify that Line behaves correctly on file
rule file(bytes32 what, uint256 data) {
    env e;

    file(e, what, data);

    assert(Line() == data, "file did not set Line as expected");
}

// Verify revert rules on file
rule file_revert(bytes32 what, uint256 data) {
    env e;

    uint256 ward = wards(e.msg.sender);
    uint256 live = live();

    file@withrevert(e, what, data);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;
    bool revert3 = live != 1;
    bool revert4 = what != 0x4c696e6500000000000000000000000000000000000000000000000000000000; // what is not "Line"

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");
    assert(revert4 => lastReverted, "revert4 failed");

    assert(lastReverted => revert1 || revert2 || revert3 ||
                           revert4, "Revert rules are not covering all the cases");
}

// Verify that spot/line/dust behave correctly on file
rule file_ilk(bytes32 ilk, bytes32 what, uint256 data) {
    env e;

    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(ilk);

    file(e, ilk, what, data);

    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(ilk);

    assert(what == 0x73706f7400000000000000000000000000000000000000000000000000000000 => spotAfter == data, "file did not set spot as expected");
    assert(what != 0x73706f7400000000000000000000000000000000000000000000000000000000 => spotAfter == spotBefore, "file did not keep spot as expected");
    assert(what == 0x6c696e6500000000000000000000000000000000000000000000000000000000 => lineAfter == data, "file did not set line as expected");
    assert(what != 0x6c696e6500000000000000000000000000000000000000000000000000000000 => lineAfter == lineBefore, "file did not keep line as expected");
    assert(what == 0x6475737400000000000000000000000000000000000000000000000000000000 => dustAfter == data, "file did not set dust as expected");
    assert(what != 0x6475737400000000000000000000000000000000000000000000000000000000 => dustAfter == dustBefore, "file did not keep dust as expected");
    assert(ArtAfter == ArtBefore, "file did not keep Art as expected");
    assert(rateAfter == rateBefore, "file did not keep rate as expected");
}

// Verify revert rules on file
rule file_ilk_revert(bytes32 ilk, bytes32 what, uint256 data) {
    env e;

    uint256 ward = wards(e.msg.sender);
    uint256 live = live();

    file@withrevert(e, ilk, what, data);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;
    bool revert3 = live != 1;
    bool revert4 = what != 0x73706f7400000000000000000000000000000000000000000000000000000000 &&
                   what != 0x6c696e6500000000000000000000000000000000000000000000000000000000 &&
                   what != 0x6475737400000000000000000000000000000000000000000000000000000000;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");
    assert(revert4 => lastReverted, "revert4 failed");

    assert(lastReverted => revert1 || revert2 || revert3 ||
                           revert4, "Revert rules are not covering all the cases");
}

// Verify that live behaves correctly on cage
rule cage() {
    env e;

    cage(e);

    assert(live() == 0, "cage did not set live to 0");
}

// Verify revert rules on file
rule cage_revert() {
    env e;

    uint256 ward = wards(e.msg.sender);

    cage@withrevert(e);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");

    assert(lastReverted => revert1 || revert2, "Revert rules are not covering all the cases");
}

// Verify that can behaves correctly on hope
rule hope(address usr) {
    env e;

    address otherFrom;
    address otherTo;
    require(otherFrom != e.msg.sender || otherTo != usr);
    uint256 canOtherBefore = can(otherFrom, otherTo);

    hope(e, usr);

    uint256 canAfter = can(e.msg.sender, usr);
    uint256 canOtherAfter = can(otherFrom, otherTo);

    assert(canAfter == 1, "hope did not set can as expected");
    assert(canOtherAfter == canOtherBefore, "hope affected other can which was not expected");
}

// Verify revert rules on hope
rule hope_revert(address usr) {
    env e;

    hope@withrevert(e, usr);

    bool revert1 = e.msg.value > 0;

    assert(revert1 => lastReverted, "revert1 failed");

    assert(lastReverted => revert1, "Revert rules are not covering all the cases");
}

// Verify that can behaves correctly on nope
rule nope(address usr) {
    env e;

    address otherFrom;
    address otherTo;
    require(otherFrom != e.msg.sender || otherTo != usr);
    uint256 canOtherBefore = can(otherFrom, otherTo);

    nope(e, usr);

    uint256 canAfter = can(e.msg.sender, usr);
    uint256 canOtherAfter = can(otherFrom, otherTo);

    assert(canAfter == 0, "nope did not set can as expected");
    assert(canOtherAfter == canOtherBefore, "nope affected other can which was not expected");
}

// Verify revert rules on nope
rule nope_revert(address usr) {
    env e;

    nope@withrevert(e, usr);

    bool revert1 = e.msg.value > 0;

    assert(revert1 => lastReverted, "revert1 failed");

    assert(lastReverted => revert1, "Revert rules are not covering all the cases");
}

// Verify that gem behaves correctly on slip
rule slip(bytes32 ilk, address usr, int256 wad) {
    env e;

    bytes32 otherIlk;
    address otherUsr;
    require(otherIlk != ilk || otherUsr != usr);
    uint256 gemBefore = gem(ilk, usr);
    uint256 gemOtherBefore = gem(otherIlk, otherUsr);

    slip(e, ilk, usr, wad);

    uint256 gemAfter = gem(ilk, usr);
    uint256 gemOtherAfter = gem(otherIlk, otherUsr);

    assert(to_mathint(gemAfter) == to_mathint(gemBefore) + to_mathint(wad), "slip did not set gem as expected");
    assert(gemOtherAfter == gemOtherBefore, "slip affected other gem which was not expected");
}

// Verify revert rules on slip
rule slip_revert(bytes32 ilk, address usr, int256 wad) {
    env e;

    uint256 ward = wards(e.msg.sender);
    uint256 gem = gem(ilk, usr);

    slip@withrevert(e, ilk, usr, wad);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;
    bool revert3 = to_mathint(gem) + to_mathint(wad) < 0 || to_mathint(gem) + to_mathint(wad) > max_uint256;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");

    assert(lastReverted => revert1 || revert2 || revert3, "Revert rules are not covering all the cases");
}

// Verify that gems behave correctly on flux
rule flux(bytes32 ilk, address src, address dst, uint256 wad) {
    env e;

    bytes32 otherIlk;
    address otherUsr;
    require(otherIlk != ilk || (otherUsr != src && otherUsr != dst));
    uint256 gemSrcBefore = gem(ilk, src);
    uint256 gemDstBefore = gem(ilk, dst);
    uint256 gemOtherBefore = gem(otherIlk, otherUsr);

    flux(e, ilk, src, dst, wad);

    uint256 gemSrcAfter = gem(ilk, src);
    uint256 gemDstAfter = gem(ilk, dst);
    uint256 gemOtherAfter = gem(otherIlk, otherUsr);

    assert(src != dst => gemSrcAfter == gemSrcBefore - wad, "flux did not set src gem as expected");
    assert(src != dst => gemDstAfter == gemDstBefore + wad, "flux did not set dst gem as expected");
    assert(src == dst => gemSrcAfter == gemDstBefore, "flux did not keep gem as expected");
    assert(gemOtherAfter == gemOtherBefore, "flux affected other gem which was not expected");
}

// Verify revert rules on flux
rule flux_revert(bytes32 ilk, address src, address dst, uint256 wad) {
    env e;

    bool wish = src == e.msg.sender || can(src, e.msg.sender) == 1;
    uint256 gemSrc = gem(ilk, src);
    uint256 gemDst = gem(ilk, dst);

    flux@withrevert(e, ilk, src, dst, wad);

    bool revert1 = e.msg.value > 0;
    bool revert2 = !wish;
    bool revert3 = gemSrc < wad;
    bool revert4 = src != dst && gemDst + wad > max_uint256;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");
    assert(revert4 => lastReverted, "revert4 failed");

    assert(lastReverted => revert1 || revert2 || revert3 ||
                           revert4, "Revert rules are not covering all the cases");
}

// Verify that dais behave correctly on move
rule move(address src, address dst, uint256 rad) {
    env e;

    address otherUsr;
    require(otherUsr != src && otherUsr != dst);
    uint256 daiSrcBefore = dai(src);
    uint256 daiDstBefore = dai(dst);
    uint256 daiOtherBefore = dai(otherUsr);

    move(e, src, dst, rad);

    uint256 daiSrcAfter = dai(src);
    uint256 daiDstAfter = dai(dst);
    uint256 daiOtherAfter = dai(otherUsr);

    assert(src != dst => daiSrcAfter == daiSrcBefore - rad, "move did not set src dai as expected");
    assert(src != dst => daiDstAfter == daiDstBefore + rad, "move did not set dst dai as expected");
    assert(src == dst => daiSrcAfter == daiDstBefore, "move did not keep dai as expected");
    assert(daiOtherAfter == daiOtherBefore, "move affected other dai which was not expected");
}

// Verify revert rules on move
rule move_revert(address src, address dst, uint256 rad) {
    env e;

    bool wish = src == e.msg.sender || can(src, e.msg.sender) == 1;
    uint256 daiSrc = dai(src);
    uint256 daiDst = dai(dst);

    move@withrevert(e, src, dst, rad);

    bool revert1 = e.msg.value > 0;
    bool revert2 = !wish;
    bool revert3 = daiSrc < rad;
    bool revert4 = src != dst && daiDst + rad > max_uint256;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");
    assert(revert4 => lastReverted, "revert4 failed");

    assert(lastReverted => revert1 || revert2 || revert3 ||
                           revert4, "Revert rules are not covering all the cases");
}

// Verify that variables behave correctly on frob
rule frob(bytes32 i, address u, address v, address w, int256 dink, int256 dart) {
    env e;

    bytes32 otherIlk;
    address otherUsrU;
    address otherUsrV;
    address otherUsrW;
    require((otherIlk != i || otherUsrU != u) && (otherIlk != i || otherUsrV != v) && otherUsrW != w);

    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(i);

    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(i, u);

    uint256 gemBefore = gem(i, v);
    uint256 daiBefore = dai(w);
    uint256 debtBefore = debt();

    uint256 inkOtherBefore; uint256 artOtherBefore;
    inkOtherBefore, artOtherBefore = urns(otherIlk, otherUsrU);

    uint256 gemOtherBefore = gem(otherIlk, otherUsrV);
    uint256 daiOtherBefore = dai(otherUsrW);

    frob(e, i, u, v, w, dink, dart);

    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(i);

    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(i, u);

    uint256 gemAfter = gem(i, v);
    uint256 daiAfter = dai(w);
    uint256 debtAfter = debt();

    uint256 inkOtherAfter; uint256 artOtherAfter;
    inkOtherAfter, artOtherAfter = urns(otherIlk, otherUsrU);

    uint256 gemOtherAfter = gem(otherIlk, otherUsrV);
    uint256 daiOtherAfter = dai(otherUsrW);

    assert(to_mathint(inkAfter) == to_mathint(inkBefore) + to_mathint(dink), "frob did not set u ink as expected");
    assert(to_mathint(artAfter) == to_mathint(artBefore) + to_mathint(dart), "frob did not set u art as expected");
    assert(to_mathint(ArtAfter) == to_mathint(ArtBefore) + to_mathint(dart), "frob did not set Art as expected");
    assert(to_mathint(debtAfter) == to_mathint(debtBefore) + to_mathint(rateBefore) * to_mathint(dart), "frob did not set debt as expected");
    assert(to_mathint(gemAfter) == to_mathint(gemBefore) - to_mathint(dink), "frob did not set v gem as expected");
    assert(to_mathint(daiAfter) == to_mathint(daiBefore) + to_mathint(rateBefore) * to_mathint(dart), "frob did not set w dai as expected");
    assert(to_mathint(inkOtherAfter) == to_mathint(inkOtherBefore), "frob did not keep other ink as expected");
    assert(to_mathint(artOtherAfter) == to_mathint(artOtherBefore), "frob did not keep other art as expected");
    assert(rateAfter == rateBefore, "frob did not keep rate as expected");
    assert(spotAfter == spotBefore, "frob did not keep spot as expected");
    assert(lineAfter == lineBefore, "frob did not keep line as expected");
    assert(dustAfter == dustBefore, "frob did not keep dust as expected");
    assert(gemOtherAfter == gemOtherBefore, "frob did not keep other gem as expected");
    assert(daiOtherAfter == daiOtherBefore, "frob did not keep other dai as expected");
}

// Verify revert rules on frob
function frob_revert_internal(bytes32 i, address u, address v, address w, int256 dink, int256 dart) {
    env e;

    uint256 live = live();

    bool wishU = u == e.msg.sender || can(u, e.msg.sender) == 1;
    bool wishV = v == e.msg.sender || can(v, e.msg.sender) == 1;
    bool wishW = w == e.msg.sender || can(w, e.msg.sender) == 1;

    uint256 Line = Line();

    uint256 Art; uint256 rate; uint256 spot; uint256 line; uint256 dust;
    Art, rate, spot, line, dust = ilks(i);

    uint256 ink; uint256 art;
    ink, art = urns(i, u);

    uint256 gem = gem(i, v);
    uint256 dai = dai(w);
    uint256 debt = debt();

    mathint inkFinal = to_mathint(ink) + to_mathint(dink);
    mathint artFinal = to_mathint(art) + to_mathint(dart);
    mathint ArtFinal = to_mathint(Art) + to_mathint(dart);
    mathint debtFinal = to_mathint(debt) + to_mathint(rate) * to_mathint(dart);

    frob@withrevert(e, i, u, v, w, dink, dart);

    bool revert1  = e.msg.value > 0;
    bool revert2  = live != 1;
    bool revert3  = rate == 0;
    bool revert4  = to_mathint(ink) + to_mathint(dink) < 0 || to_mathint(ink) + to_mathint(dink) > max_uint256;
    bool revert5  = to_mathint(art) + to_mathint(dart) < 0 || to_mathint(art) + to_mathint(dart) > max_uint256;
    bool revert6  = to_mathint(Art) + to_mathint(dart) < 0 || to_mathint(Art) + to_mathint(dart) > max_uint256;
    bool revert7  = rate > max_int256();
    bool revert8  = to_mathint(rate) * to_mathint(dart) < min_int256() || to_mathint(rate) * to_mathint(dart) > max_int256();
    bool revert9  = rate * artFinal > max_uint256;
    bool revert10 = to_mathint(debt) + to_mathint(rate) * to_mathint(dart) < 0 || to_mathint(debt) + to_mathint(rate) * to_mathint(dart) > max_uint256;
    bool revert11 = ArtFinal * rate > max_uint256;
    bool revert12 = dart > 0 && (ArtFinal * rate > line || debtFinal > Line);
    bool revert13 = inkFinal * spot > max_uint256;
    bool revert14 = (dart > 0 || dink < 0) && rate * artFinal > inkFinal * spot;
    bool revert15 = (dart > 0 || dink < 0) && !wishU;
    bool revert16 = dink > 0 && !wishV;
    bool revert17 = dart < 0 && !wishW;
    bool revert18 = artFinal > 0 && rate * artFinal < dust;
    bool revert19 = to_mathint(gem) - to_mathint(dink) < 0 || to_mathint(gem) - to_mathint(dink) > max_uint256;
    bool revert20 = to_mathint(dai) + to_mathint(rate) * to_mathint(dart) < 0 || to_mathint(dai) + to_mathint(rate) * to_mathint(dart) > max_uint256;

    assert(revert1  => lastReverted, "revert1 failed");
    assert(revert2  => lastReverted, "revert2 failed");
    assert(revert3  => lastReverted, "revert3 failed");
    assert(revert4  => lastReverted, "revert4 failed");
    assert(revert5  => lastReverted, "revert5 failed");
    assert(revert6  => lastReverted, "revert6 failed");
    assert(revert7  => lastReverted, "revert7 failed");
    assert(revert8  => lastReverted, "revert8 failed");
    assert(revert9  => lastReverted, "revert9 failed");
    assert(revert10 => lastReverted, "revert10 failed");
    assert(revert11 => lastReverted, "revert11 failed");
    assert(revert12 => lastReverted, "revert12 failed");
    assert(revert13 => lastReverted, "revert13 failed");
    assert(revert14 => lastReverted, "revert14 failed");
    assert(revert15 => lastReverted, "revert15 failed");
    assert(revert16 => lastReverted, "revert16 failed");
    assert(revert17 => lastReverted, "revert17 failed");
    assert(revert18 => lastReverted, "revert18 failed");
    assert(revert19 => lastReverted, "revert19 failed");
    assert(revert20 => lastReverted, "revert20 failed");

    assert(lastReverted => revert1  || revert2  || revert3  ||
                        revert4  || revert5  || revert6  ||
                        revert7  || revert8  || revert9  ||
                        revert10 || revert11 || revert12 ||
                        revert13 || revert14 || revert15 ||
                        revert16 || revert17 || revert18 ||
                        revert19 || revert20, "Revert rules are not covering all the cases");
}

rule frob_revert_1(bytes32 i, address u, address v, address w, int256 dink, int256 dart) {
    require(dink >= 0);
    require(dart >= 0);
    frob_revert_internal(i, u, v, w, dink, dart);
}

rule frob_revert_2(bytes32 i, address u, address v, address w, int256 dink, int256 dart) {
    require(dink >= 0);
    require(dart < 0);
    frob_revert_internal(i, u, v, w, dink, dart);
}

rule frob_revert_3(bytes32 i, address u, address v, address w, int256 dink, int256 dart) {
    require(dink < 0);
    require(dart >= 0);
    frob_revert_internal(i, u, v, w, dink, dart);
}

rule frob_revert_4(bytes32 i, address u, address v, address w, int256 dink, int256 dart) {
    require(dink < 0);
    require(dart < 0);
    frob_revert_internal(i, u, v, w, dink, dart);
}

// Verify that variables behave correctly on fork
rule fork(bytes32 ilk, address src, address dst, int256 dink, int256 dart) {
    env e;

    bytes32 otherIlk;
    address otherUsr;
    require(otherIlk != ilk || otherUsr != src && otherUsr != dst);

    uint256 inkSrcBefore; uint256 artSrcBefore;
    inkSrcBefore, artSrcBefore = urns(ilk, src);

    uint256 inkDstBefore; uint256 artDstBefore;
    inkDstBefore, artDstBefore = urns(ilk, dst);

    uint256 inkOtherBefore; uint256 artOtherBefore;
    inkOtherBefore, artOtherBefore = urns(otherIlk, otherUsr);

    fork(e, ilk, src, dst, dink, dart);

    uint256 inkSrcAfter; uint256 artSrcAfter;
    inkSrcAfter, artSrcAfter = urns(ilk, src);

    uint256 inkDstAfter; uint256 artDstAfter;
    inkDstAfter, artDstAfter = urns(ilk, dst);

    uint256 inkOtherAfter; uint256 artOtherAfter;
    inkOtherAfter, artOtherAfter = urns(otherIlk, otherUsr);

    assert(src != dst => to_mathint(inkSrcAfter) == to_mathint(inkSrcBefore) - to_mathint(dink), "fork did not set src ink as expected");
    assert(src != dst => to_mathint(artSrcAfter) == to_mathint(artSrcBefore) - to_mathint(dart), "fork did not set src art as expected");
    assert(src != dst => to_mathint(inkDstAfter) == to_mathint(inkDstBefore) + to_mathint(dink), "fork did not set dst ink as expected");
    assert(src != dst => to_mathint(artDstAfter) == to_mathint(artDstBefore) + to_mathint(dart), "fork did not set dst art as expected");
    assert(src == dst => to_mathint(inkSrcAfter) == to_mathint(inkSrcBefore), "fork did not keep src/dst ink as expected");
    assert(src == dst => to_mathint(artSrcAfter) == to_mathint(artSrcBefore), "fork did not keep src/dst art as expected");
    assert(to_mathint(inkOtherAfter) == to_mathint(inkOtherBefore), "fork did not keep other ink as expected");
    assert(to_mathint(artOtherAfter) == to_mathint(artOtherBefore), "fork did not keep other art as expected");
}

// Verify revert rules on fork
rule fork_revert(bytes32 ilk, address src, address dst, int256 dink, int256 dart) {
    env e;

    uint256 ward = wards(e.msg.sender);

    bool wishSrc = src == e.msg.sender || can(src, e.msg.sender) == 1;
    bool wishDst = dst == e.msg.sender || can(dst, e.msg.sender) == 1;

    uint256 Art; uint256 rate; uint256 spot; uint256 line; uint256 dust;
    Art, rate, spot, line, dust = ilks(ilk);

    uint256 inkSrc; uint256 artSrc;
    inkSrc, artSrc = urns(ilk, src);

    uint256 inkDst; uint256 artDst;
    inkDst, artDst = urns(ilk, dst);

    mathint inkSrcFinal = src != dst ? to_mathint(inkSrc) - to_mathint(dink) : to_mathint(inkSrc);
    mathint artSrcFinal = src != dst ? to_mathint(artSrc) - to_mathint(dart) : to_mathint(artSrc);
    mathint inkDstFinal = src != dst ? to_mathint(inkDst) + to_mathint(dink) : to_mathint(inkDst);
    mathint artDstFinal = src != dst ? to_mathint(artDst) + to_mathint(dart) : to_mathint(artDst);

    fork@withrevert(e, ilk, src, dst, dink, dart);

    bool revert1  = e.msg.value > 0;
    bool revert2  = to_mathint(inkSrc) - to_mathint(dink) < 0 || to_mathint(inkSrc) - to_mathint(dink) > max_uint256;
    bool revert3  = to_mathint(artSrc) - to_mathint(dart) < 0 || to_mathint(artSrc) - to_mathint(dart) > max_uint256;
    bool revert4  = src != dst && (to_mathint(inkDst) + to_mathint(dink) < 0 || to_mathint(inkDst) + to_mathint(dink) > max_uint256);
    bool revert5  = src != dst && (to_mathint(artDst) + to_mathint(dart) < 0 || to_mathint(artDst) + to_mathint(dart) > max_uint256);
    bool revert6  = artSrcFinal * to_mathint(rate) > max_uint256;
    bool revert7  = artDstFinal * to_mathint(rate) > max_uint256;
    bool revert8  = !wishSrc || !wishDst;
    bool revert9  = inkSrcFinal * to_mathint(spot) > max_uint256;
    bool revert10 = artSrcFinal * to_mathint(rate) > inkSrcFinal * to_mathint(spot);
    bool revert11 = inkDstFinal * to_mathint(spot) > max_uint256;
    bool revert12 = artDstFinal * to_mathint(rate) > inkDstFinal * to_mathint(spot);
    bool revert13 = artSrcFinal * to_mathint(rate) < dust && artSrcFinal != 0;
    bool revert14 = artDstFinal * to_mathint(rate) < dust && artDstFinal != 0;

    assert(revert1  => lastReverted, "revert1 failed");
    assert(revert2  => lastReverted, "revert2 failed");
    assert(revert3  => lastReverted, "revert3 failed");
    assert(revert4  => lastReverted, "revert4 failed");
    assert(revert5  => lastReverted, "revert5 failed");
    assert(revert6  => lastReverted, "revert6 failed");
    assert(revert7  => lastReverted, "revert7 failed");
    assert(revert8  => lastReverted, "revert8 failed");
    assert(revert9  => lastReverted, "revert9 failed");
    assert(revert10 => lastReverted, "revert10 failed");
    assert(revert11 => lastReverted, "revert11 failed");
    assert(revert12 => lastReverted, "revert12 failed");
    assert(revert13 => lastReverted, "revert13 failed");
    assert(revert14 => lastReverted, "revert14 failed");

    assert(lastReverted => revert1  || revert2  || revert3  ||
                           revert4  || revert5  || revert6  ||
                           revert7  || revert8  || revert9  ||
                           revert10 || revert11 || revert12 ||
                           revert13 || revert14, "Revert rules are not covering all the cases");
}

// Verify that variables behave correctly on grab
rule grab(bytes32 i, address u, address v, address w, int256 dink, int256 dart) {
    env e;

    bytes32 otherIlk;
    address otherUsrU;
    address otherUsrV;
    address otherUsrW;
    require((otherIlk != i || otherUsrU != u) && (otherIlk != i || otherUsrV != v) && otherUsrW != w);

    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(i);

    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(i, u);

    uint256 gemBefore = gem(i, v);
    uint256 sinBefore = sin(w);
    uint256 viceBefore = vice();

    uint256 inkOtherBefore; uint256 artOtherBefore;
    inkOtherBefore, artOtherBefore = urns(otherIlk, otherUsrU);

    uint256 gemOtherBefore = gem(otherIlk, otherUsrV);
    uint256 sinOtherBefore = sin(otherUsrW);

    grab(e, i, u, v, w, dink, dart);

    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(i);

    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(i, u);

    uint256 gemAfter = gem(i, v);
    uint256 sinAfter = sin(w);
    uint256 viceAfter = vice();

    uint256 inkOtherAfter; uint256 artOtherAfter;
    inkOtherAfter, artOtherAfter = urns(otherIlk, otherUsrU);

    uint256 gemOtherAfter = gem(otherIlk, otherUsrV);
    uint256 sinOtherAfter = sin(otherUsrW);

    assert(to_mathint(inkAfter) == to_mathint(inkBefore) + to_mathint(dink), "grab did not set u ink as expected");
    assert(to_mathint(artAfter) == to_mathint(artBefore) + to_mathint(dart), "grab did not set u art as expected");
    assert(to_mathint(ArtAfter) == to_mathint(ArtBefore) + to_mathint(dart), "grab did not set Art as expected");
    assert(to_mathint(gemAfter) == to_mathint(gemBefore) - to_mathint(dink), "grab did not set v gem as expected");
    assert(to_mathint(sinAfter) == to_mathint(sinBefore) - to_mathint(rateBefore) * to_mathint(dart), "grab did not set w sin as expected");
    assert(to_mathint(viceAfter) == to_mathint(viceBefore) - to_mathint(rateBefore) * to_mathint(dart), "grab did not set vice as expected");
    assert(inkOtherAfter == inkOtherBefore, "grab did not keep other ink as expected");
    assert(artOtherAfter == artOtherBefore, "grab did not keep other art as expected");
    assert(rateAfter == rateBefore, "grab did not keep rate as expected");
    assert(spotAfter == spotBefore, "grab did not keep spot as expected");
    assert(lineAfter == lineBefore, "grab did not keep line as expected");
    assert(dustAfter == dustBefore, "grab did not keep dust as expected");
    assert(gemOtherAfter == gemOtherBefore, "grab did not keep other gem as expected");
    assert(sinOtherAfter == sinOtherBefore, "grab did not keep other sin as expected");
}

// Verify revert rules on grab
rule grab_revert(bytes32 i, address u, address v, address w, int256 dink, int256 dart) {
    env e;

    uint256 ward = wards(e.msg.sender);

    uint256 Art; uint256 rate; uint256 spot; uint256 line; uint256 dust;
    Art, rate, spot, line, dust = ilks(i);

    uint256 ink; uint256 art;
    ink, art = urns(i, u);

    uint256 gem = gem(i, v);
    uint256 sin = sin(w);
    uint256 vice = vice();

    grab@withrevert(e, i, u, v, w, dink, dart);

    bool revert1  = e.msg.value > 0;
    bool revert2  = ward != 1;
    bool revert3  = to_mathint(ink) + to_mathint(dink) < 0 || to_mathint(ink) + to_mathint(dink) > max_uint256;
    bool revert4  = to_mathint(art) + to_mathint(dart) < 0 || to_mathint(art) + to_mathint(dart) > max_uint256;
    bool revert5  = to_mathint(Art) + to_mathint(dart) < 0 || to_mathint(Art) + to_mathint(dart) > max_uint256;
    bool revert6  = to_mathint(rate) > max_int256();
    bool revert7  = to_mathint(rate) * to_mathint(dart) < min_int256() || to_mathint(rate) * to_mathint(dart) > max_int256();
    bool revert8  = to_mathint(gem) - to_mathint(dink) < 0 || to_mathint(gem) - to_mathint(dink) > max_uint256;
    bool revert9  = to_mathint(sin) - to_mathint(rate) * to_mathint(dart) < 0 || to_mathint(sin) - to_mathint(rate) * to_mathint(dart) > max_uint256;
    bool revert10 = to_mathint(vice) - to_mathint(rate) * to_mathint(dart) < 0 || to_mathint(vice) - to_mathint(rate) * to_mathint(dart) > max_uint256;

    assert(revert1  => lastReverted, "revert1 failed");
    assert(revert2  => lastReverted, "revert2 failed");
    assert(revert3  => lastReverted, "revert3 failed");
    assert(revert4  => lastReverted, "revert4 failed");
    assert(revert5  => lastReverted, "revert5 failed");
    assert(revert6  => lastReverted, "revert6 failed");
    assert(revert7  => lastReverted, "revert7 failed");
    assert(revert8  => lastReverted, "revert8 failed");
    assert(revert9  => lastReverted, "revert9 failed");
    assert(revert10 => lastReverted, "revert10 failed");

    assert(lastReverted => revert1  || revert2  || revert3  ||
                           revert4  || revert5  || revert6  ||
                           revert7  || revert8  || revert9  ||
                           revert10, "Revert rules are not covering all the cases");
}

// Verify that variables behave correctly on heal
rule heal(uint256 rad) {
    env e;

    address otherUsr;
    require(otherUsr != e.msg.sender);
    uint256 daiSenderBefore = dai(e.msg.sender);
    uint256 sinSenderBefore = sin(e.msg.sender);
    uint256 viceBefore = vice();
    uint256 debtBefore = debt();
    uint256 daiOtherBefore = dai(otherUsr);
    uint256 sinOtherBefore = sin(otherUsr);

    heal(e, rad);

    uint256 daiSenderAfter = dai(e.msg.sender);
    uint256 sinSenderAfter = sin(e.msg.sender);
    uint256 viceAfter = vice();
    uint256 debtAfter = debt();
    uint256 daiOtherAfter = dai(otherUsr);
    uint256 sinOtherAfter = sin(otherUsr);

    assert(daiSenderAfter == daiSenderBefore - rad, "heal did not set sender dai as expected");
    assert(sinSenderAfter == sinSenderBefore - rad, "heal did not set sender sin as expected");
    assert(viceAfter == viceBefore - rad, "heal did not set vice as expected");
    assert(debtAfter == debtBefore - rad, "heal did not set debt as expected");
    assert(daiOtherAfter == daiOtherBefore, "heal did not keep other dai as expected");
    assert(sinOtherAfter == sinOtherBefore, "heal did not keep other sin as expected");
}

// Verify revert rules on heal
rule heal_revert(uint256 rad) {
    env e;

    uint256 dai = dai(e.msg.sender);
    uint256 sin = sin(e.msg.sender);
    uint256 vice = vice();
    uint256 debt = debt();

    heal@withrevert(e, rad);

    bool revert1 = e.msg.value > 0;
    bool revert2 = dai < rad;
    bool revert3 = sin < rad;
    bool revert4 = vice < rad;
    bool revert5 = debt < rad;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");
    assert(revert4 => lastReverted, "revert4 failed");
    assert(revert5 => lastReverted, "revert5 failed");

    assert(lastReverted => revert1 || revert2 || revert3 ||
                           revert4 || revert5, "Revert rules are not covering all the cases");
}

// Verify that variables behave correctly on suck
rule suck(address u, address v, uint256 rad) {
    env e;

    address otherUsrU;
    address otherUsrV;
    require(otherUsrU != u && otherUsrV != v);
    uint256 sinUBefore = sin(u);
    uint256 daiVBefore = dai(v);
    uint256 viceBefore = vice();
    uint256 debtBefore = debt();
    uint256 sinOtherBefore = sin(otherUsrU);
    uint256 daiOtherBefore = dai(otherUsrV);

    suck(e, u, v, rad);

    uint256 sinUAfter = sin(u);
    uint256 daiVAfter = dai(v);
    uint256 viceAfter = vice();
    uint256 debtAfter = debt();
    uint256 sinOtherAfter = sin(otherUsrU);
    uint256 daiOtherAfter = dai(otherUsrV);

    assert(sinUAfter == sinUBefore + rad, "suck did not set u sin as expected");
    assert(daiVAfter == daiVBefore + rad, "suck did not set v dai as expected");
    assert(viceAfter == viceBefore + rad, "suck did not set vice as expected");
    assert(debtAfter == debtBefore + rad, "suck did not set debt as expected");
    assert(sinOtherAfter == sinOtherBefore, "suck did not keep other sin as expected");
    assert(daiOtherAfter == daiOtherBefore, "suck did not keep other dai as expected");
}

// Verify revert rules on suck
rule suck_revert(address u, address v, uint256 rad) {
    env e;

    uint256 ward = wards(e.msg.sender);
    uint256 sin = sin(u);
    uint256 dai = dai(v);
    uint256 vice = vice();
    uint256 debt = debt();

    suck@withrevert(e, u, v, rad);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;
    bool revert3 = sin + rad > max_uint256;
    bool revert4 = dai + rad > max_uint256;
    bool revert5 = vice + rad > max_uint256;
    bool revert6 = debt + rad > max_uint256;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");
    assert(revert4 => lastReverted, "revert4 failed");
    assert(revert5 => lastReverted, "revert5 failed");
    assert(revert6 => lastReverted, "revert6 failed");


    assert(lastReverted => revert1 || revert2 || revert3 ||
                           revert4 || revert5 || revert6, "Revert rules are not covering all the cases");
}

// Verify that variables behave correctly on fold
rule fold(bytes32 i, address u, int256 rate_) {
    env e;

    address otherUsr;
    require(otherUsr != u);

    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(i);

    uint256 daiBefore = dai(u);
    uint256 debtBefore = debt();
    uint256 daiOtherBefore = dai(otherUsr);

    fold(e, i, u, rate_);

    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(i);

    uint256 daiAfter = dai(u);
    uint256 debtAfter = debt();
    uint256 daiOtherAfter = dai(otherUsr);

    assert(to_mathint(rateAfter) == to_mathint(rateBefore) + to_mathint(rate_), "fold did not set rate as expected");
    assert(to_mathint(daiAfter) == to_mathint(daiBefore) + to_mathint(ArtBefore) * to_mathint(rate_), "fold did not set u dai as expected");
    assert(to_mathint(debtAfter) == to_mathint(debtBefore) + to_mathint(ArtBefore) * to_mathint(rate_), "fold did not set debt as expected");
    assert(ArtAfter == ArtBefore, "fold did not keep Art as expected");
    assert(spotAfter == spotBefore, "fold did not keep spot as expected");
    assert(lineAfter == lineBefore, "fold did not keep line as expected");
    assert(dustAfter == dustBefore, "fold did not keep dust as expected");
    assert(daiOtherAfter == daiOtherBefore, "fold did not keep other dai as expected");
}

// Verify revert rules on fold
rule fold_revert(bytes32 i, address u, int256 rate_) {
    env e;

    uint256 ward = wards(e.msg.sender);
    uint256 live = live();

    uint256 Art; uint256 rate; uint256 spot; uint256 line; uint256 dust;
    Art, rate, spot, line, dust = ilks(i);

    uint256 dai = dai(u);
    uint256 debt = debt();

    fold@withrevert(e, i, u, rate_);

    mathint rad = to_mathint(Art) * to_mathint(rate_);

    bool revert1 = e.msg.value > 0;
    bool revert2 = ward != 1;
    bool revert3 = live != 1;
    bool revert4 = to_mathint(rate) + to_mathint(rate_) < 0 || to_mathint(rate) + to_mathint(rate_) > max_uint256;
    bool revert5 = Art > max_int256();
    bool revert6 = to_mathint(Art) * to_mathint(rate_) < min_int256() || to_mathint(Art) * to_mathint(rate_) > max_int256();
    bool revert7 = to_mathint(dai) + rad < 0 || to_mathint(dai) + rad > max_uint256;
    bool revert8 = to_mathint(debt) + rad < 0 || to_mathint(debt) + rad > max_uint256;

    assert(revert1 => lastReverted, "revert1 failed");
    assert(revert2 => lastReverted, "revert2 failed");
    assert(revert3 => lastReverted, "revert3 failed");
    assert(revert4 => lastReverted, "revert4 failed");
    assert(revert5 => lastReverted, "revert5 failed");
    assert(revert6 => lastReverted, "revert6 failed");
    assert(revert7 => lastReverted, "revert7 failed");
    assert(revert8 => lastReverted, "revert8 failed");

    assert(lastReverted => revert1 || revert2 || revert3 ||
                           revert4 || revert5 || revert6 ||
                           revert7 || revert8, "Revert rules are not covering all the cases");
}
