.. _CLI:

Command Line Interface for IOC Management
=========================================

The Module k8s-epics-utils provides scripts that simplify common operations
for deploying and managing IOCs with Kubernetes.

The underlying tools used are:

  - kubectl: https://kubernetes.io/docs/tasks/tools/
  - helm: https://helm.sh/docs/intro/install/

All the functions described below are simply shortcuts for helm and
kubectl commands.

To enable the scripts you must have helm and kubectl installed and be
authenticated to your kubernetes cluster. You must also have enabled a
kubectl context that connects to the kubernetes namespace in which you
deploy your IOCs.

Declare the URL of your HELM registry and source kube-functions.sh to add
the k8s-iocs function to your shell:

  - export K8S_HELM_REGISTRY=ghcr.io/epics-containers
  - wget https://raw.githubusercontent.com/epics-containers/k8s-epics-utils/main/epics-dev-image/home/bin/kube-functions.sh
  - source kube-functions.sh

The k8s-iocs shell function can perform the following opertions. Note that
the command k8s-iocs with no parameters will print this list.

        usage:
          k8s-ioc <command> <options>

          commands:

            attach <ioc-name>
                    attach to a running ioc shell
            delete <ioc-name>
                    delete all ioc resources except storage
            deploy <ioc-name> <ioc-version>
                    deploy an ioc manifest from the beamline helm registry
            exec <ioc-name>
                    execute bash in the ioc's container
            history <ioc-name>
                    list the history of installed versions of an ioc
            graylog <ioc-name>
                    print a URL to get to greylog historical logging for an ioc
            list <ioc-name> [options]
                    list k8s resources associtated with ioc-name
                    -o output formatting e.g. -o name
            log <ioc-name> [options]
                    display log of ioc output
                    -p for previous instance
                    -f to attach to output stream
            monitor <beamline>
                    monitor the status of running IOCs on a beamline
            ps [<beamline>]
                    list all running iocs [on beamline]
            purge
                    clear the helm local cache
            restart <ioc-name>
                    restart a running ioc
            rollback <ioc-name> <revision>
                    rollback to a previous revision
                    (see history command for revision numbers)
            start <ioc-name>
                    start a stopped ioc
            stop  <ioc-name>
                    stop a deployed ioc
