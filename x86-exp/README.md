# Core Slicing on x86 -- Benchmark setup details

## Hardware config

We need two machines, one is the system under test, one is the network client.
Ideally, the network client should be more powerful than the system under test
(to generate sufficient memcached load), but for the paper we had it the other
way round: the test system had 2x12-core CPUs, and the client had 2x8-core CPUs.

Each machine should be on a control network (e.g. corpnet) via the host adapter.
Additionally, each machine has a CX-4 NIC (make sure this is in a x16 slot for
full bandwidth) and those are connected back-to-back via an SFP cable, so they
get a 25G link.

Finally, the test system has the PM1735 NVMe drive in it.

## Software config: network client

The client system doubles as a DHCP server and masquerading gateway to allow
slice guests to (slowly, but that doesn't matter) reach the internet. To set this
up:

 1. Install Ubuntu 22.04
 2. Edit the network config (`/etc/netplan/*.yaml`) to give the CX4 NIC a fixed IP address, e.g.:
    ```
    network:
        ethernets:
            eno1:
                dhcp4: false # not connected
            enp21s0f0np0:
                addresses:
                    - 192.168.37.1/24
            enp9s0f2:
                dhcp4: true
        version: 2
    ```
    Then run `sudo netplan apply`

 3. Install `isc-dhcp-server` package, and configure it as follows:
    * In `/etc/dhcp/dhcpd.conf` add:
       ```
       # option definitions common to all supported networks...
       option domain-name "corp.microsoft.com";
       option domain-name-servers 10.50.10.50, 10.50.50.50;

       subnet 192.168.37.0 netmask 255.255.255.0 {
        range 192.168.37.100 192.168.37.200;
        option routers 192.168.37.1;
        option subnet-mask 255.255.255.0;
        option broadcast-address 192.168.37.255;
       }

       host slice0 {
        hardware ethernet 02:22:33:44:55:66;
        fixed-address 192.168.37.10;
       }

       host slice1 {
        hardware ethernet 02:22:33:44:55:67;
        fixed-address 192.168.37.11;
       }

       host slice2 {
        hardware ethernet 02:22:33:44:55:68;
        fixed-address 192.168.37.12;
       }
       ```
     * In `/etc/default/isc-dhcp-server` add the CX4 interface name to `INTERFACESv4`.
     * Start the server with `sudo service isc-dhcp-server restart`

  4. To configure NAT (IP masquerading), we need to:
     * Edit `/etc/ufw/sysctl.conf`:
        ```
        # Uncomment this to allow this host to route packets between interfaces
        net/ipv4/ip_forward=1
        net/ipv6/conf/default/forwarding=1
        net/ipv6/conf/all/forwarding=1
        ```
     * In `/etc/ufw/before.rules`, add these lines (borrowed from [here](https://blog.oshim.net/2013/01/configure-ip-masquerading-for-ubuntu/)) to the top of the file:
        ```
        *nat
        :POSTROUTING ACCEPT [0:0]
        -A POSTROUTING -s 192.168.37.0/24 -o enp9s0f2 -j MASQUERADE
        COMMIT
        ```
        Note that in this example, `enp9s0f2` is the main upstream interface.
     * In `/etc/default/ufw` make sure all three of the `DEFAULT_INPUT_POLICY`,
    `DEFAULT_OUTPUT_POLICY`, and `DEFAULT_FORWARD_POLICY` are `ACCEPT`.
     * In `/etc/ufw/ufw.conf` set `ENABLED=yes`.
     * Run `sudo service ufw restart` (and cross your fingers that it doesn't drop off the network).

Finally, to run CloudSuite clients, install Docker following [these instructions](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository).

## Software config: test system

Follow the README in the sliceloader-x86 repo to setup the test system.

## Running benchmarks

You can find a couple of helper scripts in the same directory as this file.

### Local benchmarks

Graph analytics and in-memory analytics run entirely on the test system, using `collect-local.sh`. Copy back the log files to the appropriate places after the run.

### Data serving

(Once only, to setup the entire network.) On the client, create a swarm, and create a network:
```
docker swarm init
docker network create serving_network
```

(Once only, for each new server image.) On the client, run:
```
docker swarm join-token worker
```
This will print the command you need to use on the server to join it to the swarm.

On the server, ensure the node is joined to the swarm (see above), then run:
```
docker run --name cassandra-server --net serving_network cloudsuite3/data-serving:server cassandra
```
(wait for it to print "Keyspace usertable was created")

On the client, run:
```
docker run --rm -e RECORDCOUNT=10000000 -e OPERATIONCOUNT=10000000 --name cassandra-client --net serving_network 0xabu/data-serving:client cassandra-server | tee data-serving.log
```

When the run finishes, retain `data-serving.log` in the appropriate data folder.

If the server was already loaded by a prior run, you can try adding -e
SKIP_LOAD=1 to skip the lengthy load phase on the client side, but note that
results in the paper were from a clean run with a fresh server instance.

### Data caching

Copy `collect-data-caching.sh` and `check_qos.py` to the client system.

See the top of `collect-data-caching.sh` for the commands to run on the server, e.g.:
```
docker run --rm --name dc-server --net host -d cloudsuite3/data-caching:server -t 4 -m 8192 -n 550 -p 11211
```

On the client, remove all the existing log files, then run `collect-data-caching.sh` which will
load the server, capture the peak load, and then execute a binary search for the highest load
that achieves the QoS target. Copy back all the log files when you are done.

It's important to saturate the server CPU to see a difference in system
overhead, so while the peak load experiment is running, ensure that the *server*
is bottlenecked on CPU time, and not the client (or the network). For our
config, this required far more threads on the client side than on the server
side (max 2-3 threads). Ensure that the server CPUs are fully utilised (>98% CPU
time in memcached). The workload supports multiple servers, but we don't use
them as we can't saturate them.

See https://github.com/parsa-epfl/cloudsuite/blob/CSv3/docs/benchmarks/data-caching.md for more details.

## Notes on benchmarks we didn't use (yet)

### Web Serving

https://github.com/parsa-epfl/cloudsuite/blob/CSv3/docs/benchmarks/web-serving.md

We run 3 guests (for each of the three tiers), each with 8G and 4 cores.

Server 0 (database):
```
sudo ./runvm.sh -m 8 -c 4 -p 2 -v 0
docker run --rm -dt --net=host --name=mysql_server cloudsuite3/web-serving:db_server 192.168.37.12
```

Server 1 (memcache):
```
sudo ./runvm.sh -m 8 -c 4 -p 2 -v 1
docker run --rm -dt --net=host --name=memcache_server cloudsuite3/web-serving:memcached_server
```

Server 2 (web server):
```
sudo ./runvm.sh -m 8 -c 4 -p 2 -v 2
docker run --rm -dt --net=host --name=web_server cloudsuite3/web-serving:web_server /etc/bootstrap.sh 192.168.37.10 192.168.37.11
```

Client:
```
docker run --rm --net=host --name=faban_client cloudsuite3/web-serving:faban_client 192.168.37.12 100 | tee web-serving-vm2m-100.log
```
… where 100 is the load scale.

Check for `<passed>true</passed>` in the output, and the ops/sec.

TODO: figure out why it doesn't pass, how to tune/scale this benchmark, etc.

### Media Streaming

This benchmark produced unstable results. It is entirely I/O bound, so not very interesting.

### Web Search

This container tries to download a huge file from EPFL each time it runs. They appear to have fixed it in v4, but that's not yet released.
