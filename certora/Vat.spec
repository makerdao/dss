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
rule fallback_revert(method f) filtered { f -> f.isFallback } {
    env e;

    calldataarg arg;
    f@withrevert(e, arg);

    assert(lastReverted, "Fallback did not revert");
}

// Verify correct storage changes for non reverting rely
rule rely(address usr) {
    env e;

    address other;
    require(other != usr);
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsOtherBefore = wards(other);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(anyIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiBefore = dai(anyUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    rely(e, usr);

    uint256 wardsAfter = wards(usr);
    uint256 wardsOtherAfter = wards(other);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(anyIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiAfter = dai(anyUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == 1, "rely did not set wards");
    assert(wardsOtherAfter == wardsOtherBefore, "rely did not keep unchanged the rest of wards[x]");
    assert(canAfter == canBefore, "rely did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "rely did not keep unchanged every ilks[x].Art");
    assert(rateAfter == rateBefore, "rely did not keep unchanged every ilks[x].rate");
    assert(spotAfter == spotBefore, "rely did not keep unchanged every ilks[x].spot");
    assert(lineAfter == lineBefore, "rely did not keep unchanged every ilks[x].line");
    assert(dustAfter == dustBefore, "rely did not keep unchanged every ilks[x].dust");
    assert(inkAfter == inkBefore, "rely did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "rely did not keep unchanged every urns[x].art");
    assert(gemAfter == gemBefore, "rely did not keep unchanged every gem[x][y]");
    assert(daiAfter == daiBefore, "rely did not keep unchanged every dai[x]");
    assert(sinAfter == sinBefore, "rely did not keep unchanged every sin[x]");
    assert(debtAfter == debtBefore, "rely did not keep unchanged debt");
    assert(viceAfter == viceBefore, "rely did not keep unchanged vice");
    assert(LineAfter == LineBefore, "rely did not keep unchanged Line");
    assert(liveAfter == liveBefore, "rely did not keep unchanged live");
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

// Verify correct storage changes for non reverting deny
rule deny(address usr) {
    env e;

    address other;
    require(other != usr);
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsOtherBefore = wards(other);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(anyIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiBefore = dai(anyUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    deny(e, usr);

    uint256 wardsAfter = wards(usr);
    uint256 wardsOtherAfter = wards(other);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(anyIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiAfter = dai(anyUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == 0, "deny did not set wards");
    assert(wardsOtherAfter == wardsOtherBefore, "deny did not keep unchanged the rest of wards[x]");
    assert(canAfter == canBefore, "deny did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "deny did not keep unchanged every ilks[x].Art");
    assert(rateAfter == rateBefore, "deny did not keep unchanged every ilks[x].rate");
    assert(spotAfter == spotBefore, "deny did not keep unchanged every ilks[x].spot");
    assert(lineAfter == lineBefore, "deny did not keep unchanged every ilks[x].line");
    assert(dustAfter == dustBefore, "deny did not keep unchanged every ilks[x].dust");
    assert(inkAfter == inkBefore, "deny did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "deny did not keep unchanged every urns[x].art");
    assert(gemAfter == gemBefore, "deny did not keep unchanged every gem[x][y]");
    assert(daiAfter == daiBefore, "deny did not keep unchanged every dai[x]");
    assert(sinAfter == sinBefore, "deny did not keep unchanged every sin[x]");
    assert(debtAfter == debtBefore, "deny did not keep unchanged debt");
    assert(viceAfter == viceBefore, "deny did not keep unchanged vice");
    assert(LineAfter == LineBefore, "deny did not keep unchanged Line");
    assert(liveAfter == liveBefore, "deny did not keep unchanged live");
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

// Verify correct storage changes for non reverting init
rule init(bytes32 ilk) {
    env e;

    bytes32 otherIlk;
    require(otherIlk != ilk);
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(ilk);
    uint256 ArtOtherBefore; uint256 rateOtherBefore; uint256 spotOtherBefore; uint256 lineOtherBefore; uint256 dustOtherBefore;
    ArtOtherBefore, rateOtherBefore, spotOtherBefore, lineOtherBefore, dustOtherBefore = ilks(otherIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiBefore = dai(anyUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    init(e, ilk);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(ilk);
    uint256 ArtOtherAfter; uint256 rateOtherAfter; uint256 spotOtherAfter; uint256 lineOtherAfter; uint256 dustOtherAfter;
    ArtOtherAfter, rateOtherAfter, spotOtherAfter, lineOtherAfter, dustOtherAfter = ilks(otherIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiAfter = dai(anyUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "init did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "init did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "init did not keep unchanged ilks[ilk].Art");
    assert(rateAfter == RAY(), "init did not set ilks[ilk].rate");
    assert(spotAfter == spotBefore, "init did not keep unchanged ilks[ilk].spot");
    assert(lineAfter == lineBefore, "init did not keep unchanged ilks[ilk].line");
    assert(dustAfter == dustBefore, "init did not keep unchanged ilks[ilk].dust");
    assert(ArtOtherAfter == ArtOtherBefore, "init did not keep unchanged the rest of ilks[x].Art");
    assert(rateOtherAfter == rateOtherBefore, "init did not keep unchanged the rest of ilks[x].rate");
    assert(spotOtherAfter == spotOtherBefore, "init did not keep unchanged the rest of ilks[x].spot");
    assert(lineOtherAfter == lineOtherBefore, "init did not keep unchanged the rest of ilks[x].line");
    assert(dustOtherAfter == dustOtherBefore, "init did not keep unchanged the rest of ilks[x].dust");
    assert(inkAfter == inkBefore, "init did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "init did not keep unchanged every urns[x].art");
    assert(gemAfter == gemBefore, "init did not keep unchanged every gem[x][y]");
    assert(daiAfter == daiBefore, "init did not keep unchanged every dai[x]");
    assert(sinAfter == sinBefore, "init did not keep unchanged every sin[x]");
    assert(debtAfter == debtBefore, "init did not keep unchanged debt");
    assert(viceAfter == viceBefore, "init did not keep unchanged vice");
    assert(LineAfter == LineBefore, "init did not keep unchanged Line");
    assert(liveAfter == liveBefore, "init did not keep unchanged live");
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

// Verify correct storage changes for non reverting file
rule file(bytes32 what, uint256 data) {
    env e;

    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(anyIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiBefore = dai(anyUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 liveBefore = live();

    file(e, what, data);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(anyIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiAfter = dai(anyUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "file did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "file did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "file did not keep unchanged every ilks[x].Art");
    assert(rateAfter == rateBefore, "file did not keep unchanged every ilks[x].rate");
    assert(spotAfter == spotBefore, "file did not keep unchanged every ilks[x].spot");
    assert(lineAfter == lineBefore, "file did not keep unchanged every ilks[x].line");
    assert(dustAfter == dustBefore, "file did not keep unchanged every ilks[x].dust");
    assert(inkAfter == inkBefore, "file did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "file did not keep unchanged every urns[x].art");
    assert(gemAfter == gemBefore, "file did not keep unchanged every gem[x][y]");
    assert(daiAfter == daiBefore, "file did not keep unchanged every dai[x]");
    assert(sinAfter == sinBefore, "file did not keep unchanged every sin[x]");
    assert(debtAfter == debtBefore, "file did not keep unchanged debt");
    assert(viceAfter == viceBefore, "file did not keep unchanged vice");
    assert(LineAfter == data, "file did not set Line");
    assert(liveAfter == liveBefore, "file did not keep unchanged live");
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

// Verify correct storage changes for non reverting file
rule file_ilk(bytes32 ilk, bytes32 what, uint256 data) {
    env e;

    bytes32 otherIlk;
    require(otherIlk != ilk);
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(ilk);
    uint256 ArtOtherBefore; uint256 rateOtherBefore; uint256 spotOtherBefore; uint256 lineOtherBefore; uint256 dustOtherBefore;
    ArtOtherBefore, rateOtherBefore, spotOtherBefore, lineOtherBefore, dustOtherBefore = ilks(otherIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiBefore = dai(anyUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    file(e, ilk, what, data);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(ilk);
    uint256 ArtOtherAfter; uint256 rateOtherAfter; uint256 spotOtherAfter; uint256 lineOtherAfter; uint256 dustOtherAfter;
    ArtOtherAfter, rateOtherAfter, spotOtherAfter, lineOtherAfter, dustOtherAfter = ilks(otherIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiAfter = dai(anyUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "file did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "file did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "file did not keep unchanged ilks[ilk].Art");
    assert(rateAfter == rateBefore, "file did not keep unchanged ilks[ilk].rate");
    assert(what == 0x73706f7400000000000000000000000000000000000000000000000000000000 => spotAfter == data, "file did not set ilks[ilk].spot");
    assert(what != 0x73706f7400000000000000000000000000000000000000000000000000000000 => spotAfter == spotBefore, "file did not keep unchanged ilks[ilk].spot");
    assert(what == 0x6c696e6500000000000000000000000000000000000000000000000000000000 => lineAfter == data, "file did not set ilks[ilk].line");
    assert(what != 0x6c696e6500000000000000000000000000000000000000000000000000000000 => lineAfter == lineBefore, "file did not keep unchanged ilks[ilk].line");
    assert(what == 0x6475737400000000000000000000000000000000000000000000000000000000 => dustAfter == data, "file did not set ilks[ilk].dust");
    assert(what != 0x6475737400000000000000000000000000000000000000000000000000000000 => dustAfter == dustBefore, "file did not keep unchanged ilks[ilk].dust");
    assert(ArtOtherAfter == ArtOtherBefore, "file did not keep unchanged the rest of ilks[x].Art");
    assert(rateOtherAfter == rateOtherBefore, "file did not keep unchanged the rest of ilks[x].rate");
    assert(spotOtherAfter == spotOtherBefore, "file did not keep unchanged the rest of ilks[x].spot");
    assert(lineOtherAfter == lineOtherBefore, "file did not keep unchanged the rest of ilks[x].line");
    assert(dustOtherAfter == dustOtherBefore, "file did not keep unchanged the rest of ilks[x].dust");
    assert(inkAfter == inkBefore, "file did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "file did not keep unchanged every urns[x].art");
    assert(gemAfter == gemBefore, "file did not keep unchanged every gem[x][y]");
    assert(daiAfter == daiBefore, "file did not keep unchanged every dai[x]");
    assert(sinAfter == sinBefore, "file did not keep unchanged every sin[x]");
    assert(debtAfter == debtBefore, "file did not keep unchanged debt");
    assert(viceAfter == viceBefore, "file did not keep unchanged vice");
    assert(LineAfter == LineBefore, "file did not keep unchanged Line");
    assert(liveAfter == liveBefore, "file did not keep unchanged live");
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

// Verify correct storage changes for non reverting cage
rule cage() {
    env e;

    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(anyIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiBefore = dai(anyUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();

    cage(e);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(anyIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiAfter = dai(anyUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "cage did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "cage did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "cage did not keep unchanged every ilks[x].Art");
    assert(rateAfter == rateBefore, "cage did not keep unchanged every ilks[x].rate");
    assert(spotAfter == spotBefore, "cage did not keep unchanged every ilks[x].spot");
    assert(lineAfter == lineBefore, "cage did not keep unchanged every ilks[x].line");
    assert(dustAfter == dustBefore, "cage did not keep unchanged every ilks[x].dust");
    assert(inkAfter == inkBefore, "cage did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "cage did not keep unchanged every urns[x].art");
    assert(gemAfter == gemBefore, "cage did not keep unchanged every gem[x][y]");
    assert(daiAfter == daiBefore, "cage did not keep unchanged every dai[x]");
    assert(sinAfter == sinBefore, "cage did not keep unchanged every sin[x]");
    assert(debtAfter == debtBefore, "cage did not keep unchanged debt");
    assert(viceAfter == viceBefore, "cage did not keep unchanged vice");
    assert(LineAfter == LineBefore, "cage did not keep unchanged Line");
    assert(liveAfter == 0, "cage did not set live");
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

// Verify correct storage changes for non reverting hope
rule hope(address usr) {
    env e;

    address otherFrom; address otherTo;
    require(otherFrom != e.msg.sender || otherTo != usr);
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canOtherBefore = can(otherFrom, otherTo);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(anyIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiBefore = dai(anyUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    hope(e, usr);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(e.msg.sender, usr);
    uint256 canOtherAfter = can(otherFrom, otherTo);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(anyIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiAfter = dai(anyUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "hope did not keep unchanged every wards[x]");
    assert(canAfter == 1, "hope did not set can[usr]");
    assert(canOtherAfter == canOtherBefore, "hope did not keep unchanged the rest of can[x]");
    assert(ArtAfter == ArtBefore, "hope did not keep unchanged every ilks[x].Art");
    assert(rateAfter == rateBefore, "hope did not keep unchanged every ilks[x].rate");
    assert(spotAfter == spotBefore, "hope did not keep unchanged every ilks[x].spot");
    assert(lineAfter == lineBefore, "hope did not keep unchanged every ilks[x].line");
    assert(dustAfter == dustBefore, "hope did not keep unchanged every ilks[x].dust");
    assert(inkAfter == inkBefore, "hope did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "hope did not keep unchanged every urns[x].art");
    assert(gemAfter == gemBefore, "hope did not keep unchanged every gem[x][y]");
    assert(daiAfter == daiBefore, "hope did not keep unchanged every dai[x]");
    assert(sinAfter == sinBefore, "hope did not keep unchanged every sin[x]");
    assert(debtAfter == debtBefore, "hope did not keep unchanged debt");
    assert(viceAfter == viceBefore, "hope did not keep unchanged vice");
    assert(LineAfter == LineBefore, "hope did not keep unchanged Line");
    assert(liveAfter == liveBefore, "hope did not keep unchanged live");
}

// Verify revert rules on hope
rule hope_revert(address usr) {
    env e;

    hope@withrevert(e, usr);

    bool revert1 = e.msg.value > 0;

    assert(revert1 => lastReverted, "revert1 failed");

    assert(lastReverted => revert1, "Revert rules are not covering all the cases");
}

// Verify correct storage changes for non reverting nope
rule nope(address usr) {
    env e;

    address otherFrom; address otherTo;
    require(otherFrom != e.msg.sender || otherTo != usr);
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canOtherBefore = can(otherFrom, otherTo);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(anyIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiBefore = dai(anyUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    nope(e, usr);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(e.msg.sender, usr);
    uint256 canOtherAfter = can(otherFrom, otherTo);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(anyIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiAfter = dai(anyUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "nope did not keep unchanged every wards[x]");
    assert(canAfter == 0, "nope did not set can[usr]");
    assert(canOtherAfter == canOtherBefore, "nope did not keep unchanged the rest of can[x]");
    assert(ArtAfter == ArtBefore, "nope did not keep unchanged every ilks[x].Art");
    assert(rateAfter == rateBefore, "nope did not keep unchanged every ilks[x].rate");
    assert(spotAfter == spotBefore, "nope did not keep unchanged every ilks[x].spot");
    assert(lineAfter == lineBefore, "nope did not keep unchanged every ilks[x].line");
    assert(dustAfter == dustBefore, "nope did not keep unchanged every ilks[x].dust");
    assert(inkAfter == inkBefore, "nope did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "nope did not keep unchanged every urns[x].art");
    assert(gemAfter == gemBefore, "nope did not keep unchanged every gem[x][y]");
    assert(daiAfter == daiBefore, "nope did not keep unchanged every dai[x]");
    assert(sinAfter == sinBefore, "nope did not keep unchanged every sin[x]");
    assert(debtAfter == debtBefore, "nope did not keep unchanged debt");
    assert(viceAfter == viceBefore, "nope did not keep unchanged vice");
    assert(LineAfter == LineBefore, "nope did not keep unchanged Line");
    assert(liveAfter == liveBefore, "nope did not keep unchanged live");
}

// Verify revert rules on nope
rule nope_revert(address usr) {
    env e;

    nope@withrevert(e, usr);

    bool revert1 = e.msg.value > 0;

    assert(revert1 => lastReverted, "revert1 failed");

    assert(lastReverted => revert1, "Revert rules are not covering all the cases");
}

// Verify correct storage changes for non reverting slip
rule slip(bytes32 ilk, address usr, int256 wad) {
    env e;

    bytes32 otherIlk; address otherUsr;
    require(otherIlk != ilk || otherUsr != usr);
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(anyIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(ilk, usr);
    uint256 gemOtherBefore = gem(otherIlk, otherUsr);
    uint256 daiBefore = dai(anyUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    slip(e, ilk, usr, wad);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(anyIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(ilk, usr);
    uint256 gemOtherAfter = gem(otherIlk, otherUsr);
    uint256 daiAfter = dai(anyUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "slip did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "slip did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "slip did not keep unchanged every ilks[x].Art");
    assert(rateAfter == rateBefore, "slip did not keep unchanged every ilks[x].rate");
    assert(spotAfter == spotBefore, "slip did not keep unchanged every ilks[x].spot");
    assert(lineAfter == lineBefore, "slip did not keep unchanged every ilks[x].line");
    assert(dustAfter == dustBefore, "slip did not keep unchanged every ilks[x].dust");
    assert(inkAfter == inkBefore, "slip did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "slip did not keep unchanged every urns[x].art");
    assert(to_mathint(gemAfter) == to_mathint(gemBefore) + to_mathint(wad), "slip did not set gem[ilk][usr]");
    assert(gemOtherAfter == gemOtherBefore, "slip did not keep unchanged the rest of gem[x][y]");
    assert(daiAfter == daiBefore, "slip did not keep unchanged every dai[x]");
    assert(sinAfter == sinBefore, "slip did not keep unchanged every sin[x]");
    assert(debtAfter == debtBefore, "slip did not keep unchanged debt");
    assert(viceAfter == viceBefore, "slip did not keep unchanged vice");
    assert(LineAfter == LineBefore, "slip did not keep unchanged Line");
    assert(liveAfter == liveBefore, "slip did not keep unchanged live");
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

// Verify correct storage changes for non reverting flux
rule flux(bytes32 ilk, address src, address dst, uint256 wad) {
    env e;

    bytes32 otherIlk; address otherUsr;
    require(otherIlk != ilk || (otherUsr != src && otherUsr != dst));
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(anyIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemSrcBefore = gem(ilk, src);
    uint256 gemDstBefore = gem(ilk, dst);
    uint256 gemOtherBefore = gem(otherIlk, otherUsr);
    uint256 daiBefore = dai(anyUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    flux(e, ilk, src, dst, wad);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(anyIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemSrcAfter = gem(ilk, src);
    uint256 gemDstAfter = gem(ilk, dst);
    uint256 gemOtherAfter = gem(otherIlk, otherUsr);
    uint256 daiAfter = dai(anyUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "flux did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "flux did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "flux did not keep unchanged every ilks[x].Art");
    assert(rateAfter == rateBefore, "flux did not keep unchanged every ilks[x].rate");
    assert(spotAfter == spotBefore, "flux did not keep unchanged every ilks[x].spot");
    assert(lineAfter == lineBefore, "flux did not keep unchanged every ilks[x].line");
    assert(dustAfter == dustBefore, "flux did not keep unchanged every ilks[x].dust");
    assert(inkAfter == inkBefore, "flux did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "flux did not keep unchanged every urns[x].art");
    assert(src != dst => gemSrcAfter == gemSrcBefore - wad, "flux did not set gem[ilk][src]");
    assert(src != dst => gemDstAfter == gemDstBefore + wad, "flux did not set gem[ilk][dst]");
    assert(src == dst => gemSrcAfter == gemDstBefore, "flux did not keep unchanged gem[ilk][src/dst]");
    assert(gemOtherAfter == gemOtherBefore, "flux did not keep unchanged the rest of gem[x][y]");
    assert(daiAfter == daiBefore, "flux did not keep unchanged every dai[x]");
    assert(sinAfter == sinBefore, "flux did not keep unchanged every sin[x]");
    assert(debtAfter == debtBefore, "flux did not keep unchanged debt");
    assert(viceAfter == viceBefore, "flux did not keep unchanged vice");
    assert(LineAfter == LineBefore, "flux did not keep unchanged Line");
    assert(liveAfter == liveBefore, "flux did not keep unchanged live");
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

// Verify correct storage changes for non reverting move
rule move(address src, address dst, uint256 rad) {
    env e;

    address otherUsr;
    require(otherUsr != src && otherUsr != dst);
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(anyIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiSrcBefore = dai(src);
    uint256 daiDstBefore = dai(dst);
    uint256 daiOtherBefore = dai(otherUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    move(e, src, dst, rad);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(anyIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiSrcAfter = dai(src);
    uint256 daiDstAfter = dai(dst);
    uint256 daiOtherAfter = dai(otherUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "move did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "move did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "move did not keep unchanged every ilks[x].Art");
    assert(rateAfter == rateBefore, "move did not keep unchanged every ilks[x].rate");
    assert(spotAfter == spotBefore, "move did not keep unchanged every ilks[x].spot");
    assert(lineAfter == lineBefore, "move did not keep unchanged every ilks[x].line");
    assert(dustAfter == dustBefore, "move did not keep unchanged every ilks[x].dust");
    assert(inkAfter == inkBefore, "move did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "move did not keep unchanged every urns[x].art");
    assert(gemAfter == gemBefore, "move did not keep unchanged every gem[x][y]");
    assert(src != dst => daiSrcAfter == daiSrcBefore - rad, "move did not set dai[src]");
    assert(src != dst => daiDstAfter == daiDstBefore + rad, "move did not set dai[dst]");
    assert(src == dst => daiSrcAfter == daiDstBefore, "move did not keep unchanged dai[src/dst]");
    assert(daiOtherAfter == daiOtherBefore, "move did not keep unchanged the rest of dai[x]");
    assert(sinAfter == sinBefore, "move did not keep unchanged every sin[x]");
    assert(debtAfter == debtBefore, "move did not keep unchanged debt");
    assert(viceAfter == viceBefore, "move did not keep unchanged vice");
    assert(LineAfter == LineBefore, "move did not keep unchanged Line");
    assert(liveAfter == liveBefore, "move did not keep unchanged live");
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

// Verify correct storage changes for non reverting frob
rule frob(bytes32 i, address u, address v, address w, int256 dink, int256 dart) {
    env e;

    bytes32 otherIlk;
    require(otherIlk != i);
    bytes32 otherIlkU; address otherUsrU;
    require(otherIlkU != i || otherUsrU != u);
    bytes32 otherIlkV; address otherUsrV;
    require(otherIlkV != i || otherUsrV != v);
    address otherUsrW;
    require(otherUsrW != w);
    address anyUsr; address anyUsr2;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(i);
    uint256 ArtOtherBefore; uint256 rateOtherBefore; uint256 spotOtherBefore; uint256 lineOtherBefore; uint256 dustOtherBefore;
    ArtOtherBefore, rateOtherBefore, spotOtherBefore, lineOtherBefore, dustOtherBefore = ilks(otherIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(i, u);
    uint256 inkOtherBefore; uint256 artOtherBefore;
    inkOtherBefore, artOtherBefore = urns(otherIlkU, otherUsrU);
    uint256 gemBefore = gem(i, v);
    uint256 gemOtherBefore = gem(otherIlkV, otherUsrV);
    uint256 daiBefore = dai(w);
    uint256 daiOtherBefore = dai(otherUsrW);
    uint256 debtBefore = debt();
    uint256 sinBefore = sin(anyUsr);
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    frob(e, i, u, v, w, dink, dart);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(i);
    uint256 ArtOtherAfter; uint256 rateOtherAfter; uint256 spotOtherAfter; uint256 lineOtherAfter; uint256 dustOtherAfter;
    ArtOtherAfter, rateOtherAfter, spotOtherAfter, lineOtherAfter, dustOtherAfter = ilks(otherIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(i, u);
    uint256 inkOtherAfter; uint256 artOtherAfter;
    inkOtherAfter, artOtherAfter = urns(otherIlkU, otherUsrU);
    uint256 gemAfter = gem(i, v);
    uint256 gemOtherAfter = gem(otherIlkV, otherUsrV);
    uint256 daiAfter = dai(w);
    uint256 daiOtherAfter = dai(otherUsrW);
    uint256 debtAfter = debt();
    uint256 sinAfter = sin(anyUsr);
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "frob did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "frob did not keep unchanged every can[x][y]");
    assert(to_mathint(ArtAfter) == to_mathint(ArtBefore) + to_mathint(dart), "frob did not set ilks[i].Art");
    assert(rateAfter == rateBefore, "frob did not keep unchanged ilks[i].rate");
    assert(spotAfter == spotBefore, "frob did not keep unchanged ilks[i].spot");
    assert(lineAfter == lineBefore, "frob did not keep unchanged ilks[i].line");
    assert(dustAfter == dustBefore, "frob did not keep unchanged ilks[i].dust");
    assert(ArtOtherAfter == ArtOtherBefore, "frob did not keep unchanged rest of ilks[x].Art");
    assert(rateOtherAfter == rateOtherBefore, "frob did not keep unchanged rest of ilks[x].rate");
    assert(spotOtherAfter == spotOtherBefore, "frob did not keep unchanged rest of ilks[x].spot");
    assert(lineOtherAfter == lineOtherBefore, "frob did not keep unchanged rest of ilks[x].line");
    assert(dustOtherAfter == dustOtherBefore, "frob did not keep unchanged rest of ilks[x].dust");
    assert(to_mathint(inkAfter) == to_mathint(inkBefore) + to_mathint(dink), "frob did not set urns[u].ink");
    assert(to_mathint(artAfter) == to_mathint(artBefore) + to_mathint(dart), "frob did not set urns[u].art");
    assert(inkOtherAfter == inkOtherBefore, "frob did not keep unchanged rest of urns[x].ink");
    assert(artOtherAfter == artOtherBefore, "frob did not keep unchanged rest of urns[x].art");
    assert(to_mathint(gemAfter) == to_mathint(gemBefore) - to_mathint(dink), "frob did not set gem[i][v]");
    assert(gemOtherAfter == gemOtherBefore, "frob did not keep unchanged rest of gem[x][y]");
    assert(to_mathint(daiAfter) == to_mathint(daiBefore) + to_mathint(rateBefore) * to_mathint(dart), "frob did not set dai[w]");
    assert(daiOtherAfter == daiOtherBefore, "frob did not keep unchanged rest of dai[x]");
    assert(sinAfter == sinBefore, "frob did not keep unchanged every sin[x]");
    assert(to_mathint(debtAfter) == to_mathint(debtBefore) + to_mathint(rateBefore) * to_mathint(dart), "frob did not set debt");
    assert(viceAfter == viceBefore, "frob did not keep unchanged vice");
    assert(LineAfter == LineBefore, "frob did not keep unchanged Line");
    assert(liveAfter == liveBefore, "frob did not keep unchanged live");
}

// Verify revert rules on frob
rule frob_revert(bytes32 i, address u, address v, address w, int256 dink, int256 dart) {
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

// Verify correct storage changes for non reverting fork
rule fork(bytes32 ilk, address src, address dst, int256 dink, int256 dart) {
    env e;

    bytes32 otherIlk; address otherUsr;
    require(otherIlk != ilk || otherUsr != src && otherUsr != dst);
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(anyIlk);
    uint256 inkSrcBefore; uint256 artSrcBefore;
    inkSrcBefore, artSrcBefore = urns(ilk, src);
    uint256 inkDstBefore; uint256 artDstBefore;
    inkDstBefore, artDstBefore = urns(ilk, dst);
    uint256 inkOtherBefore; uint256 artOtherBefore;
    inkOtherBefore, artOtherBefore = urns(otherIlk, otherUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiBefore = dai(anyUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    fork(e, ilk, src, dst, dink, dart);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(anyIlk);
    uint256 inkSrcAfter; uint256 artSrcAfter;
    inkSrcAfter, artSrcAfter = urns(ilk, src);
    uint256 inkDstAfter; uint256 artDstAfter;
    inkDstAfter, artDstAfter = urns(ilk, dst);
    uint256 inkOtherAfter; uint256 artOtherAfter;
    inkOtherAfter, artOtherAfter = urns(otherIlk, otherUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiAfter = dai(anyUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "fork did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "fork did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "fork did not keep unchanged every ilks[x].Art");
    assert(rateAfter == rateBefore, "fork did not keep unchanged every ilks[x].rate");
    assert(spotAfter == spotBefore, "fork did not keep unchanged every ilks[x].spot");
    assert(lineAfter == lineBefore, "fork did not keep unchanged every ilks[x].line");
    assert(dustAfter == dustBefore, "fork did not keep unchanged every ilks[x].dust");
    assert(src != dst => to_mathint(inkSrcAfter) == to_mathint(inkSrcBefore) - to_mathint(dink), "fork did not set urns[src].ink");
    assert(src != dst => to_mathint(artSrcAfter) == to_mathint(artSrcBefore) - to_mathint(dart), "fork did not set urns[src].art");
    assert(src != dst => to_mathint(inkDstAfter) == to_mathint(inkDstBefore) + to_mathint(dink), "fork did not set urns[dst].ink");
    assert(src != dst => to_mathint(artDstAfter) == to_mathint(artDstBefore) + to_mathint(dart), "fork did not set urns[dst].art");
    assert(src == dst => inkSrcAfter == inkSrcBefore, "fork did not keep unchanged urns[src/dst].ink");
    assert(src == dst => artSrcAfter == artSrcBefore, "fork did not keep unchanged urns[src/dst].art");
    assert(inkOtherAfter == inkOtherBefore, "fork did not keep unchanged rest of urns[x].ink");
    assert(artOtherAfter == artOtherBefore, "fork did not keep unchanged rest of urns[x].art");
    assert(gemAfter == gemBefore, "fork did not keep unchanged every gem[x][y]");
    assert(daiAfter == daiBefore, "fork did not keep unchanged every dai[x]");
    assert(sinAfter == sinBefore, "fork did not keep unchanged every sin[x]");
    assert(debtAfter == debtBefore, "fork did not keep unchanged debt");
    assert(viceAfter == viceBefore, "fork did not keep unchanged vice");
    assert(LineAfter == LineBefore, "fork did not keep unchanged Line");
    assert(liveAfter == liveBefore, "fork did not keep unchanged live");
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

// Verify correct storage changes for non reverting grab
rule grab(bytes32 i, address u, address v, address w, int256 dink, int256 dart) {
    env e;

    bytes32 otherIlk;
    require(otherIlk != i);
    bytes32 otherIlkU; address otherUsrU;
    require(otherIlkU != i || otherUsrU != u);
    bytes32 otherIlkV; address otherUsrV;
    require(otherIlkV != i || otherUsrV != v);
    address otherUsrW;
    require(otherUsrW != w);
    address anyUsr; address anyUsr2;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(i);
    uint256 ArtOtherBefore; uint256 rateOtherBefore; uint256 spotOtherBefore; uint256 lineOtherBefore; uint256 dustOtherBefore;
    ArtOtherBefore, rateOtherBefore, spotOtherBefore, lineOtherBefore, dustOtherBefore = ilks(otherIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(i, u);
    uint256 inkOtherBefore; uint256 artOtherBefore;
    inkOtherBefore, artOtherBefore = urns(otherIlkU, otherUsrU);
    uint256 gemBefore = gem(i, v);
    uint256 gemOtherBefore = gem(otherIlkV, otherUsrV);
    uint256 daiBefore = dai(anyUsr);
    uint256 sinBefore = sin(w);
    uint256 sinOtherBefore = sin(otherUsrW);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    grab(e, i, u, v, w, dink, dart);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(i);
    uint256 ArtOtherAfter; uint256 rateOtherAfter; uint256 spotOtherAfter; uint256 lineOtherAfter; uint256 dustOtherAfter;
    ArtOtherAfter, rateOtherAfter, spotOtherAfter, lineOtherAfter, dustOtherAfter = ilks(otherIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(i, u);
    uint256 inkOtherAfter; uint256 artOtherAfter;
    inkOtherAfter, artOtherAfter = urns(otherIlkU, otherUsrU);
    uint256 gemAfter = gem(i, v);
    uint256 gemOtherAfter = gem(otherIlkV, otherUsrV);
    uint256 daiAfter = dai(anyUsr);
    uint256 sinAfter = sin(w);
    uint256 sinOtherAfter = sin(otherUsrW);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "grab did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "grab did not keep unchanged every can[x][y]");
    assert(to_mathint(ArtAfter) == to_mathint(ArtBefore) + to_mathint(dart), "grab did not set ilks[i].Art");
    assert(rateAfter == rateBefore, "grab did not keep unchanged ilks[i].rate");
    assert(spotAfter == spotBefore, "grab did not keep unchanged ilks[i].spot");
    assert(lineAfter == lineBefore, "grab did not keep unchanged ilks[i].line");
    assert(dustAfter == dustBefore, "grab did not keep unchanged ilks[i].dust");
    assert(ArtOtherAfter == ArtOtherBefore, "grab did not keep unchanged the rest of ilks[x].Art");
    assert(rateOtherAfter == rateOtherBefore, "grab did not keep unchanged the rest of ilks[x].rate");
    assert(spotOtherAfter == spotOtherBefore, "grab did not keep unchanged the rest of ilks[x].spot");
    assert(lineOtherAfter == lineOtherBefore, "grab did not keep unchanged the rest of ilks[x].line");
    assert(dustOtherAfter == dustOtherBefore, "grab did not keep unchanged the rest of ilks[x].dust");
    assert(to_mathint(inkAfter) == to_mathint(inkBefore) + to_mathint(dink), "grab did not set urns[u].ink");
    assert(to_mathint(artAfter) == to_mathint(artBefore) + to_mathint(dart), "grab did not set urns[u].art");
    assert(inkOtherAfter == inkOtherBefore, "grab did not keep unchanged the rest of urns[x].ink");
    assert(artOtherAfter == artOtherBefore, "grab did not keep unchanged the rest of urns[x].art");
    assert(to_mathint(gemAfter) == to_mathint(gemBefore) - to_mathint(dink), "grab did not set gem[i][v]");
    assert(gemOtherAfter == gemOtherBefore, "grab did not keep unchanged the rest of gem[x][y]");
    assert(daiAfter == daiBefore, "grab did not keep unchanged every dai[x]");
    assert(to_mathint(sinAfter) == to_mathint(sinBefore) - to_mathint(rateBefore) * to_mathint(dart), "grab did not set sin[w]");
    assert(sinOtherAfter == sinOtherBefore, "grab did not keep unchanged the rest of sin[x]");
    assert(debtAfter == debtBefore, "grab did not keep unchanged debt");
    assert(to_mathint(viceAfter) == to_mathint(viceBefore) - to_mathint(rateBefore) * to_mathint(dart), "grab did not set vice");
    assert(LineAfter == LineBefore, "grab did not keep unchanged Line");
    assert(liveAfter == liveBefore, "grab did not keep unchanged live");
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

// Verify correct storage changes for non reverting heal
rule heal(uint256 rad) {
    env e;

    address otherUsr;
    require(otherUsr != e.msg.sender);
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(anyIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiSenderBefore = dai(e.msg.sender);
    uint256 daiOtherBefore = dai(otherUsr);
    uint256 sinSenderBefore = sin(e.msg.sender);
    uint256 sinOtherBefore = sin(otherUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    heal(e, rad);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(anyIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiSenderAfter = dai(e.msg.sender);
    uint256 daiOtherAfter = dai(otherUsr);
    uint256 sinSenderAfter = sin(e.msg.sender);
    uint256 sinOtherAfter = sin(otherUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "heal did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "heal did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "heal did not keep unchanged every ilks[x].Art");
    assert(rateAfter == rateBefore, "heal did not keep unchanged every ilks[x].rate");
    assert(spotAfter == spotBefore, "heal did not keep unchanged every ilks[x].spot");
    assert(lineAfter == lineBefore, "heal did not keep unchanged every ilks[x].line");
    assert(dustAfter == dustBefore, "heal did not keep unchanged every ilks[x].dust");
    assert(inkAfter == inkBefore, "heal did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "heal did not keep unchanged every urns[x].art");
    assert(gemAfter == gemBefore, "heal did not keep unchanged every gem[x][y]");
    assert(daiSenderAfter == daiSenderBefore - rad, "heal did not set dai[sender]");
    assert(daiOtherAfter == daiOtherBefore, "heal did not keep unchanged the rest of dai[x]");
    assert(sinSenderAfter == sinSenderBefore - rad, "heal did not set sin[sender]");
    assert(sinOtherAfter == sinOtherBefore, "heal did not keep unchanged the rest of sin[x]");
    assert(debtAfter == debtBefore - rad, "heal did not set debt");
    assert(viceAfter == viceBefore - rad, "heal did not set vice");
    assert(LineAfter == LineBefore, "heal did not keep unchanged Line");
    assert(liveAfter == liveBefore, "heal did not keep unchanged live");
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

// Verify correct storage changes for non reverting suck
rule suck(address u, address v, uint256 rad) {
    env e;

    address otherUsrU;
    require(otherUsrU != u);
    address otherUsrV;
    require(otherUsrV != v);
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(anyIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiVBefore = dai(v);
    uint256 daiOtherBefore = dai(otherUsrV);
    uint256 sinUBefore = sin(u);
    uint256 sinOtherBefore = sin(otherUsrU);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    suck(e, u, v, rad);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(anyIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiVAfter = dai(v);
    uint256 daiOtherAfter = dai(otherUsrV);
    uint256 sinUAfter = sin(u);
    uint256 sinOtherAfter = sin(otherUsrU);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "suck did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "suck did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "suck did not keep unchanged every ilks[x].Art");
    assert(rateAfter == rateBefore, "suck did not keep unchanged every ilks[x].rate");
    assert(spotAfter == spotBefore, "suck did not keep unchanged every ilks[x].spot");
    assert(lineAfter == lineBefore, "suck did not keep unchanged every ilks[x].line");
    assert(dustAfter == dustBefore, "suck did not keep unchanged every ilks[x].dust");
    assert(inkAfter == inkBefore, "suck did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "suck did not keep unchanged every urns[x].art");
    assert(gemAfter == gemBefore, "suck did not keep unchanged every gem[x][y]");
    assert(daiVAfter == daiVBefore + rad, "suck did not set dai[v]");
    assert(daiOtherAfter == daiOtherBefore, "suck did not keep unchanged the rest of dai[x]");
    assert(sinUAfter == sinUBefore + rad, "suck did not set sin[u]");
    assert(sinOtherAfter == sinOtherBefore, "suck did not keep unchanged the rest of sin[x]");
    assert(debtAfter == debtBefore + rad, "suck did not set debt");
    assert(viceAfter == viceBefore + rad, "suck did not set vice");
    assert(LineAfter == LineBefore, "suck did not keep unchanged Line");
    assert(liveAfter == liveBefore, "suck did not keep unchanged live");
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

// Verify correct storage changes for non reverting fold
rule fold(bytes32 i, address u, int256 rate_) {
    env e;

    address otherUsr;
    require(otherUsr != u);
    bytes32 otherIlk;
    require(otherIlk != i);
    address anyUsr; address anyUsr2; bytes32 anyIlk;

    uint256 wardsBefore = wards(anyUsr);
    uint256 canBefore = can(anyUsr, anyUsr2);
    uint256 ArtBefore; uint256 rateBefore; uint256 spotBefore; uint256 lineBefore; uint256 dustBefore;
    ArtBefore, rateBefore, spotBefore, lineBefore, dustBefore = ilks(i);
    uint256 ArtOtherBefore; uint256 rateOtherBefore; uint256 spotOtherBefore; uint256 lineOtherBefore; uint256 dustOtherBefore;
    ArtOtherBefore, rateOtherBefore, spotOtherBefore, lineOtherBefore, dustOtherBefore = ilks(otherIlk);
    uint256 inkBefore; uint256 artBefore;
    inkBefore, artBefore = urns(anyIlk, anyUsr);
    uint256 gemBefore = gem(anyIlk, anyUsr);
    uint256 daiBefore = dai(u);
    uint256 daiOtherBefore = dai(otherUsr);
    uint256 sinBefore = sin(anyUsr);
    uint256 debtBefore = debt();
    uint256 viceBefore = vice();
    uint256 LineBefore = Line();
    uint256 liveBefore = live();

    fold(e, i, u, rate_);

    uint256 wardsAfter = wards(anyUsr);
    uint256 canAfter = can(anyUsr, anyUsr2);
    uint256 ArtAfter; uint256 rateAfter; uint256 spotAfter; uint256 lineAfter; uint256 dustAfter;
    ArtAfter, rateAfter, spotAfter, lineAfter, dustAfter = ilks(i);
    uint256 ArtOtherAfter; uint256 rateOtherAfter; uint256 spotOtherAfter; uint256 lineOtherAfter; uint256 dustOtherAfter;
    ArtOtherAfter, rateOtherAfter, spotOtherAfter, lineOtherAfter, dustOtherAfter = ilks(otherIlk);
    uint256 inkAfter; uint256 artAfter;
    inkAfter, artAfter = urns(anyIlk, anyUsr);
    uint256 gemAfter = gem(anyIlk, anyUsr);
    uint256 daiAfter = dai(u);
    uint256 daiOtherAfter = dai(otherUsr);
    uint256 sinAfter = sin(anyUsr);
    uint256 debtAfter = debt();
    uint256 viceAfter = vice();
    uint256 LineAfter = Line();
    uint256 liveAfter = live();

    assert(wardsAfter == wardsBefore, "fold did not keep unchanged every wards[x]");
    assert(canAfter == canBefore, "fold did not keep unchanged every can[x][y]");
    assert(ArtAfter == ArtBefore, "fold did not keep unchanged ilks[i].Art");
    assert(to_mathint(rateAfter) == to_mathint(rateBefore) + to_mathint(rate_), "fold did not set ilks[i].rate");
    assert(spotAfter == spotBefore, "fold did not keep unchanged ilks[i].spot");
    assert(lineAfter == lineBefore, "fold did not keep unchanged ilks[i].line");
    assert(dustAfter == dustBefore, "fold did not keep unchanged ilks[i].dust");
    assert(ArtOtherAfter == ArtOtherBefore, "fold did not keep unchanged the rest of ilks[x].Art");
    assert(rateOtherAfter == rateOtherBefore, "fold ddid not keep unchanged the rest of ilks[x].rate");
    assert(spotOtherAfter == spotOtherBefore, "fold did not keep unchanged the rest of ilks[x].spot");
    assert(lineOtherAfter == lineOtherBefore, "fold did not keep unchanged the rest of ilks[x].line");
    assert(dustOtherAfter == dustOtherBefore, "fold did not keep unchanged the rest of ilks[x].dust");
    assert(inkAfter == inkBefore, "fold did not keep unchanged every urns[x].ink");
    assert(artAfter == artBefore, "fold did not keep unchanged every urns[x].art");
    assert(gemAfter == gemBefore, "fold did not keep unchanged every gem[x][y]");
    assert(to_mathint(daiAfter) == to_mathint(daiBefore) + to_mathint(ArtBefore) * to_mathint(rate_), "fold did not set dai[u]");
    assert(daiOtherAfter == daiOtherBefore, "fold did not keep unchanged the rest of dai[x]");
    assert(sinAfter == sinBefore, "fold did not keep unchanged every sin[x]");
    assert(to_mathint(debtAfter) == to_mathint(debtBefore) + to_mathint(ArtBefore) * to_mathint(rate_), "fold did not set debt");
    assert(viceAfter == viceBefore, "fold did not keep unchanged vice");
    assert(LineAfter == LineBefore, "fold did not keep unchanged Line");
    assert(liveAfter == liveBefore, "fold did not keep unchanged live");
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
