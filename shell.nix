{ dappPkgs ? (
    import (fetchTarball "https://github.com/makerdao/makerpkgs/tarball/master") {}
  ).dappPkgsVersions.hevm-0_42_0
}: with dappPkgs;

mkShell {
  buildInputs = [
    (dapp.override {
      solc = solc-versions.solc_0_5_12;
    })
  ];
}
