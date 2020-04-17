{ dappPkgs ? (
    import (fetchTarball "https://github.com/makerdao/makerpkgs/tarball/master") {}
  ).dappPkgsVersions.seth-0_8_4
}: with dappPkgs;

mkShell {
  buildInputs = [
    (dapp.override {
      solc = solc-versions.solc_0_5_12;
    })
  ];
}
