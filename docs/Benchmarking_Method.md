# Benchmarking Method — Procedure + Required Artifacts

## Purpose
Define a **repeatable, tool-agnostic, operator-light** method to run the same frozen spec through multiple AI coding tools and collect **comparison-ready** evidence.

This document is designed to support benchmarking goals in:
- `docs/Master_Functional_Spec.md` (Model A/B, no overreach, assumptions)
- `docs/API_Contract.md` (contract artifact completeness + determinism)
- `docs/Seed_Data.md` (reset-to-seed + determinism checks)
- `docs/Acceptance_Criteria.md` (feature-complete definition via acceptance criteria)

## Scope + Constraints (Normative)
- **Tool-agnostic**: The procedure MUST work with any AI coding tool (IDE agent, CLI agent, web agent).
- **Prescribed tech stack**: All implementations MUST use the required technology stack (Node.js + Express + SQLite + Vite + React + TypeScript) as defined in `docs/Master_Functional_Spec.md`. The procedure itself does not assume details about these technologies (e.g., specific SQLite client libraries), but all benchmarked implementations must use the same stack for comparability.
- **Minimal human interaction**: The procedure MUST be executable largely via copy/paste + checklists; manual edits are tracked as "operator interventions".
- **No overreach**: Implementations MUST be evaluated against explicit `REQ-*` and `NOR-*` only; "extra features" are counted as overreach incidents.
- **Reproducibility**: Each tool MUST be run **twice** for the same benchmark target (same spec ref + model selection) to measure reproducibility.

## Definitions
- **Tool under test (TUT)**: The AI coding tool being benchmarked.
- **Run**: One end-to-end execution attempt by a TUT from prompt start through “stop condition”.
- **Rerun**: Restarting a run (or re-invoking generation) because of failures or to apply the same prompt again.
- **Operator intervention**: Any manual change beyond copy/paste execution of the TUT’s instructions (e.g., editing code, fixing configs, resolving conflicts).
- **Frozen spec reference**: A version identifier for the exact spec being used (e.g., git commit SHA, tag, or an immutable archive hash).
- **Contract artifact**: The implementation’s machine-readable API contract (OpenAPI or GraphQL schema) that satisfies `docs/API_Contract.md`.

## Benchmark Inputs (What the operator chooses and records)
For each benchmark, record these **before** starting any tool runs:
- **Spec reference**: frozen spec ref (commit/tag) + file list used (at minimum the `docs/` set).
- **Target model**: **Model A** or **Model B**.
- **Tool under test**: name + version/build identifier (as available).
- **Environment**: OS + CPU/arch + memory; workspace path; any required runtime versions (as available).

## Standardized Prompt Wrapper Requirement (Normative)
Each run MUST use a standardized wrapper that:
- **Declares the target model** (A or B) explicitly.
- **Pins the frozen spec reference** and states which files are in-scope inputs.
- **Declares run independence**: the tool MUST NOT reference, rely on, or mention previous runs, earlier chats, or other run folders.
- **Specifies the required tech stack**: the tool MUST use Node.js + Express + SQLite for backend, and Vite + React + TypeScript for frontend.
- **Restates the overreach guardrail**: do not implement beyond `REQ-*` and respect `NOR-*`.
- **Requires explicit assumptions** labeled `ASM-*` when the spec is ambiguous (default to the smallest compliant interpretation and proceed).
- **Requires zero operator interaction during generation**: the tool MUST NOT pause for confirmations or require the operator to type "continue" or approve changes mid-run.
- **Requires autonomous completion**: the tool MUST continue working until 100% complete (all code written, built, seeded, started, tested to 100% pass rate, and all artifacts generated). The tool MUST NOT stop after partial completion.
- **Requires a contract artifact** compliant with `docs/API_Contract.md`.
- **Requires reset-to-seed + determinism behavior** per `docs/Seed_Data.md` (including operator-friendly reset instructions).
- **Requires acceptance verification** against `docs/Acceptance_Criteria.md` for the selected model.
- **Requires operator run instructions** that are copy/paste friendly (no interactive prompts).
- **Requires automated test generation and execution**: the tool MUST generate tests, run them, iterate to fix failures, and continue until all tests pass (100% pass rate).

> Note: See `prompts/api_start_prompt_template.md` for the API start prompt template; this appendix defines the requirement that a wrapper exists and what it must contain. Use `./scripts/initialize_run.sh` to render the templates with run-specific values.

## Benchmark Run Procedure (Normative)
### 0) Initialize the benchmark record (operator)
Create a “Run Record” file (one per tool, per model) and fill the “Benchmark Inputs” above. Keep a single stopwatch/time source for the run.

### 1) Prepare a clean workspace state (operator)
The operator MUST ensure the starting state is clean and comparable across tools:
- No leftover build artifacts from prior runs.
- No leftover generated files from other tools.
- If the repo is under version control, the operator SHOULD start from a clean checkout at the frozen spec reference.

### 2) Start Run 1 for the tool under test (operator)
- Start the timer at the moment the standardized wrapper prompt is submitted to the TUT.
- Save the **exact prompt text** used (wrapper + any tool-specific boilerplate).

### 3) Capture clarifications and decisions (operator + tool)
During the run:
- Log each clarification question the tool asks (copy the question verbatim).
- Log each explicit assumption the tool makes (as `ASM-*`), if provided in its outputs.
- If the operator answers questions, record each answer verbatim.

> Benchmark expectation: A high-quality run should require **no clarifications**. Tools SHOULD default to `ASM-*` assumptions and proceed rather than blocking on operator input.

### 3.5) Monitor progress and send continuation prompts if needed (operator)
The standardized prompt requires the AI to work autonomously until 100% complete (all code written, built, seeded, started, tested to 100% pass rate, and all artifacts generated). However, some AI tools may stop prematurely due to safety limits or internal constraints.

**Operator procedure:**
1. **Monitor AI progress** for completion indicators:
   - All code files written
   - Build successful (`npm install` completed)
   - Seed data loaded and verified
   - API server started and responsive
   - All tests passing (100% pass rate)
   - All benchmark artifacts generated with complete timestamps

2. **If AI stops before 100% complete**, send a continuation prompt:
   ```
   continue
   ```

3. **Record each continuation prompt** sent:
   - Count: total number of `continue` messages sent
   - Context: what stage the AI had reached when it stopped (e.g., "stopped after writing code, before build")

4. **Keep sending `continue`** until the AI reaches 100% completion as defined above.

**Benchmark metric:** Record the number of continuation prompts required. This is a quality indicator:
- 0 continuations = ideal autonomous behavior
- 1-2 continuations = tool has stopping points but resumes well
- 3+ continuations = tool struggles with autonomous completion

**Important:** Continuation prompts are NOT counted as "clarifications" or "operator interventions" in the traditional sense, as they do not provide new information or fix code. They are a separate metric tracking the tool's autonomous completion capability.

### 4) Track reruns and interventions (operator)
If the tool’s output does not lead to a runnable system:
- Record each **rerun** attempt (what was re-issued and why).
- Record each **operator intervention** (what was changed, where, why).

### 5) Time-to-first-runnable (TTFR) measurement point (Normative)
**Stop the TTFR clock** at the earliest moment when BOTH are true:
- The tool has provided **complete run instructions** sufficient for an operator to start the system non-interactively (as applicable), and
- Following those instructions results in the system being **runnable** (i.e., the primary services/processes start successfully without operator code edits).

Notes:
- If the operator must modify code/config beyond copy/paste, TTFR continues until the system becomes runnable and the intervention is logged.
- If the implementation is API-only (no UI), “runnable” means the API process starts and serves requests.

### 6) Reset-to-seed + determinism readiness (Normative)
Before any “feature complete” claim, the operator MUST verify the implementation provides:
- A **non-interactive reset-to-seed** mechanism (API operation or local command) per `docs/Seed_Data.md`.
- Operator-visible **post-reset invariants** verification steps (golden records/determinism checks from `docs/Seed_Data.md`).

### 7) Time-to-feature-complete (TTFC) measurement point (Normative)
**Stop the TTFC clock** at the earliest moment when BOTH are true:
- The operator can execute reset-to-seed and run the acceptance checks for the selected model (`docs/Acceptance_Criteria.md`), and
- The implementation is **feature-complete** for the selected model, evidenced by passing the relevant acceptance criteria (or an operator checklist derived directly from `docs/Acceptance_Criteria.md`).

### 8) Complete Run 1 artifact capture (operator)
Collect and save the required artifacts listed below.

### 9) Repeat for Run 2 (reproducibility check) (Normative)
Repeat steps 1–8 for a **second run** of the same tool under test using:
- the same frozen spec reference,
- the same target model,
- the same standardized wrapper (except for run identifiers),
and record differences between Run 1 and Run 2 outputs and outcomes.

## Required Artifacts to Collect (Per tool, per run) (Normative)
Each run MUST produce the following, stored in a run folder (structure is implementer/operator choice, but MUST be complete):
- **Run record**: benchmark inputs, start/end timestamps, TTFR, TTFC, rerun count, intervention log.
- **Prompt wrapper**: the exact prompt text submitted to the tool.
- **Full tool transcript**: raw chat/log output from the tool (including clarifications and responses).
- **Generated run instructions**: "how to run", "how to reset-to-seed", "how to verify acceptance".
- **Run management scripts**: `startup.sh` and `shutdown.sh` in the root of the `PawMate/` folder per `docs/Master_Functional_Spec.md` REQ-OPS-0003-A through REQ-OPS-0007-A. These scripts MUST enable one-command startup and shutdown of all services.
- **AI run report** (tool-produced): `benchmark/ai_run_report.md` with tool-reported timestamps. If automated tests are run, the tool MUST have started the API/application successfully and recorded the corresponding "app started and responsive" timestamp before reporting any `tests_run_N` timestamp.
- **Contract artifact**: OpenAPI or GraphQL schema (and any required supporting files) meeting `docs/API_Contract.md`. The contract artifact is part of the application code (e.g., `PawMate/backend/src/schema.graphql` for GraphQL or `PawMate/backend/openapi.yaml` for REST) and should NOT be duplicated in the benchmark folder.
- **Acceptance evidence**:
  - model selected (A or B),
  - pass/fail results for `docs/Acceptance_Criteria.md` criteria (or a checklist mapping to them),
  - output logs or screenshots sufficient to verify the result.
- **Determinism evidence**:
  - reset-to-seed invocation (command/mutation) executed at least twice with identical post-reset outcomes,
  - verification of `docs/Seed_Data.md` golden items (e.g., key seeded animals/applications/history/images; Model B users/search if applicable).
- **Overreach evidence**:
  - any detected `NOR-*` violations or features beyond `REQ-*`,
  - notes on where the overreach appeared (files/behavior).

## Metrics catalog + evidence requirements
This section defines **required benchmark metrics** and the **evidence** needed to score them. Metrics MUST be recorded **per tool** and **per run** (Run 1 and Run 2), then summarized at the tool level.

#### Evidence rule (Normative)
For a metric value to be considered valid, the run folder MUST contain explicit evidence as described below. If evidence is missing, the metric MUST be recorded as **Unknown** (not guessed).

### Required Metrics (Normative)
Each run MUST record the following metrics.

#### M-01: Time-to-first-runnable (TTFR)
- **What it measures**: Elapsed time from submitting the prompt wrapper to the first successful “runnable” state (per §5).
- **How to measure**: Use a single time source; record start timestamp at prompt submit and end timestamp at first runnable.
- **Required evidence**:
  - the prompt wrapper text with a recorded submit timestamp
  - operator log of the exact run command(s) executed and the first successful start confirmation (log line, screenshot, or equivalent)
  - intervention log entries if any manual steps were required before first runnable

#### M-02: Time-to-feature-complete (TTFC)
- **What it measures**: Elapsed time from submitting the prompt wrapper to satisfying the “feature complete” stop condition (per §7).
- **How to measure**: Same as TTFR; end timestamp is when acceptance evidence confirms feature-complete.
- **Required evidence**:
  - acceptance evidence bundle (`docs/Acceptance_Criteria.md` mapping + pass/fail outputs)
  - determinism evidence bundle (`docs/Seed_Data.md` reset + golden checks)
  - operator log showing the timestamp when the final required evidence was produced

#### M-03: Clarifications requested
- **What it measures**: Count of tool questions that require operator input to proceed (excluding purely informational progress messages).
- **How to measure**: Count distinct clarification prompts from the tool transcript.
- **Required evidence**:
  - tool transcript excerpts showing each clarification question
  - operator responses (if provided) recorded verbatim in the run record

#### M-03.5: Continuation prompts required
- **What it measures**: Count of "continue" messages the operator had to send because the AI stopped before reaching 100% completion (all code written, built, seeded, started, tested to 100% pass rate, and all artifacts generated).
- **How to measure**: Count each time the operator sent a continuation prompt (typically the message "continue" or similar).
- **Required evidence**:
  - operator log or tool transcript showing each continuation prompt sent
  - context note for each continuation (e.g., "stopped after code generation, before build")
- **Quality indicator**: 
  - 0 = ideal autonomous completion
  - 1-2 = tool has stopping points but resumes well
  - 3+ = tool struggles with autonomous completion
- **Note**: Continuation prompts are distinct from clarifications (M-03) and interventions (M-04). They don't provide new information or fix code; they simply prompt the AI to resume work.

#### M-04: Operator interventions (manual edits)
- **What it measures**: Count of manual changes beyond copy/paste execution of tool-provided instructions.
- **How to measure**: Count each discrete intervention event (edit/add/delete/rename/config change) performed by the operator.
- **Required evidence**:
  - intervention log listing: timestamp, file/path affected, description, and reason
  - if under version control, a diff or patch is recommended (not required)

#### M-05: Reruns / regeneration attempts
- **What it measures**: Count of times the operator had to restart the tool run or re-trigger generation to make progress.
- **How to measure**: Count each rerun event and classify reason (build failure, missing instructions, failing acceptance, etc.).
- **Required evidence**:
  - run record entries for each rerun with reason
  - tool transcript showing the rerun trigger (e.g., “try again”, “regenerate”, new session)

#### M-06: Acceptance pass rate (Model A or Model B)
- **What it measures**: Correctness against `docs/Acceptance_Criteria.md` for the selected model.
- **How to measure**:
  - Create an "Acceptance Checklist" derived directly from `docs/Acceptance_Criteria.md` for the selected model.
  - Record each criterion as Pass/Fail/Not-Run with notes and evidence references.
  - Compute pass rate as: \( \text{PassRate} = \frac{\#Pass}{\#Pass + \#Fail} \) (exclude Not-Run).
- **Required evidence**:
  - completed checklist mapping each checked item to its `AC-*` ID
  - API outputs/logs/screenshots sufficient to verify each pass/fail outcome

#### M-06a: Test run iterations
- **What it measures**: Number of times automated tests were run before all tests passed.
- **How to measure**:
  - Track each test run iteration with begin/end timestamps
  - Record pass rate for each iteration
  - Count total iterations until all tests pass
- **Required evidence**:
  - AI run report with `test_run_N_start`, `test_run_N_end`, and results for each iteration
  - Final `test_iterations_count` value

#### M-07: Overreach incidents (violations of `NOR-*` or beyond `REQ-*`)
- **What it measures**: Scope control and spec adherence (no extra features).
- **How to measure**: Count each distinct overreach incident as one item; record which `NOR-*` or which “not required by REQ-*” area it violates.
- **Required evidence**:
  - evidence of the behavior/feature (docs, endpoints, UI, config, code reference)
  - justification mapping to the violated `NOR-*` item or the absence of a supporting `REQ-*`

#### M-08: Reproducibility (Run 1 vs Run 2)
- **What it measures**: Stability of outputs and outcomes across two runs for the same tool/model/spec ref.
- **How to measure**:
  - Compare Run 1 vs Run 2 for: TTFR, TTFC, acceptance pass/fail, determinism checks, and required artifacts presence.
  - Record differences as “None / Minor / Major” with a short explanation.
- **Required evidence**:
  - both run folders with complete artifacts
  - a run-comparison note listing observed differences and pointers to evidence

#### M-09: Determinism compliance (seed + reset)
- **What it measures**: Conformance to `docs/Seed_Data.md` reset-to-seed and post-reset invariants, and `docs/API_Contract.md` ordering determinism declarations.
- **How to measure**:
  - Execute reset-to-seed twice and verify identical post-reset outcomes.
  - Verify `docs/Seed_Data.md` golden items for the selected model (and contract-declared deterministic ordering rules for collections).
- **Required evidence**:
  - reset-to-seed invocation record (commands/mutations) executed twice
  - captured outputs of golden checks (e.g., seeded animals/applications/history/images; Model B users/search if applicable)
  - contract artifact section(s) showing deterministic ordering + tie-break rules for collections

#### M-10: Contract artifact completeness
- **What it measures**: Whether the contract artifact is benchmark-ready per `docs/API_Contract.md` (operations, schemas, errors, pagination, determinism).
- **How to measure**: Use a “Contract Completeness Checklist” derived from `docs/API_Contract.md` and mark each item Pass/Fail/Unknown.
- **Required evidence**:
  - the contract artifact file(s)
  - a completed contract checklist referencing `docs/API_Contract.md`

#### M-11: Operator run-instructions quality (documentation quality)
- **What it measures**: Whether the tool’s run instructions enable minimal human interaction.
- **How to measure**: Evaluate instructions against the requirement that an operator can copy/paste to: run, reset-to-seed, and verify acceptance.
- **Required evidence**:
  - the run instructions as produced by the tool
  - notes on any missing steps, ambiguities, or interactive prompts encountered

#### M-11a: LLM Usage Tracking
- **What it measures**: Model used, token usage, request counts, and estimated costs for the LLM used during implementation.
- **How to measure**:
  - **Backend/API run**: Record `backend_model_used`, `backend_requests`, `backend_tokens`
  - **UI run** (if applicable): Record `ui_model_used`, `ui_requests`, `ui_tokens`
  - Record estimated cost (if available)
  - Note usage source: `tool_reported`, `operator_estimated`, or `unknown`
- **Required fields**:
  - `backend_model_used`: Model name and version (e.g., "claude-sonnet-4.5", "gpt-4-turbo")
  - `backend_requests`: Total number of LLM API requests for backend
  - `backend_tokens`: Total tokens used for backend (input + output combined)
  - `ui_model_used`: Model name and version for UI (if UI was implemented)
  - `ui_requests`: Total number of LLM API requests for UI
  - `ui_tokens`: Total tokens used for UI (input + output combined)
- **Required evidence**:
  - LLM usage metrics in AI run report and UI run summary (if tool provides them)
  - Operator notes on how usage was determined (if manually calculated)
- **Note**: This metric is optional but encouraged. Operators should check their plan usage before and after runs to determine actual costs.

#### Metric Recording Minimums (Normative)
- Every run record MUST include M-01..M-11, M-06a (test iterations), and M-11a (LLM usage, if available).
- If a metric cannot be measured, record **Unknown** and explain what evidence was missing.

### Overall scoring formula + comparison table schema
This document intentionally matches the scoring model defined in the reference Pet Store harness; the PawMate domain changes should affect scores via correctness/determinism/ethics, not via tooling changes.


