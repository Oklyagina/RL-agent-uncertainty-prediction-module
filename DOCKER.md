# Docker Usage

This wrapper runs the existing Grid2Op conformal-prediction project without requiring host Python, Conda, or project dependencies. Docker builds a Linux image, installs `requirements.txt` inside it, and runs the project from `src/`.

## First Run

Install Docker, then create a local environment file:

```bash
cp .env.example .env
```

In Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Start the smoke test:

```bash
docker compose up --build
```

The default `.env.example` uses `CP_CONFIG=smoke`, which is the recommended first run. The full configuration can be much slower and heavier.

## Reuse an Existing Docker Setup

After the image has been built once, you usually do not need to rebuild it.

Run the existing Compose service again in Windows PowerShell:

```powershell
docker compose up
```

Use `--build` only when Docker-related files, `requirements.txt`, or project files that are copied into the image have changed:

```powershell
docker compose up --build
```

If the previous container exists, Docker Compose will reuse the existing service definition, mounted folders, and named Grid2Op data volume. The container may be recreated when needed, but `docker-output/`, `docker-cache/`, and the `grid2op-data` volume are preserved.

To run a different configuration without editing `.env`, start a one-off Compose run:

```powershell
docker compose run --rm -e CP_CONFIG=full app python main.py --config full
```

To run the smoke test again:

```powershell
docker compose run --rm -e CP_CONFIG=smoke app python main.py --config smoke
```

`docker compose exec ...` sends a command into a container that is already running. This project is a batch simulation: it starts, runs one simulation, writes results, and exits. Because of that, `docker compose run --rm ...` is usually the right command when you want to run the project again with different settings.

## Change Forecasting Mode or Data

If the mode you need is already represented by `smoke` or `full`, use `CP_CONFIG` and `--config` as shown above.

If you need a different Grid2Op environment, agent, or forecaster, add or edit a Python configuration file first, then run Docker with that configuration. The environment, agent, model path, forecaster class, and forecaster path are application settings, so Docker should launch the chosen config rather than modify those values inside an already running process.

Keep these mounts active so repeated Docker runs reuse the same generated data:

- `/app/src/RESULTS` for result files
- `/app/src/CACHE` for calibration/model cache files
- `/home/appuser/data_grid2op` for downloaded Grid2Op environment data

## Outputs and Cache

Runtime files are written outside the image:

- `docker-output/` is mounted to `/app/src/RESULTS`
- `docker-cache/` is mounted to `/app/src/CACHE`
- the named Docker volume `grid2op-data` stores Grid2Op environment data under `/home/appuser/data_grid2op`

Logs are written to standard output and standard error:

```bash
docker compose logs -f
```

## Stop and Finish Working

If the simulation is currently running in the terminal, stop it gracefully with:

```text
Ctrl+C
```

Then stop and remove the Compose container/network:

```
docker compose down
```

This does not delete your generated results, cache folders, or the named `grid2op-data` volume.

Use this only when you intentionally want Docker to forget downloaded Grid2Op environment data:

```bash
docker compose down --volumes
```

Do not delete `docker-output/` unless you no longer need the generated results. Do not delete `docker-cache/` unless you want future runs to recompute cached calibration/model data.

## Full Experiment

Edit `.env`:

```env
CP_CONFIG=full
```

Then run:

```bash
docker compose up --build
```

You can also set the full configuration for one PowerShell session without editing `.env`:

```powershell
$env:CP_CONFIG = "full"
docker compose up --build
```

## Direct Docker Commands

Build the image:

```bash
docker build -t grid2op-cp .
```

Run the smoke configuration:

```bash
docker run --rm \
  --env CP_CONFIG=smoke \
  -v ./docker-output:/app/src/RESULTS \
  -v ./docker-cache:/app/src/CACHE \
  grid2op-cp
```

In Windows PowerShell, use backticks for line continuation:

```powershell
docker run --rm `
  --env CP_CONFIG=smoke `
  -v "${PWD}/docker-output:/app/src/RESULTS" `
  -v "${PWD}/docker-cache:/app/src/CACHE" `
  grid2op-cp
```

Run a clean no-cache build when validating reproducibility:

```bash
docker build --no-cache -t grid2op-cp:no-cache .
```

## Required Artifacts

The default smoke/full case-14 configuration expects these files to exist before the image is built:

- `HBGB_14.pkl`
- `curriculum_14/model/saved_model.pb`
- `curriculum_14/actions/actions.npy`

If the repository was cloned with Git LFS and model files are missing or tiny pointer files, run this on the host before building:

```bash
git lfs pull
```

The same command works in Windows PowerShell:

```powershell
git lfs pull
```

## Troubleshooting

- `Required artifact is missing`: fetch Git LFS files, then rebuild.
- `Unknown CP_CONFIG`: set `CP_CONFIG=smoke` or `CP_CONFIG=full`.
- `COPY docker/entrypoint.sh ... not found`: use the current `Dockerfile`, where the entrypoint is embedded during build. If you still see this error, the other machine has an older copy of the Docker files.
- Permission errors in `docker-output` or `docker-cache`: remove the local mounted folder and let Docker recreate it, or fix ownership/permissions on the host.
- Grid2Op environment errors: keep the `grid2op-data` Docker volume so downloaded environment data persists across runs.
- Very slow startup: confirm `.env` still uses `CP_CONFIG=smoke` for validation.
