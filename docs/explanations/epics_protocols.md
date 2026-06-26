# EPICS Network Protocols in Containers

When EPICS IOCs run in containers, their Channel Access (CA) and PV Access
(PVA) traffic must still reach clients. Both protocols predate containers and
make assumptions - UDP broadcast for discovery, freely negotiated ephemeral
ports - that container networks do not always honour. This page explains the
options and why epics-containers makes the choices it does.

## Approaches to Network Protocols

There are three ways to connect clients and servers:

1. Run IOC containers in **host network**:
    - The container uses the host's network stack, so it looks identical to a
      native IOC running on that machine.
    - This is the approach epics-containers uses for IOCs in Kubernetes - see
      {ref}`kubernetes-networking` for why.
    - It reduces isolation between container and host, so additional security
      measures may be needed.
2. Use **port mapping**:
    - Used by the developer containers in
      [example-services](https://github.com/epics-containers/example-services).
    - The container runs in a container network and the required ports are
      mapped from the host. VS Code can do this automatically when it detects
      a process binding to a port.
    - Good for local development and tutorials: the mapping can be bound to
      localhost only, isolating PVs to the developer's machine.
3. Run clients in the **same container network** as the IOCs:
    - Also used by
      [example-services](https://github.com/epics-containers/example-services),
      which runs a CA and a PVA gateway alongside the IOCs.
    - The gateways reach the IOCs over any ports and UDP broadcast, and use
      port mapping to publish to their own clients.
    - A GUI client such as Phoebus may still struggle here, as X11 forwarding
      into a rootless container network is awkward.

:::{note}
DLS users: managed Kubernetes beamlines run IOCs in host network for exactly
the reasons set out below. See the
[DLS developer guide](https://dev-guide.diamond.ac.uk/epics-containers/).
:::

## General Observations

Host network, or sharing one container network between client and server, is
compatible with both CA and PVA - and with UDP broadcast on podman networks.

Most Kubernetes CNIs do not pass broadcast between pods. Broadcast *within* a
pod would work (equivalent to "same container network"), but that would make
managing large numbers of IOCs a manual chore.

## Channel Access

Specification: <https://docs.epics-controls.org/en/latest/internal/ca_protocol.html>.

Experiments with CA servers in containers show:

- Port mapping works for CA, including UDP broadcast.
- Broadcast or unicast only works if the container does **not** remap the port
  to a different number inside the container.
- `EPICS_CA_NAME_SERVERS` always works with port mapping.

## PV Access

Specification: <https://docs.epics-controls.org/en/latest/pv-access/Protocol-Messages.html>.

Experiments with PVA servers in containers show:

- Port mapping over UDP always fails: a PVA server opens a new random port per
  circuit, which is not NAT friendly.
- `EPICS_PVA_NAME_SERVERS` always works with port mapping, but both client and
  server must be PVXS.
- To talk to a non-PVXS server, run a `pvagw` in the same container network.

## Test Scripts

The following scripts exercise the assertions above against a demo IOC:

```{literalinclude} ../demo/channel_access_tests.sh
```

```{literalinclude} ../demo/pv_access_tests.sh
```

(kubernetes-networking)=
## Running IOCs in Kubernetes

A Kubernetes cluster connects pods through a CNI (Container Network Interface)
- a virtual network overlay. To reach a pod from outside you normally define a
Service, which provides Network Address Translation (NAT) and an external
IP/port. CNIs typically do **not** carry broadcast traffic on this virtual
LAN.

That breaks two things EPICS relies on:

- **UDP broadcast** for IOC discovery.
- **Application-negotiated ephemeral ports** - NAT cannot route to a port it
  has not already seen, so the reply looks like a brand-new connection.

When prototyping IOCs in Kubernetes we hit these problems with Channel Access,
PV Access and GVSP (GigE Vision Streaming Protocol).

### Why per-protocol workarounds fail

We first tried protocol-specific proxies. The diagram below shows a
"ca-forwarder" on the EPICS client subnet relaying requests to IOCs in the
cluster:

:::{figure} ../images/caforwarder.png
:::

But this breaks down as soon as a client lives *inside* the cluster:

:::{figure} ../images/cabackwarder.png
:::

Each workaround was fiddly, had to be redone per protocol, and gave no
guarantee that every protocol we might need could be solved at all.

### Solution: host network

Instead we bypass the CNI entirely:

- Run IOC pods on worker nodes that sit in the **beamline subnet**.
- Set `hostNetwork: true` so pods get direct access to the host node's network.

From a networking point of view the IOC is then indistinguishable from a
traditional IOC on a beamline server: it listens on the host's IP, receives
broadcasts, and can open ephemeral ports that clients reach with no NAT in the
way. `hostNetwork: true` is the default in the
[ioc-instance Helm chart](https://github.com/epics-containers/ec-helm-charts).

Host network needs elevated privileges, so harden the pods:

- **Drop unneeded Linux capabilities** in the pod's `securityContext`, keeping
  only what EPICS needs (for example `NET_ADMIN` and `NET_BROADCAST`). This
  shrinks the attack surface.
- **Pin IOC pods to beamline nodes.** Label and taint the beamline worker
  nodes with the beamline name; IOC pods then set a matching `nodeSelector`
  and `tolerations` so only the right IOCs land there.

:::{note}
DLS users: the production "Argus" cluster implements this pattern with remote
beamline worker nodes. See the developer guide
[argocd-accelerator](https://dev-guide.diamond.ac.uk/epics-containers/explanations/argocd-accelerator.html)
explanation and the
[where](https://dev-guide.diamond.ac.uk/epics-containers/reference/where.html)
reference.
:::
