#!/bin/bash

# demo of exposing PV Access outside of a container

# requires a venv with p4p installed

pvget='
from p4p.client.thread import Context

Context("pva").get("EXAMPLE:IBEK:SUM", timeout=0.5)
'

cmd='-dit --rm --name test ghcr.io/epics-containers/ioc-template-example-runtime:4.1.0'

check () {
    podman run $args $env $ports $cmd > /dev/null
    podman logs -f test | grep -q -m 1 "iocInit"

    if python -c "$pvget" 2>/dev/null; then
        echo "PVA Success"
    else
        echo "PVA Failure"
    fi

    podman stop test &> /dev/null
    echo ---
}

(
    echo no ports, network host, broadcast
    ports=
    args="--network host"
    check
    # the default sledgehammer approach works like native IOCs
)

# PVA fails for broadcast and unicast because the client creates a new random
# port for the server to make the TCP circuit but that is not NAT friendly.
(
    echo 5075, broadcast: FAILURE
    ports="-p 5075:5075 -p 5075:5075/udp"
    check
)

(
    echo 5075, unicast: FAILURE
    export EPICS_PVA_ADDR_LIST="localhost"
    ports="-p 5075:5075 -p 5075:5075/udp"
    check
)

# NAME SERVER uses a single TCP connection and is compatible with NAT
#
# IMPORTANT - for this to work, both ends of the conversation must be pvxs.
# Thus to talk to ADPvaPlugin requires a pvagw running in the same container
# network to proxy the traffic
(
    echo 5075, NAME SERVER
    export EPICS_PVA_NAME_SERVERS="localhost:5075"
    ports="-p 5075:5075"
    check
)

(
    echo 8057:5075, NAME SERVER
    export EPICS_PVA_NAME_SERVERS="localhost:8075"
    ports="-p 8075:5075"
    check
)
