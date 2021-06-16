from argparse import ArgumentParser

from k8s_epics_docs import __version__


def main(args=None):
    parser = ArgumentParser()
    parser.add_argument("--version", action="version", version=__version__)
    args = parser.parse_args(args)

    # dummy CLI entry point
