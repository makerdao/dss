.PHONY: build clean test test-gas

build    	:; DAPP_BUILD_OPTIMIZE=0 DAPP_BUILD_OPTIMIZE_RUNS=0 dapp --use solc:0.5.12 build
clean    	:; dapp clean
test     	:; DAPP_BUILD_OPTIMIZE=0 DAPP_BUILD_OPTIMIZE_RUNS=0 DAPP_TEST_ADDRESS=0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B dapp --use solc:0.5.12 test -v ${TEST_FLAGS}
test-gas 	:; build && LANG=C.UTF-8 hevm dapp-test --rpc="${ETH_RPC_URL}" --json-file=out/dapp.sol.json --dapp-root=. --verbose 2 --match "test_gas"
certora-vat :; PATH=~/.solc-select/artifacts/solc-0.5.12:~/.solc-select/artifacts/:${PATH} certoraRun --solc_map Vat=solc-0.5.12 --optimize_map Vat=0 --rule_sanity basic src/vat.sol:Vat --verify Vat:certora/Vat.spec --staging jaroslav/partialLIAAxiomatisation --settings -mediumTimeout=180,-deleteSMTFile=false,-postProcessCounterExamples=none,-t=1200$(if $(short), --short_output,)$(if $(rule), --rule $(rule),)$(if $(multi), --multi_assert_check,)
certora-dai :; PATH=~/.solc-select/artifacts/solc-0.5.12:~/.solc-select/artifacts:${PATH} certoraRun --solc_map Dai=solc-0.5.12,Auxiliar=solc-0.5.12 --optimize_map Dai=0,Auxiliar=0 --rule_sanity basic src/dai.sol:Dai certora/Auxiliar.sol --verify Dai:certora/Dai.spec --settings -mediumTimeout=180 --optimistic_loop$(if $(short), --short_output,)$(if $(rule), --rule $(rule),)$(if $(multi), --multi_assert_check,)
