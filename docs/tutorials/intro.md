# Tutorials Introduction

Welcome to the epics-containers tutorial series. These tutorials introduce you
to building, deploying and managing containerized EPICS IOCs. They are
self-contained and assume no prior experience with the framework.

The series builds up in two halves, in toctree order:

- **Workstation track** — run everything locally with `podman` and
  `docker compose`, starting from a ready-made example and working up to
  building your own Generic IOC. No cluster required.
- **Cluster track** — move the same workflow onto a Kubernetes cluster and
  deploy IOCs with ArgoCD continuous deployment.

If you only need IOCs on a single server you can stop after the workstation
track; the cluster track is independent and can be tackled later.

Before you start, it helps to have some background in the technologies the
framework builds on:

| Topic | Link |
|---|---|
| An introduction to containers | <https://www.docker.com/resources/what-container/> |
| Managing containers with podman | <https://docs.podman.io/en/latest/Introduction.html> |
| Introduction to docker compose | <https://docs.docker.com/compose/> |
| Orchestrating containers with Kubernetes | <https://kubernetes.io/docs/concepts/overview/> |
| Managing packages with Helm | <https://helm.sh/docs/intro/quickstart/> |
| Introduction to EPICS | <https://docs.epics-controls.org/en/latest/guides/EPICS_Intro.html> |
| Continuous deployment with Argo CD | <https://argo-cd.readthedocs.io/en/stable/> |

For an overview of how epics-containers fits these together, read
{any}`../explanations/introduction`.

You will need a workstation running Linux, Mac or Windows, plus a free GitHub
account. All the required software is open source. The next tutorial,
{any}`setup_workstation`, walks you through installing it.
