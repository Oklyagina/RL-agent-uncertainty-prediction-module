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

Run the existing Compose service again:

```
docker compose up
```

Use `--build` only when Docker-related files, `requirements.txt`, or project files that are copied into the image have changed:

```bash
docker compose up --build
```

If the previous container exists, Docker Compose will reuse the existing service definition, mounted folders, and named Grid2Op data volume. The container may be recreated when needed, but `docker-output/`, `docker-cache/`, and the `grid2op-data` volume are preserved.

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
- Permission errors in `docker-output` or `docker-cache`: remove the local mounted folder and let Docker recreate it, or fix ownership/permissions on the host.
- Grid2Op environment errors: keep the `grid2op-data` Docker volume so downloaded environment data persists across runs.
- Very slow startup: confirm `.env` still uses `CP_CONFIG=smoke` for validation.
