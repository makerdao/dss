.PHONY: build clean test test-gas

build    :; DAPP_BUILD_OPTIMIZE=0 DAPP_BUILD_OPTIMIZE_RUNS=0 dapp --use solc:0.6.12 build
clean    :; dapp clean
test     :; DAPP_BUILD_OPTIMIZE=0 DAPP_BUILD_OPTIMIZE_RUNS=0 dapp --use solc:0.6.12 test -v ${TEST_FLAGS}
test-gas : build
	LANG=C.UTF-8 hevm dapp-test --rpc="${ETH_RPC_URL}" --json-file=out/dapp.sol.json --dapp-root=. --verbose 2 --match "test_gas"
