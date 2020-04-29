#!/usr/bin/env bash

# Requires vegeta to be installed.

echo "Running: SET"
vegeta attack -targets=./bench.targets.set.txt -rate=0 -max-workers=900 -duration=10s | vegeta report

echo -e "\n"

echo "Running: GET"
vegeta attack -targets=./bench.targets.get.txt -rate=0 -max-workers=900 -duration=10s | vegeta report