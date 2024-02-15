Troubleshooting
===============

Permissions issues with GitHub
-------------------------------

Problem: in the devcontainer you see the following error:

.. code-block:: none

    git@github.com: Permission denied (publickey).
    fatal: Could not read from remote repository.

Solution: you may need to add your github ssh key to the ssh-agent as
follows:

.. code-block:: none

    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa

Where ``id_rsa`` is the name of your private key file you use for connecting
to GitHub.
