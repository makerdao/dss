build  :; DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=1000000 dapp --use solc:0.6.11 build
clean  :; dapp clean
test   :; DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=1000000 dapp --use solc:0.6.11 test -v ${TEST_FLAGS}
