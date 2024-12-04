# EPICS Network Protocols in Containers

When EPICS IOCs run in containers, Channel Access or PVAcess protocols must be made available to clients. There are some challenges around this that are discussed in this page.


## Approaches to Network Protocols

To get clients and servers connected we can use 3 approaches:

1. Run IOC containers in **Host Network**:
    - This is the approach that DLS has adopted for IOCs running in Kubernetes.
    - The container uses the host network stack.
    - This looks identical to running the IOC on the host machine as far as clients are concerned.
    - See a discussion of the reasoning here: [](./net_protocols.md)
    - This reduces the isolation of the container from the host so additional security measures may be needed.
2. Use **Port Mapping**:
    - This approach is used in the developer containers defined by [ioc-template](https://github.com/epics-containers/example-services)
    - The container runs in a container network.
    - The necessary ports are mapped from the host network to the container network.
    - VSCode can do this port mapping automatically when it detects processes binding to ports.
    - This approach is good for local development and running tutorials as the mapping can be made to localhost only and PVs can be isolated to the developer's machine.
3. Run the clients in the **same container network** as the IOCs:
    - This approach is used in [example-services](https://github.com/epics-containers/example-services).
    - **example-services** runs a PVA and a CA gateway in the same container network as the IOCs.
      - The gateways use Port Mapping to give access to their own clients.
      - The gateways can use any ports and UDP broadcast to communicate with the IOCs.
    - If your client is a GUI app, like phoebus, then this may not work as it can be difficult to do X11 forwarding into a rootless container network.

## General Observations

Using Host Network or the same container network for client and host is compatible with both PVA and CA protocols.

For podman and docker networks this is true even for UDP broadcast.

For the majority of Kubernetes CNI's the broadcast does not work across pods. It is quite possible that broadcast within pods would work as this is equivalent to 'same container network'. However this would make management of large numbers of IOCs far more of a manual task.


## Channel Access

Specification <https://docs.epics-controls.org/en/latest/internal/ca_protocol.html>.

Experiments with Channel Access servers running in containers reveal:
- Port Mapping works for CA including UDP broadcast.
- But UDP broadcast or unicast only works if the container does not remap the port to a different number inside the container.
- Using EPICS_PVA_NAME_SERVERS always works with Port Mapping


## PV Access

Specification <https://docs.epics-controls.org/en/latest/pv-access/Protocol-Messages.html>.

Experimentation with PV Access servers running in containers reveal:
- Port Mapping for PVA using UDP always fails because PVA servers open a new random port for each circuit and this is not NAT friendly.
- Using EPICS_PVA_NAME_SERVERS always works with Port Mapping
- But the client and server must both be PVXS
- To talk to a non PVXS server, a pvagw running in the same container network may be used.

## Code

The following bash scripts can be run to test the assertions made above:

```{literalinclude} ../demo/channel_access_tests.sh
```

```{literalinclude} ../demo/pv_access_tests.sh
```
