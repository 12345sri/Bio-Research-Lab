# BioAI Research Lab

Explainable and reproducible AI infrastructure for biomedical research.

- **Founder:** Tanjidul Huda (Founder / Research Lead)
- **Co-Founder:** Sriporna Biswas Srima (Co-Founder / Research & Development)

| Platform | Focus |
|---|---|
| **BioSignal AI** | ECG, RR intervals, HRV, workload and recovery research, condition comparisons |
| **BioOmics AI** | Gene expression, multi-omics, leakage-safe ML, SHAP, gene networks, pathways, external validation |

> **Research tool only.** Not a medical device. It does not diagnose disease, predict disease for
> individual patients, or recommend treatment. See `docs/scientific-rules.md`.

## Quick start: local mode (one command, no Docker)

```bash
python3 run_local.py
```

Opens http://127.0.0.1:8765. Needs Python 3.10+; on first run it installs any missing required packages
(numpy, scipy, pandas, scikit-learn, networkx, matplotlib, reportlab) with pip. No Docker, PostgreSQL, Redis,
MinIO or Node.js is needed: the frontend is prebuilt in `frontend/dist-local/`. Data is kept in `./local-data`.

- Click **Explore the live demo** to open a project of synthetic DEMONSTRATION DATA that is analysed
  automatically on first start (about a minute).
- Local mode uses SQLite, a local file store and a background worker thread, with the same `/api/v1` contract,
  scientific engines, guard constraints and append-only audit log as the Docker stack.
- XGBoost and tree/kernel SHAP run only if `xgboost` / `shap` are installed; otherwise they are reported as
  "not run" (permutation importance is shown instead, and labelled as such).
- Options: `--port`, `--data`, `--no-demo`, `--no-browser`, `--rebuild-frontend` (needs Node.js).
- Tests: `python3 scripts/run_science_tests.py` (includes local-mode API tests);
  browser checks with a running site: `python3 e2e/local/walk_all_pages.py` and `python3 e2e/local/researcher_journey.py`.

## Public deployment

See `DEPLOY.md` (Render blueprint included: New > Blueprint > this repository).

## Full stack (Docker)

## 1. Prerequisites
- Docker Engine 24+ with Docker Compose v2
- About 6 GB free disk space (images for PostgreSQL, Redis, MinIO, Python scientific stack, Node)
- Python 3.10+ on the host only if you run `scripts/verify_all.sh` or the offline test runner

## 2. Installation
```bash
git clone <repository> bioai-research-lab && cd bioai-research-lab
```
All application dependencies install inside the Docker images during the first build.

## 3. Environment setup
```bash
cp .env.example .env
```
The defaults are for local development. Replace every `change-me` value, and generate `SECRET_KEY` with
`python3 -c "import secrets; print(secrets.token_urlsafe(48))"`, before the machine is reachable by anyone else.
`ENVIRONMENT=development` shows email-verification and password-reset links on screen because no mail server
is configured; set `ENVIRONMENT=production` to hide them.

## 4. Database setup
Automatic. On start the backend container generates the initial migration if absent, runs
`alembic upgrade head` (including the append-only audit-log trigger) and seeds the organization and roles.

## 5. Start
```bash
docker compose up --build
```

## 6-8. URLs
- Frontend: http://localhost:3000
- Backend: http://localhost:8000
- API docs (OpenAPI): http://localhost:8000/api/v1/docs

## 9. Demo account
With `LOAD_DEMO=true` (the default in `.env.example`) a DEMONSTRATION project on synthetic data is created
for `demo@bioai.local` / `Demo-Research-2026`. Its two analyses run in the background for a few minutes after
startup; `docker compose exec backend python -m app.cli status` shows progress.

Founder accounts are created explicitly (password taken from the environment, never the command line):
```bash
docker compose exec -e BIOAI_NEW_PASSWORD='<strong password>' backend \
  python -m app.cli create-user tanjidul@example.org FOUNDER "Tanjidul Huda"
```

## 10. Tests
```bash
python3 scripts/run_science_tests.py        # scientific engines + security primitives, no services needed
python3 scripts/check_api_contract.py       # every frontend API call matches a backend route and method
docker compose exec -e TEST_DATABASE_URL=... -e REQUIRE_DB=1 backend pytest -q   # full backend suite
```

## 11. Full verification
```bash
./scripts/verify_all.sh    # stack up, migrations, backend suite on PostgreSQL, XGBoost/SHAP, Playwright E2E
```
Output is saved to `docs/verification.log`.

## 12. Known limitations
- **Docker stack not yet executed:** the PostgreSQL migrations and tests, FastAPI API tests, Next.js build and
  Playwright tests of the Docker version have not run in the build environment (no Docker or package
  downloads there). Local mode has been run and tested end to end; see `docs/progress.md`.
- XGBoost and tree/kernel SHAP are exercised only when those libraries are installed (they are, in the image).
- No email delivery; tokens are shown on screen in development mode.
- Access tokens cannot be revoked before expiry (30 minutes); signing out clears them in the browser.
- The copilot answers with a language model only when `ANTHROPIC_API_KEY` is set; otherwise it shows the
  recorded evidence and the automated review. Model answers containing numbers or claims absent from the
  evidence are withheld.
- Differential expression uses Welch/Mann-Whitney tests on log-scale data, not count models (DESeq2/edgeR).
- Pathway enrichment needs a gene-set (GMT) file supplied by the researcher; KEGG files are not bundled.

## Repository layout

```
backend/            FastAPI, SQLAlchemy, Celery worker
  app/core          settings, security
  app/db            engine, session, migrations
  app/models        SQLAlchemy tables
  app/schemas       Pydantic request/response models
  app/api/v1        REST routers (/auth, /projects, /datasets, ...)
  app/services      business logic, permissions, audit logging
  app/workers       background analysis jobs
  app/science       scientific engines (pure functions, tested independently)
    biosignal       QC, preprocessing, HRV
    omics           expression QC, orientation, feature selection
    stats           tests, effect sizes, confidence intervals
    ml              leak-free pipelines, cross-validation
    explain         SHAP
    network         correlation networks, centrality
    pathway         enrichment with multiple-testing correction
    validation      external validation, calibration
    copilot         evidence-labelled research assistant
    reports         report generation and export
  demo_data         SYNTHETIC datasets only, clearly labelled
  tests             unit, integration, api, science, security
frontend/           Next.js, TypeScript, Tailwind
docs/               architecture, scientific rules, progress log
scripts/            verification and maintenance scripts
```

