(helm)=
# Pure Helm Deployments

At DLS we use helm charts in our services repos to describe our IOC instances. However we use ArgoCD continuous deployment to deploy them. ArgoCD is a Kubernetes native tool that knows how to keep a set of Helm charts in a git repository in sync with a set of Kubernetes resources.

You are not required to use ArgoCD, you can use Helm directly if you prefer. This page discusses how to use the command line tool `ec` to deploy and manage IOC instances using Helm directly. `ec` adds some useful version management features to the workflow that to some extent replicates ArgoCD's ability to track versions.

### TODO this is WIP

If you set the `EC_CLI_BACKEND` environment variable to `K8S` then `ec` will use Helm directly to deploy and manage IOC instances. You can get a feel for the commands available with `ec --help`.

```bash
export EC_CLI_BACKEND=K8S
ec --help
```