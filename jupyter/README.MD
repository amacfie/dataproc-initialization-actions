# Jupyter Notebook

This folder contains the initialization action `jupyter.sh` to quickly setup and launch [Jupyter Notebook](http://jupyter.org/), (the successor of IPython notebook) and a script to be run on the user's local machine to access the Jupyter notebook server.

Note: This init action uses Conda and Python 3. Python 2 and `pip` uesrs should consider using the [jupyter2 action](https://github.com/GoogleCloudPlatform/dataproc-initialization-actions/tree/master/jupyter2).

## Using this initialization action

You can use this initialization action to create a new Dataproc cluster with Jupyter installed:

1. Use the `gcloud` command to create a new cluster with this initialization action.  The following command will create a new cluster named `<CLUSTER_NAME>`.

    ```bash
    # Simple one-liner; just use all default settings for your cluster. Jupyter will run on port 8123
    # of your master node.
    CLUSTER=<CLUSTER_NAME>
    gcloud dataproc clusters create $CLUSTER \
        --initialization-actions gs://dataproc-initialization-actions/jupyter/jupyter.sh
    ```

1. Run `./launch-jupyter-interface` to connect to the Jupyter notebook running on the master node. This creates a SOCKS5 proxy to the master node and launches a Google Chrome window that uses this proxy. Note: you will need to edit the script to point it at the Chrome installation path for your operating system. Alternatively, follow the instructions in [connecting to cluster web interfaces](https://cloud.google.com/dataproc/docs/concepts/cluster-web-interfaces).

### Options

There are various options for customizing your Jupyter installation. These can be provided as metadata keys using `--metadata`.

* `JUPYTER_PORT`=<integer>: Port on which the Jupyter server runs
* `JUPYTER_CONDA_PACKAGES`=<colon-separated list of strings>: List of Conda packages to install.
* `INIT_ACTIONS_REPO`=<https url>: Repo to clone to find other scripts to install/configure Conda and Jupyter.
* `INIT_ACTIONS_BRANCH`=<string>: Branch in `INIT_ACTIONS_REPO` to use.

For example to specify a different port and specify additional packages to install:

```bash
CLUSTER=<CLUSTER_NAME>
gcloud dataproc clusters create $CLUSTER \
    --metadata "JUPYTER_PORT=8124,JUPYTER_CONDA_PACKAGES=numpy:pandas:scikit-learn" \
    --initialization-actions gs://dataproc-initialization-actions/jupyter/jupyter.sh \
    --properties spark:spark.executorEnv.PYTHONHASHSEED=0,spark:spark.yarn.am.memory=1024m \
    --worker-machine-type=n1-standard-4 \
    --master-machine-type=n1-standard-4
```

Notebooks are stored and retrieved from the cluster staging bucket (Google Cloud Storage) at `gs://<staging-bucket>/notebooks/`. By default, clusters in your project in the same region use the same bucket. You can explicitly provide `--bucket=gs://<some-bucket>` to the same value to share notebooks between them.

## Internal details

### jupyter.sh

`jupyter.sh` handles configuring and running Jupyter on the Dataproc master node by doing the following:

- clones the dataproc-initialization-actions git repo/branch specified in the `INIT_ACTIONS_REPO` and `INIT_ACTIONS_BRANCH` metadata keys
  - if these two metadata keys are not set during cluster creation, the default values `https://github.com/GoogleCloudPlatform/dataproc-initialization-actions.git` and `master` are used
  - this is provided so that a fork/branch of the main repo can easily be used, eg, during development
- executes `conda/bootstrap-conda.sh` from said repo/branch to ensure `miniconda` is available
- executes `jupyter/internal/setup-jupyter-kernel.sh` and `jupyter/internal/launch-jupyter-kernel.sh` from said repo/branch
  - configures `jupyter` to use the *PySpark* kernel found at `jupyter/kernels/pyspark/kernel.json`
  - configures `jupyter` to listen on the port specified by the metadata key `JUPYTER_PORT`, with a default value of `8123`
  - configures `jupyter` to use auth token `JUPYTER_AUTH_TOKEN`, with a default of none.
      - Dataproc does not recommend opening firewall ports to access Jupyter, but rather using a proxy. See [connecting to web interfaces](https://cloud.google.com/dataproc/docs/concepts/cluster-web-interfaces)
      - This proxy access is automated by [launch-jupyter-interfaces.sh](#launch-jupyter-interfacesh).
  - loads and saves notebooks to `gs://$DATAPROC_BUCKET/notebooks/`, where `$DATAPROC_BUCKET` is the value stored in the metadata key `dataproc-bucket` (set by default upon cluster creation and overridable). Note that all clusters sharing a $DATAPROC_BUCKET will share notebooks.
  - launches the `jupyter notebook` process

**NOTE**: to be run as an init action.


### launch-jupyter-interface.sh

`launch-jupyter-interface.sh` launches a web interface to connect to Jupyter notebook process running on master node.

- sets a path for the local OS to the Chrome executable
- setup an ssh tunnel and socks proxy to the master node
- launch a Chrome instance that uses this ssh tunnel and references the Jupyter port.

**NOTE**: to be run from a local machine

## Important notes

* This initialization action clones this repo at `master` to run other scripts in the repo. If you plan to copy `jupyter.sh` to your own GCS bucket, you will also need to fork this repository and specify the metadata keys `INIT_ACTIONS_REPO` and `INIT_ACTIONS_BRANCH`.
* This initialization action runs the conda init action, which supports the metadata keys `CONDA_PACKAGES` and `PIP_PACKAGES`. You can also use these to install additional packages.


# [Downstream](https://github.com/amacfie/dataproc-initialization-actions/tree/master/jupyter) extras

[nbextensions](https://github.com/ipython-contrib/jupyter_contrib_nbextensions)
always included

[extension configurator](https://github.com/Jupyter-contrib/jupyter_nbextensions_configurator/)
included

These further options can be provided as metadata keys using `--metadata`.

* `VIM_EXTENSION`: set to nonempty string to include vim keybindings
* `R_KERNEL`: set to nonempty string to include R kernel for Jupyter
* `R_PACKAGES`: colon separated list of R packages to install from CRAN.

More important notes:

* Dataproc runs this from `/`
* Python and R packages are installed on all nodes

