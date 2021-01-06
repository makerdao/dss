{ dappPkgs ? (
    import (fetchTarball "https://github.com/makerdao/makerpkgs/tarball/master") {}
  ).dappPkgsVersions.hevm-0_43_1
}: with dappPkgs;

mkShell {
  buildInputs = [
    (dapp.override {
      solc = solc-static-versions.solc_0_5_12;
    })
  ];
}
