---
html_theme.sidebar_secondary.remove: true
---

```{include} ../README.md
:end-before: <!-- README only content
```

Update for April 2024 - version 3.4.0
-------------------------------------

We have just completed another major overhaul of the epics-containers framework. The primary goal of these changes was to add in support for RTEMS based "hard" IOCs. But we have also taken the opportunity to make some other improvements.

"Hard" IOC support is currently limited to the VME5500 processor card running RTEMS 5. However this is a proof of principle for an approach that could be extended to any other type of IOC that cannot run inside of a container. In brief:

- At container build time the IOC binary is cross compiled.
- The developer image is kept (in container registry) as an archive of the sources that built the binary
- The runtime image holds the binary only and is based on a 'proxy' image
- At runtime, the proxy container places the binaries in a location accessible to the hard IOC
- The proxy container connects to the 'hard' IOC console and may change config to point the bootloader at the new binaries
- The proxy container reboots the 'hard' IOC
- The proxy container attaches the IOC console to its stdout/stdin
- Now the proxy container can be managed/logged/monitored exactly like a linux IOC
- We have demonstrated using this approach to locally build and test an RTEMS IOC from a workstation using a vscode developer container.


The tutorials are now up to date with these latest changes, although the RTEMS tutorials are still in development.

From this release onwards changes will be done in a controlled manner described in the page [](explanations/changes).

Update for February 2024
------------------------

The tutorials have now been updated. Recent changes include:

- epics-containers-cli has been renamed to edge-containers-cli. It now supports the deployment of general services as well as IOCs. It still has the entrypoint `ec` but the namespace `ioc` has been dropped and its functions are now in the root (e.g. `ec ioc deploy` is now `ec deploy`).
- Improved CI for {any}`ec-services-repo`s and generic IOCs repos.
- copier template based creation of new beamline, accelerator and generic IOC repos.
  - This provides greatly improved ability to adopt updates to the template into your own repositories.

All tutorials are now up to date with the latest workflow. The exception is tutorials for the RTEMS platform which are now in active development.



Materials
---------
- [Oxfordshire EPICS Meeting Nov 2023](https://dlsltd-my.sharepoint.com/:p:/g/personal/giles_knap_diamond_ac_uk/Ee7SPC_39blEu4Pilgqul7IBiCi4GM9_cgMzONV2ALHIsw?e=U02gHd)
- [ICALEPCS 2021 Paper: Kubernetes for EPICS IOCs](images/THBL04.PDF)
- [ICALEPCS 2021 Talk: Kubernetes for EPICS IOCs](images/THBL04_talk.PDF)

Communication
-------------

If you are interested in discussing containers for control systems, please:

- Add a brief description of your project and the status of it's use of containers to:
  - [The epics-containers Wiki](https://github.com/epics-containers/epics-containers.github.io/wiki/Brief-Overview-of-Projects-Using-Containers-in-Controls)

- Join in the discussion at:
  - [epics-containers.github.io discussions](https://github.com/epics-containers/epics-containers.github.io/discussions)


How the documentation is structured
-----------------------------------

Documentation is split into [four categories](https://diataxis.fr), also accessible from links in the top bar.

<!-- https://sphinx-design.readthedocs.io/en/latest/grids.html -->

::::{grid} 2
:gutter: 4

:::{grid-item-card} {material-regular}`directions_walk;2em`
```{toctree}
:maxdepth: 2
tutorials
```
+++
Tutorials for installation and typical usage. New users start here.
:::

:::{grid-item-card} {material-regular}`directions;2em`
```{toctree}
:maxdepth: 2
how-to
```
+++
Practical step-by-step guides for the more experienced user.
:::

:::{grid-item-card} {material-regular}`info;2em`
```{toctree}
:maxdepth: 2
explanations
```
+++
Explanations of how it works and why it works that way.
:::

:::{grid-item-card} {material-regular}`menu_book;2em`
```{toctree}
:maxdepth: 2
reference
```
+++
Technical reference material including APIs and release notes.
:::

::::
