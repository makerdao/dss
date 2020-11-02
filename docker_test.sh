#! /usr/bin/env bash

set -e

function message() {
    echo
    echo -----------------------------------
    echo "$@"
    echo -----------------------------------
    echo
}

message RUNNING TESTS
docker build -t makerdao/dss-test . && docker run --rm -it makerdao/dss-test
