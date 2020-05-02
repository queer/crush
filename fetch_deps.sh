#!/usr/bin/env bash

echo ">> Fetching mix dependencies..." &&
mix deps.get &&
echo ">> Patching setup/rebar.config to allow building" &&
sed -i -e 's/^{post_hooks, \[{compile, "make escriptize"}\]}\./%% {post_hooks, [{compile, "make escriptize"}]}./' ./deps/setup/rebar.config