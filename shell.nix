{ dappPkgs ? (
    import (fetchTarball "https://github.com/makerdao/makerpkgs/tarball/master") {}
  ).dappPkgsVersions.hevm-0_43_1
}: with dappPkgs;

mkShell {
  DAPP_SOLC = solc-static-versions.solc_0_6_11 + "/bin/solc-0.6.11";
  SOLC_FLAGS = "--optimize --optimize-runs=1000000";
  buildInputs = [
    dapp
  ];
}
