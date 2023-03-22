from argparse import ArgumentParser

from . import __version__

__all__ = ["main"]


def main(args=None):
    parser = ArgumentParser()
    parser.add_argument("--version", action="version", version=__version__)
    args = parser.parse_args(args)

    print("stub project for reporting version number")
    print("this repo is documentation only")
    print(f"version {__version__}")


# test with: python -m epics_containers
if __name__ == "__main__":
    main()
