#!/bin/bash

# demo of exposing channel access outside of a container

cmd='-dit --rm --name test ghcr.io/epics-containers/ioc-adsimdetector-demo:2024.11.1'

check () {
    podman run $args $env $ports $cmd > /dev/null
    podman logs -f test | grep -q -m 1 "iocInit"

    if [[ $(caget BL01T-EA-TST-02:DET:Acquire 2>/dev/null) =~ "Acquire" ]]; then
        echo "CA Success"
    else
        echo "CA Failure"
    fi

    podman stop test &> /dev/null
    echo ---
}

(
    echo no ports, network host, broadcast
    ports=
    args="--network host"
    check #success
    # the default sledgehammer approach works like native IOCs
)

(
    echo 5064, broadcast
    ports="-p 5064:5064 -p 5064:5064/udp"
    check #success
)

(
    echo 5064 no UDP, broadcast: FAILURE
    ports="-p 5064:5064"
    check #failure
)

(
    echo 5064, unicast
    export EPICS_CA_ADDR_LIST="localhost"
    ports="-p 5064:5064 -p 5064:5064/udp"
    check #success
)

(
    echo 5064 no UDP, unicast: FAILURE
    export EPICS_CA_ADDR_LIST="localhost"
    ports="-p 5064:5064"
    check #failure
    # EPICS_CA_ADDR_LIST uses UDP Unicast
)

# NOTE: binding to localhost means that only the local host clients
# can see the IOC. This is useful for testing without exposing the IOC
# on the whole subnet.
(
    echo 5064, broadcast, localhost: FAILURE
    ports="-p 127.0.0.1:5064:5064 -p 127.0.0.1:5064:5064/udp"
    check #failure
    # why does this fail? - I guess broadcasts do not go to localhost
)

(
    echo 5064, unicast, localhost
    export EPICS_CA_ADDR_LIST="localhost"
    ports="-p 127.0.0.1:5064:5064 -p 127.0.0.1:5064:5064/udp"
    check #success
)

(
    echo  8064, broadcast
    export EPICS_CA_SERVER_PORT=8064
    env="-e EPICS_CA_SERVER_PORT=8064"
    ports="-p 8064:8064 -p 8064:8064/udp"
    check #success
)

(
    echo  8064, unicast, localhost
    export EPICS_CA_ADDR_LIST="localhost" EPICS_CA_SERVER_PORT=8064
    env="-e EPICS_CA_SERVER_PORT=8064"
    ports="-p 127.0.0.1:8064:8064 -p 127.0.0.1:8064:8064/udp"
    check #success
)

# remapping the ports does not work!
(
    echo  8064:5064, broadcast: FAILURE
    export EPICS_CA_SERVER_PORT=8064
    ports="-p 8064:5064 -p 8064:5064/udp"
    check #failure
)

(
    echo  8064:5064, unicast, localhost: FAILURE
    export EPICS_CA_ADDR_LIST="localhost" EPICS_CA_SERVER_PORT=8064
    ports="-p 127.0.0.1:8064:5064 -p 127.0.0.1:8064:5064/udp"
    check #failure
)

(
    echo  5064 no UDP, NAME_SERVER, localhost
    export EPICS_CA_NAME_SERVERS="localhost:5064"
    ports="-p 127.0.0.1:5064:5064"
    check #success
)

(
    echo  8064:5064 no UDP, NAME_SERVER, localhost
    export EPICS_CA_NAME_SERVERS="localhost:8064"
    ports="-p 127.0.0.1:8064:5064"
    check #success
)
