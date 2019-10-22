remappings=ds-test/=lib/ds-test/src/ ds-token/=lib/ds-token/src/ ds-note/=lib/ds-token/lib/ds-stop/lib/ds-note/src/ ds-value/=lib/ds-value/src/ erc20/=lib/ds-token/lib/erc20/src/ ds-math/=lib/ds-token/lib/ds-math/src/ ds-stop/=lib/ds-token/lib/ds-stop/src/ ds-thing/=lib/ds-value/lib/ds-thing/src/ ds-auth/=lib/ds-token/lib/ds-stop/lib/ds-auth/src/
opts=--combined-json=abi,bin,bin-runtime,srcmap,srcmap-runtime,ast
files=$$(find src -type f -name '*.sol')

ls:
	echo ${files}

clean:
	rm -rf out/

build: clean
	mkdir -p out/
	solc --overwrite ${remappings} ${opts} /=/ ${files} > out/dss.json

test: build
	hevm dapp-test --json-file out/dss.json
