Create a new generic IOC image
==============================

Getting started
---------------

You may need to create an IOC instance that depends on support modules
that have not yet been published in a generic IOC image. In this case
you will need to publish a new generic IOC image that provides the
additional support.

This requires building a new Dockerfile that describes the image. The
Dockerfile will be hosted in a new source repository that includes any
additional files for the image context. In epics-containers
these repos are all called ioc-XXX where XXX is the name of the primary
support module being containerized.

To start a new ioc-XXX repo you can use the ioc-template project at
https://github.com/epics-containers/ioc-template and click **Use Template**.

If you search the resulting project for TODO this will give you hints
on how to create your new generic IOC.

All images will follow a very similar pattern, here is an example which builds
the ADAravis support module for GigE cameras.

.. code-block:: docker

    # Add support for GigE cameras with the ADAravis support module
    ARG REGISTRY=ghcr.io/epics-containers
    ARG ADCORE_VERSION=3.10r2.0

    FROM ${REGISTRY}/epics-areadetector:${ADCORE_VERSION}

    # install additional tools and libs
    USER root

    RUN apt-get update && apt-get upgrade -y && \
        apt-get install -y --no-install-recommends \
        libglib2.0-dev \
        meson \
        intltool \
        pkg-config \
        xz-utils \
        && rm -rf /var/lib/apt/lists/*

    # build aravis library
    RUN cd /usr/local && \
        git clone -b ARAVIS_0_8_1 --depth 1 https://github.com/AravisProject/aravis && \
        cd aravis && \
        meson build && \
        cd build && \
        ninja && \
        ninja install && \
        echo /usr/local/lib64 > /etc/ld.so.conf.d/usr.conf && \
        ldconfig && \
        rm -fr /usr/local/aravis

    USER ${USERNAME}

    # get additional support modules
    ARG ADARAVIS_VERSION=R2-2-1
    ARG ADGENICAM_VERSION=R1-8

    RUN python3 module.py add areaDetector ADGenICam ADGENICAM ${ADGENICAM_VERSION}
    RUN python3 module.py add areaDetector ADAravis ADARAVIS ${ADARAVIS_VERSION}

    # add CONFIG_SITE.linux and RELEASE.local
    COPY --chown=${USER_UID}:${USER_GID} configure ${SUPPORT}/ADGenICam-${ADGENICAM_VERSION}/configure
    COPY --chown=${USER_UID}:${USER_GID} configure ${SUPPORT}/ADAravis-${ADARAVIS_VERSION}/configure

    # update the generic IOC Makefile to include the new support
    COPY --chown=${USER_UID}:${USER_GID} Makefile ${EPICS_ROOT}/ioc/iocApp/src

    # update dependencies and build the support modules and the ioc
    RUN python3 module.py dependencies
    RUN make -j -C  ${SUPPORT}/ADGenICam-${ADGENICAM_VERSION} && \
        make -j -C  ${SUPPORT}/ADAravis-${ADARAVIS_VERSION} && \
        make -j -C  ${IOC} && \
        make -j clean

Changes to The Template Project
-------------------------------

:TODO:
     cover details of what is needed and how module.py works
     don't forget to include RELEASE.shell

Build and Publish the Generic IOC Image
---------------------------------------

:TODO:
    test build locally with docker build
    use CI to build and Publish on GitHub
