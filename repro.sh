#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

git submodule update --init

make -C "$dir/rabbitmq-perf-test"

(cd "$dir/rabbitmq-server" && asdf local erlang 24.3.4 && asdf local elixir 1.12.3-otp-24)

make -C "$dir/rabbitmq-server" FULL=1

(cd "$dir/rabbitmq-server" && ./sbin/rabbitmqctl --node rabbit-1 set_policy --apply-to queues \
    --priority 0 policy-0 ".*" '{"ha-mode":"all", "ha-sync-mode": "automatic", "queue-mode": "lazy"}')

(cd "$dir/rabbitmq-server" && ./sbin/rabbitmqctl --node rabbit-1 set_policy --apply-to queues \
    --priority 1 policy-1 ".*" '{"ha-mode":"all", "ha-sync-mode": "automatic"}')

make -C "$dir/rabbitmq-server" RABBITMQ_CONFIG_FILE="$dir/rabbitmq.conf" NODES=3 start-cluster
