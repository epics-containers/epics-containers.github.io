#!/bin/bash

# demo of exposing Channel Access outside of a container

# caRepeater:
#
# note that these experiments ignore the CA_REPEATER_PORT. Typically
# IOCs in containers should also expose 5065 for the CA repeater.
# Because only the first IOC needs to start caRepeater, and that one process
# binds to 5065, it turns out that caRepeater continues to work as expected.
# (caRepeater can go down if the IOC that started it goes down, but it will get
# restarted by the next IOC startup.)

cmd='-dit --rm --name test ghcr.io/epics-containers/ioc-template-example-runtime:4.1.0'

check () {
    podman run $args $env $ports $cmd > /dev/null
    podman logs -f test | grep -q -m 1 "iocInit"

    if caget EXAMPLE:IBEK:SUM &>/dev/null; then
        echo "CA Success"
    else
        echo "CA Failure"
    fi

    podman stop test &> /dev/null; sleep 1
    echo ---
}

(
    echo no ports, network host, broadcast
    ports=
    args="--network host"
    check
    # the default sledgehammer approach works like native IOCs
)

# I guess broadcasts don't go to the loopback
(
    echo 5064, broadcast: FAILURE
    ports="-p 5064:5064 -p 5064:5064/udp"
    check
)

(
    echo 5064 no UDP, broadcast: FAILURE
    ports="-p 5064:5064"
    check
)

(
    echo 5064, unicast
    export EPICS_CA_ADDR_LIST="localhost"
    ports="-p 5064:5064 -p 5064:5064/udp"
    check
)

(
    echo 5064 no UDP, unicast: FAILURE
    export EPICS_CA_ADDR_LIST="localhost"
    ports="-p 5064:5064"
    check
    # EPICS_CA_ADDR_LIST uses UDP Unicast
)

# NOTE: binding to localhost means that only the local host clients
# can see the IOC. This is useful for testing without exposing the IOC
# on the whole subnet.
(
    echo 5064, broadcast, localhost: FAILURE
    ports="-p 127.0.0.1:5064:5064 -p 127.0.0.1:5064:5064/udp"
    check
    # why does this fail? - I guess broadcasts do not go to localhost
)

(
    echo 5064, unicast, localhost
    export EPICS_CA_ADDR_LIST="localhost"
    ports="-p 127.0.0.1:5064:5064 -p 127.0.0.1:5064:5064/udp"
    check
)

(
    echo  8064, broadcast
    export EPICS_CA_SERVER_PORT=8064
    env="-e EPICS_CA_SERVER_PORT=8064"
    ports="-p 8064:8064 -p 8064:8064/udp"
    check
)

(
    echo  8064, unicast, localhost
    export EPICS_CA_ADDR_LIST="localhost" EPICS_CA_SERVER_PORT=8064
    env="-e EPICS_CA_SERVER_PORT=8064"
    ports="-p 127.0.0.1:8064:8064 -p 127.0.0.1:8064:8064/udp"
    check
)

# remapping the ports does not work!
(
    echo  8064:5064, broadcast: FAILURE
    export EPICS_CA_SERVER_PORT=8064
    ports="-p 8064:5064 -p 8064:5064/udp"
    check
)

(
    echo  8064:5064, unicast, localhost: FAILURE
    export EPICS_CA_ADDR_LIST="localhost" EPICS_CA_SERVER_PORT=8064
    ports="-p 127.0.0.1:8064:5064 -p 127.0.0.1:8064:5064/udp"
    check
)

(
    echo  5064 no UDP, NAME_SERVER, localhost
    export EPICS_CA_NAME_SERVERS="localhost:5064"
    ports="-p 127.0.0.1:5064:5064"
    check
)

(
    echo  8064:5064 no UDP, NAME_SERVER, localhost
    export EPICS_CA_NAME_SERVERS="localhost:8064"
    ports="-p 127.0.0.1:8064:5064"
    check
)
