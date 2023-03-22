import subprocess
import sys

from epics_containers import __version__


def test_cli_version():
    cmd = [sys.executable, "-m", "epics_containers", "--version"]
    assert subprocess.check_output(cmd).decode().strip() == __version__
