---
html_theme.sidebar_secondary.remove: true
---

```{include} ../README.md
:end-before: <!-- README only content
```

Materials
---------
- [Workshop @ ORNL, EPICS Collaboration 2024](images/EPICS_Collab_2024.pdf)
- [Oxfordshire EPICS Meeting Nov 2023](images/epics-oxfordshire-nov-2024)
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
