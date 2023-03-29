from importlib.metadata import version

__version__ = version("epics-containers")
del version

__all__ = ["__version__"]
