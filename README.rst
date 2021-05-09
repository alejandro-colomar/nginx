This project is an nginx docker image with only the base nginx package,
to be used by other projects.


________________________________________________________________________

Prerequisites
=============


The basic software needed to be able to build, run, and test this software
is (the following names are those of the packages in Debian):

* bash
* coreutils
* docker.io
* git
* make


________________________________________________________________________

Testing (CI)
============


A single command can be run to test the project.  It is run by the github
actions CI workflow, but is also intended to be run locally before pushing
any changes:

.. code-block:: BASH

	sudo -E make test;


________________________________________________________________________

Release a new version
=====================


Create a new version
^^^^^^^^^^^^^^^^^^^^

.. code-block:: BASH

	make version version='X.Y.Z-alpine-alxA'; # X, Y, Z, and A are numbers


Build and push architecture-specific objects
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Build a docker image for every supported architecture (this needs to be
run from many machines).

.. code-block:: BASH

	make image_;


Build and push multi-arch objects
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: BASH

	make image-manifest_;


________________________________________________________________________

Deployment
==========

Stable deployments use port 30080.
Testing deployments use port 31080.

For a seamless deployment, the following steps need to be done:

- Assuming there is an old stack deployed at port 30080.

- Test the project as explained above.

- Release a new version as explained above.

- Deploy the new version as a testing version:

.. code-block:: BASH

	sudo make stack-deploy;


- Test the new deployment by connecting to ``<localhost:30080>``.

- If the new deployment isn't good engough, that deployment has to be removed.
  The current stable deployment is left untouched.

.. code-block:: BASH

	make stack-rm;


- Else, if the new deployment is good enough, the published port should be
  forwarded to 31080 (this is done in the load balancer or whatever method
  is preferred).

- Remove the oldstable deployment, and deploy the new version at port 30080:

.. code-block:: BASH

	make stack-rm stability=stable;
	sudo make stack-deploy stability=stable;


- The published port should be forwarded back to 30080 (this is done again
  in the load balancer or whatever method is preferred).

- Remove the test deployment at port 31080:

.. code-block:: BASH

	make stack-rm;
