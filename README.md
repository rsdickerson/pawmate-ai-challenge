# PawMate AI Challenge — Docs-Driven Benchmark Spec (Tool-Agnostic)

This repository is a **documentation-first benchmarking harness**: a technology-agnostic functional specification and operator templates used to evaluate AI coding tools in a **repeatable, evidence-based** way.

It is **not** an application implementation repo. It provides the *frozen spec inputs*, constraints, and record-keeping templates that benchmark operators use to run the same target through multiple tools and compare outcomes.

## Mission statement (benchmark intent)
PawMate is an ethical pet **adoption management** domain:
**Helping animals find homes—and people find friends**.

### Models (what “Model A / Model B” mean)
- **Model A (Minimum)**: baseline required capability set.
- **Model B (Full)**: **Model A + additional deltas** (e.g., auth/roles and search), as defined in `docs/Master_Functional_Spec.md`.

This benchmark spec intentionally includes **domain constraints that are mandatory and observable via the API** (these apply to the spec overall, for both **Model A** and **Model B**).
This includes:
- **Animal lifecycle state machine (enforced)**: animals are not products; status transitions are constrained and invalid transitions must be rejected.
- **Decision workflow (multi-step)**: adoption is **submit → evaluate → staff decision**, not “add to cart → checkout”.
- **Policy enforcement (explicit)**: the contract must define key policies (e.g., single vs multiple active applications) and enforce ethics constraints (e.g., protected-class non-discrimination inputs).
- **Decision transparency + auditability**: evaluations/decisions require **human-readable explanations** and actions must be recorded as **append-only history events**.

### Why this benchmark is non-trivial (high level)
- **API as system of record**: required behaviors must be observable via API operations and the contract artifact.
- **Enforced lifecycle + decisions**: state transitions and decision steps are constrained, validated, and auditable.
- **Determinism**: implementations must support reset-to-seed and deterministic collection ordering for repeatable runs.

## Quick Start (5 steps)

**Prerequisites:** Bash shell (macOS/Linux)

1. **Clone the repo** and open it in your AI coding tool:
   ```bash
   git clone https://github.com/rsdickerson/pawmate-ai-challenge.git
   cd pawmate-ai-challenge
   ```

2. **Pick a profile** (Model × API style):
   | Profile | Target Model | API Style |
   |---------|--------------|-----------|
   | `model-a-rest` | Model A (Minimum) | REST |
   | `model-a-graphql` | Model A (Minimum) | GraphQL |
   | `model-b-rest` | Model B (Full) | REST |
   | `model-b-graphql` | Model B (Full) | GraphQL |

3. **Generate your run folder and prompt**:
   ```bash
   ./scripts/initialize_run.sh --profile model-a-rest --tool "YourTool" --tool-ver "1.0"
   ```
   This creates `runs/YYYYMMDDTHHmm/` with:
   - `run.config` — your run parameters
   - `start_build_prompt.txt` — the prompt to paste into your AI tool
   - `PawMate/` — workspace folder for all generated code

4. **Open a new AI agent** and paste the contents of `start_build_prompt.txt` as the first message.

5. **Keep all artifacts** in `runs/.../PawMate/` for scoring.

That's it! The AI tool will generate the implementation. See the [Operator Guide](#operator-guide-step-by-step) below for verification and scoring.

---

## Core constraints (read this first)
The spec is designed to support reproducible benchmarking. Key constraints include:

- **Two selectable models**:
  - **Model A (Minimum)**: baseline capability set.
  - **Model B (Full)**: Model A plus additional requirements.
- **API-first**: the API is the **system of record**; any UI is optional and non-normative.
- **Choose exactly one API style**: **REST _or_ GraphQL** (do not implement both).
- **One contract artifact is required**:
  - REST: a machine-readable REST contract (e.g., OpenAPI)
  - GraphQL: a schema contract artifact
- **Determinism + reset-to-seed**: implementations must define a deterministic seed dataset and provide a **non-interactive reset-to-seed** mechanism suitable for repeated runs.
- **No external integrations**: do not require third-party services (including external storage/CDN, email/SMS, SSO providers, etc.).
- **No scope creep / overreach**: do not invent features beyond explicit `REQ-*` requirements; out-of-scope areas are labeled `NOR-*`.
- **Privacy is out of scope**: privacy requirements are explicitly non-goals for this benchmark.
- **Required tech stack**: to ensure reliable benchmarking, implementations **must** use the prescribed technology stack (see below).

## Required Tech Stack
To ensure consistent and comparable results across benchmark runs, all implementations **must** use the following technology stack:

- **Backend**: Node.js + Express
- **Database**: SQLite (file-based, no separate database server)
- **Frontend**: Vite + React + TypeScript
- **Project structure**: Frontend and backend are separate projects (separate folders with their own `package.json`)
- **No containerization**: No Docker or container orchestration
- **No external services**: No cloud services, external databases, or third-party APIs
- **Cross-platform**: The application must run on both macOS and Windows using only `npm install && npm run dev`

## Spec versioning
The spec uses **semantic versioning** with git tags for immutable references.

### Finding the current version
- **Root file**: `SPEC_VERSION` contains the canonical version string (e.g., `v1.0.0`).
- **Spec header**: The same version appears at the top of `docs/Master_Functional_Spec.md`.

### Citing a frozen spec reference
When running a benchmark, use the spec version tag as the **Frozen Spec Reference** (e.g., `v1.0.0`). This ensures reproducibility—anyone can check out that exact tag to see the spec you used.

### Releasing a new spec version
1. Edit the spec docs as needed.
2. Decide the next SemVer (`vMAJOR.MINOR.PATCH`).
3. Update `SPEC_VERSION` and the header in `docs/Master_Functional_Spec.md` to the new version.
4. Commit with a message like: `spec: bump to vX.Y.Z`.
5. Create an **annotated** git tag on that commit:
   ```bash
   git tag -a vX.Y.Z -m "Spec version vX.Y.Z"
   ```
6. Push the commit and tag:
   ```bash
   git push origin main --tags
   ```

### Verifying spec version consistency
Run the verification script to check that `SPEC_VERSION`, the spec doc, and the git tag are in sync:
```bash
./scripts/verify_spec_version.sh            # informational check
./scripts/verify_spec_version.sh --require-tag  # strict check (for releases/CI)
```

## Canonical docs (source of truth)
- `docs/Master_Functional_Spec.md` — the functional spec, requirement IDs (`REQ-*`), non-requirements (`NOR-*`), Model A/B.
- `docs/API_Contract.md` — contract artifact requirements (REST/GraphQL).
- `docs/UI_Requirements.md` — principles-based guidance for UI-API integration (contract-driven approach).
- `docs/Seed_Data.md` — deterministic seed dataset + reset-to-seed requirements.
- `docs/Image_Handling.md` — image handling constraints (if applicable to the selected model).
- `docs/Acceptance_Criteria.md` — acceptance criteria used to determine "feature complete".
- `docs/Benchmarking_Method.md` — benchmarking procedure + required artifacts + evidence-first scoring inputs.
- `docs/SANDBOX_SOLUTION.md` — guidance for handling sandbox restrictions during build (npm install).
- `docs/GRAPHQL_RESOLVER_PATTERN.md` — critical GraphQL resolver structure requirements for express-graphql + buildSchema.

## Operator Guide (step-by-step)
This repository does **not** ship an application. The "usable application" is created by the AI tool under test in your local workspace, along with the benchmark artifact bundle (contract + instructions + evidence).

> **TL;DR:** Use the [Quick Start](#quick-start-5-steps) above to generate your run folder and prompt, then follow these steps for verification and scoring.

### 0) Get the repository locally
```bash
git clone https://github.com/rsdickerson/pawmate-ai-challenge.git
cd pawmate-ai-challenge
```
Open the folder in your AI tool/IDE.

### 1) Generate a run folder
Use the run initializer to create a timestamped run folder with all config pre-filled:
```bash
./scripts/initialize_run.sh --profile model-a-rest --tool "YourTool" --tool-ver "1.0"
```

This creates:
- `runs/YYYYMMDDTHHmm/run.config` — run parameters
- `runs/YYYYMMDDTHHmm/start_build_prompt.txt` — the prompt to use
- `runs/YYYYMMDDTHHmm/PawMate/` — workspace for the implementation

### 2) Start the AI run
- Open a new AI agent/chat session.
- Copy the contents of `start_build_prompt.txt` and paste as the first message.
- The tool generates the implementation in the `PawMate/` workspace folder.

### 3) TTFR ("first runnable")
- Follow the tool's run instructions (copy/paste; non-interactive).
- TTFR ends when the system is runnable without operator code edits (see `docs/Benchmarking_Method.md`).

### 4) Determinism + acceptance (TTFC)
- Run reset-to-seed twice and verify golden checks in `docs/Seed_Data.md`.
- Run acceptance checks for the selected model and save pass/fail evidence (`docs/Acceptance_Criteria.md`).

### 5) Required artifacts to keep
All artifacts should be saved in the run folder (`runs/YYYYMMDDTHHmm/`):
- `run.config` — auto-generated by the initializer
- `start_build_prompt.txt` — auto-generated by the initializer
- Full tool transcript (save as `transcript.md` or similar)
- Run instructions (from the tool output)
- Contract artifact (OpenAPI or GraphQL schema)
- Acceptance checklist + evidence bundle
- Determinism evidence bundle
- Overreach notes/evidence

### 6) Scoring and comparison
- Score using `docs/Scoring_Rubric.md` (grounded in `docs/Benchmarking_Method.md` metrics/evidence).
- Compare tools using `docs/Comparison_Report_Template.md`.

## Repository note
- The **PawMate** canonical spec lives in `docs/` at the repository root.
