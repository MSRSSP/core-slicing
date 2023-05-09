#!/bin/bash -e

# Script run on the client, to collect data-caching benchmarks.
# Servers must already be running, ala:
#  docker run --rm --name dc-server1 --net host -d cloudsuite3/data-caching:server -t 4 -m 8192 -n 550 -p 11211
#  docker run --rm --name dc-server2 --net host -d cloudsuite3/data-caching:server -t 4 -m 8192 -n 550 -p 11212
#  etc.

GUEST_DIR=/usr/src/memcached/memcached_client
LOADER_ARGS="-a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -g 0.8 -T 1 -c 200 -w 16"
RUNTIME=5m
NSERVERS=1
SERVERMEM=8192
MINRPS=240000
MAXRPS=260000

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <server-ip>" > /dev/stderr
    exit 1
fi

set -x

if docker container inspect dc-client > /dev/null; then

    echo "==================== Existing client: warm-up phase ===================="

    docker stop dc-client
    docker start dc-client
    docker exec -t dc-client bash -c "cd $GUEST_DIR && ./loader -a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -w 4 -S 1 -D $SERVERMEM -j -T 1"

else

    docker create --name dc-client --net host cloudsuite3/data-caching:client sleep 7d

    TMPFILE=$(mktemp)
    chmod a+r $TMPFILE

    for port in $(seq 11211 $((11211+NSERVERS-1))); do
        echo "$1, $port" >> $TMPFILE
    done

    docker cp $TMPFILE dc-client:$GUEST_DIR/docker_servers.txt
    rm $TMPFILE

    echo "==================== New client: load and warm-up phase ===================="

    docker start dc-client
    docker exec -t dc-client bash -c "cd $GUEST_DIR && ./loader -a ../twitter_dataset/twitter_dataset_unscaled -o ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -w 2 -S 30 -D $SERVERMEM -j -T 1"

fi

if [[ ! -f peak.log ]]; then
    echo "==================== Peak load ===================="
    set +e
    timeout $RUNTIME docker exec -t dc-client bash -c "cd $GUEST_DIR && ./loader $LOADER_ARGS" | tee peak.log
    set -e
    docker stop dc-client
fi

minrps=$MINRPS
maxrps=$MAXRPS

while [[ $((maxrps - minrps)) -gt 500 ]]; do
    rps=$(((minrps + maxrps) / 2))
    echo "==================== Target RPS: $rps (min: $minrps, max: $maxrps) ===================="
    docker start dc-client
    set +e
    timeout $RUNTIME docker exec -t dc-client bash -c "cd $GUEST_DIR && ./loader $LOADER_ARGS -r $rps" | tee qos-$rps.log | ./check_qos.py
    exitstatus=$?
    set -e
    docker stop dc-client

    if [[ $exitstatus -eq 0 ]]; then
        echo "Passed at $rps"
        minrps=$rps
    else
        echo "Failed at $rps"
        maxrps=$rps
    fi
done

docker rm dc-client

if [[ $minrps -eq $MINRPS ]]; then
    echo "Error: QoS RPS not found, below configured range" > /dev/stderr
    exit 1
elif [[ $maxrps -eq $MAXRPS ]]; then
    echo "Error: QoS RPS not found, above configured range" > /dev/stderr
    exit 1
else
    ln -fs qos-$minrps.log qos.log
fi
