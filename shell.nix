{ dappPkgs ? (
    import (fetchTarball "https://github.com/makerdao/makerpkgs/tarball/master") {}
  ).dappPkgsVersions.hevm-0_43_1
}: with dappPkgs;

mkShell {
  DAPP_SOLC = solc-static-versions.solc_0_5_12 + "/bin/solc-0.5.12";
  # SOLC_FLAGS = "--optimize --optimize-runs=200";
  buildInputs = [
    dapp
  ];
}
