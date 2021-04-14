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

	sudo make ci;


________________________________________________________________________

Release a new version
=====================


Create an 'rc' tag
^^^^^^^^^^^^^^^^^^

.. code-block:: BASH

	version="X.Y.Z-alpine-alxA";	# X, Y, Z, and A are numbers
	extraversion="-rc";
	tagrc="v${version}${extraversion}";

	git tag "${tagrc}";
	git push origin "${tagrc}";


Build a docker image
^^^^^^^^^^^^^^^^^^^^

Build a docker image with the version (no extraversion), for every supported
architecture (this needs to be run from many machines):

.. code-block:: BASH

	version="X.Y.Z-alpine-alxA";
	extraversion="-rc";
	tagrc="v${version}${extraversion}";

	git fetch --tags;
	git checkout "${tagrc}";
	make image lbl="${version}";


Store the sha256 checksums
^^^^^^^^^^^^^^^^^^^^^^^^^^

Every one of the architectures above will store the sha256 checksum of
the image in ``<./run/docker/image>``.  Store all of those in that file.

Create a multi-arch docker image manifest
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: BASH

	make image-manifest lbl="${version}";


Store the docker image manifest label
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The command above will have stored the label of the manifest in
``<./run/docker/image>``.  Push a commit with that (squashing all of the
commits created in step 3 into this one is nicer).

.. code-block:: BASH

	tag="v${version}";

	git add run/docker/image
	git commit -sm "${tag}";
	git push;


Release
^^^^^^^

.. code-block:: BASH

	git tag -a "${tag}" -m '';
	git push origin "${tag}";


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
  forwarded to 31080 (this is done in the DNS or whatever method is preferred).

- Remove the oldstable deployment, and deploy the new version at port 30080:

.. code-block:: BASH

	make stack-rm stability=stable;
	sudo make stack-deploy stability=stable;


- The published port should be forwarded back to 30080 (this is done again
  in the DNS or whatever method is preferred).

- Remove the test deployment at port 31080:

.. code-block:: BASH

	make stack-rm;
