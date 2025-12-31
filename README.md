# PawMate AI Challenge — Operator Guide

This repository provides a **standardized benchmarking harness** for evaluating AI coding tools through a repeatable, evidence-based procedure. It contains the frozen specification, initialization scripts, and reporting templates needed to run benchmark experiments.

## What This Repository Is

This is an **operator's toolkit** for running AI benchmarking experiments:
- **Frozen specification** that AI tools build against
- **Initialization scripts** that create run folders and generate prompts
- **Reporting templates** for capturing results and evidence
- **Comparison framework** for evaluating different AI tools

This is **not** an application implementation. The AI tool you're testing will generate the PawMate application during the benchmark run.

## Operator Quick Start

### 1. Initialize a Benchmark Run

Choose your profile and create a run folder:

```bash
./scripts/initialize_run.sh --profile model-a-rest --tool "YourTool" --tool-ver "1.0"
```

This creates `runs/YYYYMMDDTHHmm/` with:
- `start_build_api_prompt.txt` — the prompt to paste into your AI tool to build the API/backend
- `start_build_ui_prompt.txt` — the prompt to paste into your AI tool to build the UI (optional)
- `run.config` — run metadata
- `PawMate/` — workspace for the AI-generated implementation

### 2. Submit the Prompt to Your AI Tool

1. Open a new agent session in your AI coding tool
2. Copy the **entire contents** of `start_build_api_prompt.txt`
3. Paste it as the first message
4. **Wait for the AI to complete all work** (see section below)

### 3. Monitor Progress and Track Operator Interventions

**CRITICAL FOR OPERATORS:**

AI tools may pause or stop before completing all required work. If your AI tool stops and the implementation is not 100% complete (code written, built, seeded, started, and all tests passing), you MUST send a message to continue:

```
continue
```

**Keep sending 'continue' until the AI reports:**
- ✅ All code is written
- ✅ Build completes successfully (`npm install` passes)
- ✅ Seed data is loaded and verified
- ✅ API server has started and responded to health check
- ✅ All tests are written and passing (100% pass rate)
- ✅ All benchmark artifacts are generated (contract, run instructions, acceptance checklist, AI run report)

**Do NOT accept partial completion.** The specification requires the AI to work autonomously until 100% complete. If it stops prematurely, prompt it to continue.

**Track Operator Interventions:**

The benchmark measures how well the AI creates the entire application from the initial prompts without operator assistance. You must track and record:

1. **Continuation prompts**: Count each time you send "continue" or similar messages because the AI stopped before completion
2. **Error message prompts**: Count each time you provide error messages or feedback to help the AI fix issues
3. **Clarifications**: Count each time the AI asks a question that requires your input
4. **Manual interventions**: Count each time you manually edit code, config, or files (this should be zero for a valid benchmark)

**Record these counts** in your run notes or in the AI run report. The result file generation script will include these metrics. **Ideal runs require zero operator interventions** — the AI should work autonomously from the initial prompts to completion.

### 4. Verify the Implementation

Once the AI reports completion:

```bash
cd runs/YYYYMMDDTHHmm/PawMate
./startup.sh  # Starts the API (and UI if built)
```

Access the API at: http://localhost:3000

### 5. Review Benchmark Artifacts

Check that all required artifacts were generated:
- `backend/openapi.yaml` (or GraphQL schema) — API contract
- `benchmark/run_instructions.md` — operator instructions
- `benchmark/acceptance_checklist.md` — acceptance criteria evidence
- `benchmark/ai_run_report.md` — timing and metrics
- Tests (in `backend/`) — automated test suite

### 6. Generate and Submit Results

```bash
# From the challenge repo root
./scripts/generate_result_file.sh --run-dir runs/YYYYMMDDTHHmm

# Review and validate
cd /path/to/pawmate-ai-results
./scripts/validate_result.sh results/submitted/your-result-file.json
```

See [`docs/Submitting_Results.md`](docs/Submitting_Results.md) for detailed submission instructions.

---

## About the PawMate Specification

The AI tool builds a pet adoption management application with:
- **Two model options**: Model A (Minimum) or Model B (Full with auth + search)
- **Two API styles**: REST or GraphQL
- **Enforced domain constraints**: Animal lifecycle state machine, auditable decision workflow, deterministic behavior
- **Required tech stack**: Node.js + Express + SQLite (backend), Vite + React + TypeScript (frontend)

The specification intentionally includes non-trivial requirements to differentiate AI capabilities:
- State machine enforcement and validation
- Multi-step decision workflow with explanations
- Deterministic ordering and reset-to-seed
- Comprehensive acceptance criteria

## Operator Prerequisites

Before running benchmarks, verify your environment:

```bash
# macOS / Linux
./scripts/verify_environment.sh

# Windows (PowerShell)
.\scripts\verify_environment.ps1
```

**Required tools:**
- **Node.js** version 18 or higher (for testing generated implementations)
- **npm** (comes with Node.js)
- **Bash shell** (macOS/Linux) or **PowerShell** (Windows)
- **Git** (optional but recommended)

**👉 Need installation help?** See [`docs/Setup_Instructions.md`](docs/Setup_Instructions.md) for platform-specific guides.

---

## Benchmark Profiles

Choose one profile per run (combines Model + API Style):

| Profile | Model | API Style | Description |
|---------|-------|-----------|-------------|
| `model-a-rest` | Minimum | REST | Baseline capabilities |
| `model-a-graphql` | Minimum | GraphQL | Baseline capabilities |
| `model-b-rest` | Full | REST | Adds auth + search |
| `model-b-graphql` | Full | GraphQL | Adds auth + search |

---

## Common Operator Issues

### AI Stops Before Completion

**Problem:** AI tool stops after writing code but before building, testing, or generating artifacts.

**Solution:** Send a simple message to continue:
```
continue
```

Keep sending `continue` until you see:
- ✅ `build_clean` timestamp recorded
- ✅ `seed_loaded` timestamp recorded  
- ✅ `app_started` timestamp recorded
- ✅ `all_tests_pass` timestamp recorded
- ✅ All benchmark artifacts generated

**Why this happens:** Some AI tools have safety limits or pause for confirmation. The spec requires autonomous completion, but operators must be prepared to prompt continuation.

### Determining If Build Is Complete

Check the AI run report (`PawMate/benchmark/ai_run_report.md`) for these required timestamps:

```yaml
generation_started: 2025-12-26T10:15:00.000Z
code_complete: 2025-12-26T10:25:00.000Z
build_clean: 2025-12-26T10:26:30.000Z
seed_loaded: 2025-12-26T10:27:00.000Z
app_started: 2025-12-26T10:27:15.000Z
all_tests_pass: 2025-12-26T10:32:45.000Z
```

**If any timestamp shows "Unknown" or is missing**, the build is incomplete. Send `continue`.

### Build or Test Failures

If the AI reports build errors or test failures:
1. **Do NOT manually fix code** — this counts as operator intervention
2. Send `continue` and let the AI fix its own errors
3. The AI should iterate until all tests pass
4. Record the number of test iterations in your run notes

---

## Key Documentation for Operators

### Workflow Guides
- [`QUICK_START_CHECKLIST.md`](QUICK_START_CHECKLIST.md) — step-by-step checklist for first run
- [`docs/Benchmarking_Method.md`](docs/Benchmarking_Method.md) — official benchmarking procedure
- [`docs/Submitting_Results.md`](docs/Submitting_Results.md) — how to submit benchmark results
- [`docs/Setup_Instructions.md`](docs/Setup_Instructions.md) — platform-specific installation guides

### Specification Documents (What AI Builds)
- [`docs/Master_Functional_Spec.md`](docs/Master_Functional_Spec.md) — complete functional requirements
- [`docs/API_Contract.md`](docs/API_Contract.md) — API contract requirements
- [`docs/Acceptance_Criteria.md`](docs/Acceptance_Criteria.md) — definition of "feature complete"
- [`docs/Seed_Data.md`](docs/Seed_Data.md) — deterministic seed dataset requirements

### Troubleshooting and Edge Cases
- [`docs/SANDBOX_SOLUTION.md`](docs/SANDBOX_SOLUTION.md) — handling sandbox restrictions during npm install
- [`docs/GRAPHQL_RESOLVER_PATTERN.md`](docs/GRAPHQL_RESOLVER_PATTERN.md) — GraphQL resolver requirements
- [`docs/Cross_Platform_Support.md`](docs/Cross_Platform_Support.md) — Windows/macOS/Linux compatibility

---

## Spec Versioning

The specification uses semantic versioning with git tags:
- **Current version**: See `SPEC_VERSION` file in repo root
- **Frozen reference**: Use git tags (e.g., `v2.0.0`) when citing the spec
- **Verify consistency**: Run `./scripts/verify_spec_version.sh`

When running a benchmark, record the spec version tag in your `run.config` to ensure reproducibility.

---

## Detailed Operator Workflow

### Step 1: Initialize a Run

   ```bash
./scripts/initialize_run.sh --profile model-a-rest --tool "Cursor" --tool-ver "0.43.6"
```

**What this does:**
- Creates timestamped folder: `runs/20251226T1500/`
- Generates `start_build_api_prompt.txt` with all parameters filled (required)
- Generates `start_build_ui_prompt.txt` with all parameters filled (optional — use after API is complete)
- Creates workspace: `runs/20251226T1500/PawMate/`
- Records run metadata in `run.config`

### Step 2: Submit Prompt to AI Tool

1. Open a **new agent session** in your AI tool
2. Copy **entire contents** of `start_build_api_prompt.txt`
3. Paste as the first message
4. **Do not interrupt** — let the AI work autonomously
5. **Track interventions** — count each time you need to send "continue" or provide error feedback

**Expected AI behavior:**
- Records `generation_started` timestamp immediately
- Writes all code files
- Runs `npm install` (requests network permissions if needed)
- Loads and verifies seed data
- Starts the API server
- Runs tests (iterates until all pass)
- Generates all benchmark artifacts
- Records completion timestamps

**Optional: Build UI**

After the API is complete, you can optionally build the UI:
1. Open a **new agent session** (or continue in the same session)
2. Copy **entire contents** of `start_build_ui_prompt.txt`
3. Paste as the first message
4. Track interventions as with the API build

### Step 3: Monitor and Continue If Needed

**Watch for completion indicators:**

✅ **Completed run** shows:
```
✓ All code written
✓ Build successful (npm install completed)
✓ Seed data loaded and verified
✓ API server started and responsive
✓ All tests passing (100% pass rate)
✓ Benchmark artifacts generated
```

⚠️ **Incomplete run** shows:
- Code written but no build attempt
- Build successful but no tests run
- Tests run but failures not fixed
- Missing timestamps in ai_run_report.md
- Missing benchmark artifacts

**If incomplete, send:**
```
continue
```

**Keep sending `continue` until the AI completes all work.** Do not manually edit code or fix errors — this corrupts the benchmark.

**Record intervention counts** for the result file:
- Number of "continue" prompts sent
- Number of error messages or feedback provided
- Number of clarifications answered
- Number of manual code edits (should be 0)

### Step 4: Verify Implementation

```bash
cd runs/20251226T1500/PawMate

# Check that services can start
./startup.sh

# Access the API
open http://localhost:3000
```

**Verify artifacts exist:**
- `backend/openapi.yaml` (or `backend/schema.graphql`)
- `benchmark/run_instructions.md`
- `benchmark/acceptance_checklist.md`
- `benchmark/ai_run_report.md`
- Tests in `backend/` (e.g., `backend/tests/` or `backend/src/**/*.test.js`)

### Step 5: Generate Result File

```bash
# From challenge repo root
./scripts/generate_result_file.sh --run-dir runs/20251226T1500
```

This extracts metrics from the AI run report and creates a standardized result file. **Before generating**, ensure you've recorded:
- Number of continuation prompts sent
- Number of error messages/feedback provided
- Number of clarifications answered
- Number of manual interventions (code edits, config changes, etc.)

The result file includes these metrics to measure how autonomously the AI completed the work from the initial prompts.

### Step 6: Validate and Submit (Optional)

```bash
# Copy to results repo
cp your-result-file.json /path/to/pawmate-ai-results/results/submitted/

# Validate
cd /path/to/pawmate-ai-results
./scripts/validate_result.sh results/submitted/your-result-file.json

# Submit via PR
git add results/submitted/your-result-file.json
git commit -m "Add benchmark result for Cursor model-a-rest"
git push origin main
```

See [`docs/Submitting_Results.md`](docs/Submitting_Results.md) for detailed submission instructions.

---

## Repository Structure

```
pawmate-ai-challenge/
├── docs/                      # Frozen specification documents
├── scripts/                   # Operator scripts (initialize, verify, generate results)
├── prompts/                   # Prompt templates (rendered by initialize_run.sh)
├── profiles/                  # Benchmark profiles (model + API style combinations)
├── runs/                      # Generated run folders (timestamped)
│   └── 20251226T1500/        # Example run folder
│       ├── run.config        # Run metadata
│       ├── start_build_api_prompt.txt  # Generated API prompt (required)
│       ├── start_build_ui_prompt.txt  # Generated UI prompt (optional)
│       └── PawMate/          # AI-generated implementation workspace
└── SPEC_VERSION              # Current specification version
```

---

## Support and Contributions

- **Issues**: Report problems or ask questions via GitHub Issues
- **Results**: Submit benchmark results via [`docs/Submitting_Results.md`](docs/Submitting_Results.md)
- **Spec improvements**: Propose changes via pull request (follows semver process)
