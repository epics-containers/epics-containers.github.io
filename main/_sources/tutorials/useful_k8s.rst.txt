
Useful Kubernetes Additions
===========================

Install the Kubernetes Dashboard
--------------------------------

The dashboard gives you a nice GUI for exploring and controlling your cluster.
It is very useful for new users to get an understanding of what Kubernetes
has to offer.

Execute this on your workstation:

.. code-block:: bash

    GITHUB_URL=https://github.com/kubernetes/dashboard/releases
    VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
    kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml

Then create the admin user and role by creating dashboard-admin.yaml containing:

.. code-block:: yaml

    apiVersion: v1
    kind: ServiceAccount
    metadata:
    name: admin-user
    namespace: kubernetes-dashboard
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
    name: admin-user
    roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cluster-admin
    subjects:
    - kind: ServiceAccount
    name: admin-user
    namespace: kubernetes-dashboard

get a token for the user::

    kubectl create -f dashboard-admin.yaml
    kubectl -n kubernetes-dashboard describe secret admin-user-token | grep '^token'

Finally, start a proxy and goto the Dashboard URL, use the above token to log in::

    kubectl proxy &
    browse to http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy


Add a Raspberry Pi to the cluster
---------------------------------

For a Raspberry Pi you need a couple of extra settings to get K3S running.

You need the following changes before installing::

    sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
    # edit /boot/cmdline and make sure the single line contains:
    #  cgroup_memory=1 cgroup_enable=memory
    sudo reboot
