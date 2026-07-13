# Conformal Prediction for Grid2Op

## Clone the repository

`git-lfs` needs to be installed to download the `.pkl` models:

```sh
brew install git-lfs          # macOS (using brew)
sudo pacman -S git-lfs        # Arch
sudo dnf install git-lfs      # Fedora
sudo apt-get install git-lfs  # Ubuntu
```

Initialize git-lfs:

```sh
git lfs install
```

Then clone the repository.

## Creating a python environment

First install conda/miniconda

To install miniconda: [Miniconda Quickstart Install](https://www.anaconda.com/docs/getting-started/miniconda/install#quickstart-install-instructions)

### Create a conda environment

```sh
conda create -n Grid2Op_CP python=3.11.13
```

### Activate the conda environment

```sh
conda activate Grid2Op_CP
```

### Install the dependencies

```sh
pip install -r requirements.txt
```

## Understanding the structure

The framework is implemented inside [src](./src/)
and is divided into three main folders:

The [root folder](./src/) which contains the main pipeline, and all the code.

The [utils folder](./src/utils) which contains the utilities used by the pipeline.

The [plotting folder](./src/plotting/) which contains all the utilities related to plotting.

and the two folders that contain the models in:

The [conformal models folder](./src/conformalized_models/) contains the code for the conformalized models
New conformal models must be added to this directory

The [stl rules folder](./src/stl_rules/) contains the code for the implemented STL rule.
New stl rules must be added to this directory.

Important - The STL rules assume we are checking if a trajectory is safe/unsafe.
If we are trying to predict something else, it might not work to just create a rule
in the rules folder, and the structure must be refactored.

For more information, consult each folders README.

## A first experiment

With the conda environment activated, we can move to the [src](./src/) folder.

The default command uses the full configuration from [config_full.py](./src/config_full.py):

```sh
python main.py
```

For a quick end-to-end smoke test, use [config_smoke.py](./src/config_smoke.py):

```sh
python main.py --config smoke
```

You can also select the smoke configuration with an environment variable:

```sh
CP_CONFIG=smoke python main.py
```

In PowerShell, use:

```powershell
$env:CP_CONFIG = "smoke"
python main.py
```

Both configuration files are plain Python. Paths such as `OUTPUT_DIR`, `MODEL_PATH`, and
`FORECASTER_PATH` are resolved relative to the `src` configuration directory.

If needed, change parameters such as `CALIB_EPISODES`, `TEST_EPISODES`, and `OUTPUT_DIR`
in the selected configuration file, then start the simulation by running:

```sh
python main.py
```
