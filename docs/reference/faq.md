# Frequently Asked Questions

## How can I do IOC rollback if the internet is down?

The examples all use cloud registries for storing the Generic IOC images and
IOC instances. However it is still possible to roll back an IOC version when
the internet is not available.

Rollback is a git operation. Every `ec deploy` records the desired version of
a service as a commit in the deployment repository — for the ArgoCD backend,
an entry under `services.<name>` in `apps/values.yaml` (see
{any}`deploy-argocd`). git is the single source of truth, so to roll back you
`git revert` that commit and push:

```bash
git -C <deployment-repo> revert <commit>
git -C <deployment-repo> push
```

ArgoCD's auto-sync then reconciles the cluster back to the reverted state,
recreating each IOC's StatefulSet at the previous version. The git server and
cluster can both be on premises, so the revert and re-sync need no internet
connection.

What Kubernetes does still need is to pull the Generic IOC image for the
version it is rolling back to. If the beamline has only one Kubernetes worker
node then the previous image is already in that node's local cache. If you have
more than one then you will need a shared image cache, which is useful anyway
for reducing traffic to the registries.

:::{note}
**DLS users:** DLS runs an on-premises [Harbor](https://goharbor.io/) registry
that mirrors and caches all container images. IOC images therefore stay
pullable — and rollbacks keep working — even when the connection to public
registries is down.
:::

Note that making changes to an IOC and spinning them up would not be possible
if all registries were in the cloud and the internet connection had failed. It
is therefore recommended that the 'work' registries are on premises.
