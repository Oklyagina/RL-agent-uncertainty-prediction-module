# Conformal Prediction for Grid2Op

This project runs conformal-prediction simulations for Grid2Op power-grid environments. The recommended way to run it is with Docker, because Docker installs the Python dependencies inside a reproducible Linux image and keeps generated results outside the image.

## Running Project With Docker

### Prerequisites

Install Docker Desktop from the official Docker website:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

On Windows, make sure the `C:` drive has at least 10 GB of free space for the Docker image, build cache, and app runtime data.

Install Git LFS before building the Docker image. Git LFS is required because the `.pkl` model files are stored as large files:

```powershell
winget install GitHub.GitLFS
git lfs install
git lfs pull
```

On Windows, you can also download the installer from the [Git LFS website](https://git-lfs.com/).

`HBGB_14.pkl` is stored with Git LFS. If Git LFS files are not pulled, the repository contains only a tiny pointer file, and Docker will copy that pointer into the image instead of the real model. If you run `git lfs pull` after a failed Docker build, rebuild the image.

### First Docker Run

Create a local environment file:

```bash
cp .env.example .env
```

In Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Start the smoke test:

```powershell
docker compose up --build
```

The default `.env.example` uses `CP_CONFIG=smoke`, which is the recommended first run. The full configuration can be much slower and heavier.

### Reuse an Existing Docker Setup

After the image has been built once, you usually do not need to rebuild it.

Run the existing Compose service again:

```powershell
docker compose up
```

Use `--build` only when Docker-related files, `requirements.txt`, or project files copied into the image have changed:

```powershell
docker compose up --build
```

To run a different configuration without editing `.env`, start a one-off Compose run:

```powershell
docker compose run --rm -e CP_CONFIG=full app python main.py --config full
```

To run the smoke test again:

```powershell
docker compose run --rm -e CP_CONFIG=smoke app python main.py --config smoke
```

`docker compose exec ...` sends a command into a container that is already running. This project is a batch simulation: it starts, runs one simulation, writes results, and exits. Because of that, `docker compose run --rm ...` is usually the right command when you want to run the project again with different settings.

### Change Forecasting Mode Or Data

If the mode you need is already represented by `smoke` or `full`, use `CP_CONFIG` and `--config` as shown above.

If you need a different Grid2Op environment, agent, or forecaster, add or edit a Python configuration file first, then run Docker with that configuration. The environment, agent, model path, forecaster class, and forecaster path are application settings, so Docker should launch the chosen config rather than modify those values inside an already running process.

### Docker Outputs And Cache

Runtime files are written outside the image:

- `docker-output/` is mounted to `/app/src/RESULTS`
- `docker-cache/` is mounted to `/app/src/CACHE`
- the named Docker volume `grid2op-data` stores Grid2Op environment data under `/home/appuser/data_grid2op`

Logs are written to standard output and standard error:

```powershell
docker compose logs -f
```

### Stop And Finish Docker Work

If the simulation is currently running in the terminal, stop it gracefully with:

```text
Ctrl+C
```

Then stop and remove the Compose container/network:

```powershell
docker compose down
```

This does not delete generated results, cache folders, or the named `grid2op-data` volume.

Use this only when you intentionally want Docker to forget downloaded Grid2Op environment data:

```powershell
docker compose down --volumes
```

Do not delete `docker-output/` unless you no longer need the generated results. Do not delete `docker-cache/` unless you want future runs to recompute cached calibration/model data.

### Full Docker Experiment

Edit `.env`:

```env
CP_CONFIG=full
```

Then run:

```powershell
docker compose up --build
```

You can also set the full configuration for one PowerShell session without editing `.env`:

```powershell
$env:CP_CONFIG = "full"
docker compose up --build
```

### Docker Required Artifacts

The default smoke/full case-14 configuration expects these files to exist before the image is built:

- `HBGB_14.pkl`
- `curriculum_14/model/saved_model.pb`
- `curriculum_14/actions/actions.npy`

If model files are missing or tiny pointer files, run this on the host before building:

```powershell
git lfs install
git lfs pull
```

After fetching Git LFS files, rebuild the Docker image:

```powershell
docker compose up --build
```

### Docker Troubleshooting

- `Required artifact is missing`: fetch Git LFS files, then rebuild.
- `HBGB_14.pkl appears to be a Git LFS pointer`: run `git lfs install`, `git lfs pull`, `docker compose down`, then `docker compose up --build`.
- `Unknown CP_CONFIG`: set `CP_CONFIG=smoke` or `CP_CONFIG=full`.
- `read-only file system` while Docker is committing a build layer: check free space on the Windows `C:` drive. Docker Desktop stores its image/build data there by default and this project needs at least 10 GB free for the image and app data together.
- Permission errors in `docker-output` or `docker-cache`: remove the local mounted folder and let Docker recreate it, or fix ownership/permissions on the host.
- Grid2Op environment errors: keep the `grid2op-data` Docker volume so downloaded environment data persists across runs.
- Very slow startup: confirm `.env` still uses `CP_CONFIG=smoke` for validation.

## Running Project Using Conda (without Docker)

Use this path only if you want to run the project directly on the host machine.

### Clone And Fetch Model Files

Install Git LFS to download the `.pkl` models:

```sh
brew install git-lfs          # macOS (using brew)
sudo pacman -S git-lfs        # Arch
sudo dnf install git-lfs      # Fedora
sudo apt-get install git-lfs  # Ubuntu
winget install GitHub.GitLFS  # Windows PowerShell
```

Initialize Git LFS:

```sh
git lfs install
git lfs pull
```

### Create A Conda Environment

Install Conda or Miniconda first:

- [Miniconda Quickstart Install](https://www.anaconda.com/docs/getting-started/miniconda/install#quickstart-install-instructions)

Create the environment:

```sh
conda create -n Grid2Op_CP python=3.11.13
```

Activate the environment:

```sh
conda activate Grid2Op_CP
```

Install the dependencies:

```sh
pip install -r requirements.txt
```

### Run A Local Experiment

Move to the `src/` folder:

```sh
cd src
```

The default command uses the full configuration from `src/config_full.py`:

```sh
python main.py
```

For a quick end-to-end smoke test, use `src/config_smoke.py`:

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

Both configuration files are plain Python. Paths such as `OUTPUT_DIR`, `MODEL_PATH`, and `FORECASTER_PATH` are resolved relative to the `src` configuration directory.

If needed, change parameters such as `CALIB_EPISODES`, `TEST_EPISODES`, and `OUTPUT_DIR` in the selected configuration file, then start the simulation again.

## Project Structure

The framework is implemented inside `src/`.

- `src/` contains the main pipeline and application code.
- `src/utils/` contains utilities used by the pipeline.
- `src/plotting/` contains plotting utilities.
- `src/conformalized_models/` contains conformalized model implementations.
- `src/stl_rules/` contains implemented STL rules.

New conformal models should be added to `src/conformalized_models/`. New STL rules should be added to `src/stl_rules/`.

The STL rules assume the project is checking whether a trajectory is safe or unsafe. If the project needs to predict something else, the rule structure may need to be refactored.
