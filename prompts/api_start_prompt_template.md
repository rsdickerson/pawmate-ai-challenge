## API Start Prompt (Template)

> **Recommended:** Use the prompt renderer to generate a pre-filled version of this template:
> ```bash
> ./scripts/initialize_run.sh --profile model-a-rest --tool "YourTool" --tool-ver "1.0"
> ```
> This auto-creates a run folder, fills all header fields, and checks the correct model/API checkboxes.

> **Manual instructions:** If not using the renderer, copy/paste this entire template into the Tool Under Test (TUT) as the first message for a benchmark run. Fill only the bracketed fields. Do not add additional requirements not present in the frozen spec.

---

### 0) Benchmark Header (Operator fills)
- **Tool Under Test (TUT)**: [Tool name + version/build id]
- **Run ID**: [e.g., ToolX-ModelA-Run1]
- **Frozen Spec Reference**: [commit/tag/hash or immutable archive id]
- **Spec Root**: [repo-root-path]
- **Workspace Path**: [workspace-path]
- **Target Model (choose exactly one)**:
  - [ ] **Model A (Minimum)**
  - [ ] **Model B (Full)**
- **API Style (choose exactly one; DO NOT implement both)**:
  - [ ] **REST** (produce an OpenAPI contract artifact)
  - [ ] **GraphQL** (produce a GraphQL schema contract artifact)

---

### 1) Role + Objective (Tool must follow)
You are an implementation agent for a reproducible benchmarking run. Your objective is to produce a complete implementation that satisfies the frozen spec **for the selected Target Model** and to generate a benchmark-ready artifact bundle (run instructions, contract artifact, acceptance and determinism evidence pointers).

**⏱️ FIRST ACTION — Record Start Time:**
Before doing anything else, record the current timestamp in **ISO-8601 UTC with milliseconds** (e.g., `YYYY-MM-DDTHH:MM:SS.sssZ`) as `generation_started`. Output it immediately in your first response, like this:

```
generation_started: 2024-12-17T10:00:00.000Z
```

This timestamp is critical for benchmarking and MUST be recorded before any code generation begins.

---

### 1.0) Run Independence — No Cross-Run References (MUST)
This run MUST be treated as fully independent:
- You MUST NOT reference, rely on, or mention any previous runs, prior attempts, earlier chats, or other run folders.
- You MUST treat this prompt and the frozen spec files as the complete context for this run.
- If you encounter existing files under the **Workspace Path**, treat them as the current run's workspace state only; do not assume they were produced by a prior run unless explicitly stated in the prompt.

**IMPORTANT — File locations:**
- **Read spec files from:** the **Spec Root** path (frozen spec docs live there under `docs/`)
- **Write ALL generated files to:** the **Workspace Path** (all code, configs, artifacts, and outputs MUST be created inside this folder)

**CRITICAL — Workspace layout:**
- Place backend/API code under: `{Workspace Path}/backend/`
- Reserve `{Workspace Path}/ui/` for UI (generated separately via the UI start prompt)
- Place benchmark artifacts under: `{Workspace Path}/benchmark/`

You MUST work strictly within scope and MUST NOT invent requirements. If something is ambiguous, you MUST record the smallest compliant assumption as an explicit `ASM-####` and proceed.

---

### 1.1) Timing Integrity — No Confirmation Pauses (MUST)
**CRITICAL FOR BENCHMARKING:** To ensure accurate timing measurements:
- You MUST NOT pause to ask "should I create this file?" or similar confirmations.
- You MUST write files immediately without waiting for human approval.
- You MUST proceed continuously through implementation without unnecessary stops.
- You MUST NOT pause and request operator input (e.g., “click Keep All”, “confirm”, “type continue”). Assume the operator is **not available**.
- If a requirement is ambiguous, default to the **smallest reasonable compliant** interpretation, label it `ASM-####`, and keep going.

Pausing for file-creation confirmations corrupts the timing measurements that compare tools.

---

### 2) In-Scope Inputs (Frozen Spec Files)
You MUST treat the following files (located under the **Spec Root**) as the sole source of truth and keep them consistent:
- `{Spec Root}/docs/Master_Functional_Spec.md`
- `{Spec Root}/docs/API_Contract.md`
- `{Spec Root}/docs/UI_Requirements.md` **← Review for API endpoint patterns expected by UI clients**
- `{Spec Root}/docs/Seed_Data.md`
- `{Spec Root}/docs/Image_Handling.md`
- `{Spec Root}/docs/Acceptance_Criteria.md`
- `{Spec Root}/docs/Benchmarking_Method.md`
- `{Spec Root}/docs/SANDBOX_SOLUTION.md` **← Required for handling sandbox restrictions during build**

If any behavior is not required by a `REQ-*` item, it is out of scope unless explicitly allowed by `MAY`.

**NOTE:** `UI_Requirements.md` documents the expected API contract from a UI client perspective. While implementing the API, ensure your endpoint patterns, field names, and parameter placements match what UI clients will expect. This ensures future UI implementations integrate smoothly.

**NOTE:** `SANDBOX_SOLUTION.md` provides critical guidance for executing the build loop (npm install) within sandbox environments. You MUST reference this document if you encounter network access restrictions during the build step.

---

### 3) Hard Guardrails (MUST)

#### 3.0 Required Tech Stack (MUST)
To ensure reliable and comparable benchmarking results, you MUST use the following technology stack:

- **Backend**: Node.js + Express
- **Database**: SQLite (file-based, no separate database server required)
- **Project structure**: Backend as a separate project with its own `package.json`
- **No Docker**: Do not use Docker or any containerization
- **No external services**: No cloud services, external databases, or third-party APIs
- **Cross-platform**: The implementation MUST run on both macOS and Windows using only `npm install && npm run dev`

**CRITICAL:** You MUST NOT use any other backend framework (e.g., NestJS, Fastify, Koa), runtime (e.g., Deno, Bun), or database (e.g., PostgreSQL, MySQL, MongoDB). Stick to the prescribed stack exactly.

**CRITICAL — Sandbox Environment Compatibility:**
- You MUST create a `.npmrc` file in the backend directory with sandbox-friendly settings:
  - `cache=.npm-cache` (use local cache directory within workspace)
  - `audit=false` (skip audit to avoid network requirements)
  - `fund=false` (skip funding messages)
  - `prefer-offline=true` (prefer offline mode)
- All npm commands MUST work non-interactively in restricted environments
- You MUST NOT create shell scripts for workflow execution (the AI tool executes commands directly via `run_terminal_cmd`)
- All commands MUST be executable directly via terminal without manual intervention

**CRITICAL — Package.json Scripts:**
- You MUST include a `"stop"` script in package.json to stop the server:
  - `"stop": "pkill -f 'node src/server.js' || true"`
- This provides a convenient way for operators to stop the server after testing

**CRITICAL — Network Access for npm install:**
- The `npm install` step requires network access to download dependencies
- If you encounter sandbox network restrictions, you MUST request network permissions using `required_permissions: ['network']`
- See `docs/SANDBOX_SOLUTION.md` for detailed guidance on handling sandbox restrictions during the build loop
- The build loop MUST complete successfully before proceeding to seed, start, or test steps

**CRITICAL — GraphQL Implementation (If GraphQL is selected):**
- If you choose **GraphQL** as your API style, you MUST implement resolvers compatible with `express-graphql` and `buildSchema`
- When using `buildSchema` (schema-first approach), there are TWO critical requirements:

**1. Flat Resolver Structure** - resolvers MUST be provided as a **flat object** at the root level:
  ```javascript
  const resolvers = {
    getAnimal: ({ animalId }) => { /* implementation */ },
    listAnimals: ({ status, limit, offset }) => { /* implementation */ },
    intakeAnimal: ({ input }) => { /* implementation */ },
    // ... all other queries and mutations at root level
  };
  module.exports = resolvers;
  ```

**2. Correct Parameter Signature** - arguments are passed in the FIRST parameter (not the second):
  ```javascript
  // CORRECT - destructure args from first parameter
  listAnimals: ({ status, limit = 20, offset = 0 }) => {
    // status, limit, offset come from the first parameter
    if (status) {  // This will work correctly
      // filter by status
    }
  }
  
  // INCORRECT - using underscore to ignore first parameter
  listAnimals: (_, { status, limit = 20, offset = 0 }) => {
    // status, limit, offset will ALL be undefined!
    // This is the Apollo Server signature, NOT buildSchema signature
    if (status) {  // This will never execute - status is always undefined
      // filter will never work
    }
  }
  ```
**INCORRECT patterns (DO NOT USE):**

Pattern 1 - Nested structure:
  ```javascript
  // This will NOT work with buildSchema + express-graphql
  const resolvers = {
    Query: {
      getAnimal: ({ animalId }) => { /* implementation */ },
      listAnimals: ({ status, limit, offset }) => { /* implementation */ }
    },
    Mutation: {
      intakeAnimal: ({ input }) => { /* implementation */ }
    }
  };
  module.exports = resolvers; // Will cause "Cannot return null for non-nullable field" errors
  ```

Pattern 2 - Wrong parameter signature (even with flat structure):
  ```javascript
  // This will NOT work - args will all be undefined
  const resolvers = {
    listAnimals: (_, { status, limit, offset }) => {
      // status, limit, offset are undefined - filter won't work!
    }
  };
  module.exports = resolvers; // Filtering, pagination, all args will be ignored
  ```

**If you create nested resolvers for organization**, flatten them AND use correct signatures:
  ```javascript
  const resolvers = {
    Query: {
      // CORRECT signature - args in first parameter
      getAnimal: ({ animalId }) => { /* ... */ },
      listAnimals: ({ status, limit, offset }) => { /* ... */ }
    },
    Mutation: {
      // CORRECT signature - args in first parameter
      intakeAnimal: ({ input }) => { /* ... */ }
    }
  };
  
  // Flatten for buildSchema compatibility
  module.exports = {
    ...resolvers.Query,
    ...resolvers.Mutation
  };
  ```

**Why this matters:**
- `buildSchema` + `express-graphql` passes arguments as `(args, context, info, rootValue)`
- Apollo Server and other implementations use `(parent, args, context, info)`
- Using `(_, { args })` pattern from Apollo Server will cause ALL arguments to be `undefined`
- See `docs/GRAPHQL_RESOLVER_PATTERN.md` for detailed explanation

#### 3.1 Overreach guardrails (`NOR-*`)
You MUST comply with all `NOR-*` items in the Master Spec. In particular:
- You MUST NOT require any external integrations (`NOR-0001`).
- You MUST NOT implement commerce flows (`NOR-0002`), promotions (`NOR-0003`), or messaging/chat (`NOR-0004`).
- Privacy requirements are out of scope (`NOR-0005`).
- You MUST choose **one** API style (REST or GraphQL) and produce **one** corresponding contract artifact (`NOR-0006`).
- You MUST NOT add features not required by `REQ-*` items (`NOR-0007`).

#### 3.2 Assumptions (`ASM-*`)
- Any assumption MUST be explicitly labeled `ASM-####` and listed in an "Assumptions" section.
- Assumptions MUST be the smallest reasonable interpretation that remains compliant.
- You MUST NOT ask for operator input or wait for a response. Use `ASM-####` and proceed.

---

### 4) Required Outputs (MUST)
Your deliverable MUST include all of the following:

#### 4.1 Implementation (code + configs)
- A working implementation for the selected Target Model.
- Must be runnable from a clean workspace using non-interactive commands.

#### 4.2 API Contract Artifact (`docs/API_Contract.md` compliant) (MUST)
Produce exactly one contract artifact based on the selected API style:
- If **REST**: OpenAPI (or equivalent machine-readable REST contract) that satisfies `docs/API_Contract.md`.
- If **GraphQL**: GraphQL schema that satisfies `docs/API_Contract.md`.

The contract artifact MUST explicitly define:
- operations required for the selected model (animals, lifecycle transitions, applications/evaluation/decision, history; plus Model B deltas if selected)
- request/response shapes
- error categories (`ValidationError`, `NotFound`, `Conflict`, `AuthRequired`, `Forbidden` where applicable)
- pagination rules for collection operations
- deterministic ordering + tie-break rules for collection operations

#### 4.3 Deterministic Seed + Reset-to-Seed (`docs/Seed_Data.md` compliant) (MUST)
You MUST implement and document a **non-interactive reset-to-seed** mechanism that:
- restores the canonical seed dataset for the selected model
- is idempotent (safe to run twice)
- supports verification of `docs/Seed_Data.md` golden records and determinism checks

#### 4.4 Image handling constraints (`docs/Image_Handling.md` compliant) (MUST)
If the selected Target Model includes images, your implementation and contract MUST enforce `docs/Image_Handling.md` constraints, including:
- max 3 images per animal
- allowed content types (`image/jpeg`, `image/png`, `image/webp`)
- deterministic image ordering (primary `ordinal` asc, tie-break `imageId` asc)

#### 4.5 Acceptance verification (`docs/Acceptance_Criteria.md`) (MUST)
You MUST provide a benchmark-operator-friendly way to verify the implementation against `docs/Acceptance_Criteria.md`:
- Provide an "Acceptance Checklist" mapped to the relevant `AC-*` IDs for the selected model.
- Provide commands or steps to produce observable evidence (logs/output) for each acceptance item.

#### 4.6 Automated Tests (MUST)
You MUST generate automated tests that:
- Are mapped to `docs/Acceptance_Criteria.md` `AC-*` acceptance criteria IDs (use comments or test names to indicate the `AC-*` ID being tested)
- Are runnable non-interactively via a single command (e.g., `npm test`, `pytest`, `mvn test`)
- Cover both happy-path and error-path scenarios as specified in `docs/Acceptance_Criteria.md`
- Produce clear pass/fail output that can be recorded as evidence

Place tests under `{Workspace Path}/backend/` in an appropriate test folder for the chosen technology.

#### 4.7 Benchmark artifact bundle (`docs/Benchmarking_Method.md`) (MUST)
You MUST produce operator-ready artifacts aligned to `docs/Benchmarking_Method.md`:
- A run record skeleton capturing M-01..M-11 inputs (TTFR/TTFC, clarifications, reruns, interventions, etc.)
- Run instructions that are copy/paste friendly (run, reset-to-seed, verify acceptance)
- Evidence pointers for determinism checks and contract completeness checks

#### 4.8 AI Run Report (MUST)
You MUST produce a single comparison-ready document at `{Workspace Path}/benchmark/ai_run_report.md` that includes:
- **Run configuration**: Copy of the run.config contents (from `{Workspace Path}/../run.config`)
- **Tech stack**: Backend language/framework, database, and any key libraries used
- **Timestamps** (**ISO-8601 UTC with milliseconds**, e.g. `2025-12-17T22:59:33.123Z`) recorded at these checkpoints:
  - `generation_started`: When you began generating code
  - `code_complete`: When all code files have been written
  - `build_clean`: When the build succeeds with no errors
  - `seed_loaded`: When seed data is loaded and verified
  - `app_started`: When **you start the API/application process** with no errors **and verify it responds** (e.g., health check) as part of your own run workflow
  - `test_run_N_start`: Begin timestamp for each test run iteration (e.g., `test_run_1_start: 2024-12-17T10:30:00.000Z`)
  - `test_run_N_end`: End timestamp for each test run iteration (e.g., `test_run_1_end: 2024-12-17T10:32:15.000Z`)
  - `test_run_N_total`: Total number of tests in that run
  - `test_run_N_passed`: Number of tests that passed
  - `test_run_N_failed`: Number of tests that failed
  - `test_run_N_pass_rate`: Pass rate as decimal (0.0 to 1.0, e.g., 0.85 for 85%)
  - `all_tests_pass`: When all tests pass (timestamp of final successful test run)
- **Test summary**: Total tests, passed, failed, and final pass rate (from the last test run)
- **Test iterations**: Count of how many times tests were run before all passed
- **LLM Usage** (if available from tool):
  - `input_tokens`: Total input tokens used
  - `output_tokens`: Total output tokens used
  - `total_tokens`: Sum of input and output tokens
  - `requests_count`: Number of API requests made
  - `estimated_cost_usd`: Estimated cost in USD (if calculable)
  - `cost_currency`: Currency code (default: USD)
  - `usage_source`: Source of data (`tool_reported`, `operator_estimated`, or `unknown`)
- **Artifact paths**: Paths to contract, run instructions, acceptance checklist, and evidence folders

This report enables direct comparison between different AI tool runs.

**Timestamp integrity rule:** If you report any `tests_run_N` timestamp, the API MUST already be running for that test run. In that case, `app_started` MUST be set (not `Unknown`) and MUST be \(\le\) `tests_run_1`.

---

### 5) Loop-Until-Green Workflow (MUST)
After generating all code, you MUST execute the following loop-until-green workflow:

#### 5.1 Build Loop
1. Execute `npm install` in the backend directory using `run_terminal_cmd` with `required_permissions: ['network']` (or equivalent terminal command execution)
2. If npm install fails due to sandbox network restrictions:
   - Ensure `.npmrc` is configured correctly (see section 3.0)
   - Retry with `required_permissions: ['network']` explicitly specified
   - See `docs/SANDBOX_SOLUTION.md` for detailed troubleshooting guidance
3. If build errors occur (non-network related), fix them and rebuild
4. Repeat until build succeeds with no errors
5. Record timestamp for `build_clean` when `npm install` completes successfully

**Note:** Network access is required for `npm install` to download dependencies. You MUST request network permissions using `required_permissions: ['network']` in your `run_terminal_cmd` call. Refer to `docs/SANDBOX_SOLUTION.md` for best practices and alternative approaches.

#### 5.2 Seed + Verify Loop
1. Run reset-to-seed
2. Run seed verification
3. If errors occur, fix and repeat
4. Record timestamp for `seed_loaded`

#### 5.3 Start Loop
1. Execute `npm start &` (or equivalent background execution) using `run_terminal_cmd` to start the application in the background
2. Wait a few seconds for the server to initialize
3. Execute `curl http://localhost:3000/health` (or equivalent health check) to verify the API responds
4. If start errors occur, fix and restart
5. Record timestamp for `app_started` **at the moment the API is confirmed running and responsive** (when health check succeeds)
6. **Leave the API running during testing** — it will be stopped after all tests pass

#### 5.4 Test Loop
1. Record `test_run_N_start` timestamp (where N is the iteration number, starting at 1)
2. Execute `npm test` using `run_terminal_cmd` (or equivalent) and capture the output
3. Record `test_run_N_end` timestamp
4. Parse the test output to extract test results:
   - `test_run_N_total`: Total number of tests (parse from test output)
   - `test_run_N_passed`: Number of tests that passed (parse from test output)
   - `test_run_N_failed`: Number of tests that failed (parse from test output)
   - `test_run_N_pass_rate`: Calculate as `passed / (passed + failed)` (decimal 0.0 to 1.0)
5. If any tests fail, analyze failures, fix issues, and increment N for the next iteration
6. Repeat steps 1-5 until all tests pass
7. Record timestamp for `all_tests_pass` (same as the final `test_run_N_end`)
8. Record `test_iterations`: The total number of test runs (value of N when all passed)

**CRITICAL:** You MUST execute all commands using `run_terminal_cmd` (or your tool's equivalent terminal command execution capability). Do NOT create shell scripts or expect manual execution. The workflow MUST be fully autonomous.

Update `benchmark/acceptance_checklist.md` to mark each `AC-*` item as passing once verified by tests.

#### 5.5 Stop Server After Testing
After all tests pass and the `all_tests_pass` timestamp is recorded:
1. Stop the API server using `pkill -f "node src/server.js"` or equivalent
2. Verify the server is stopped (port 3000 should be free)
3. The server should be stopped to leave a clean state for the operator

**IMPORTANT:** The server will need to be manually restarted by the operator for UI integration. The run instructions MUST document how to start the server for this purpose.

---

### 6) Run Instructions Requirements (Non-interactive) (MUST)
Provide a single "Run Instructions" section at `{Workspace Path}/benchmark/run_instructions.md` that includes:
- prerequisites (runtime versions if needed)
- install/build commands (non-interactive; no prompts)
- start commands (API) with two distinct subsections:
  - **For Testing and Verification**: How to start the server for development/testing
  - **For UI Integration**: Explicit instructions that the API must be running before starting the UI
- **stop commands (API)**: How to stop the server after testing, including:
  - Using `npm stop` (recommended)
  - Manual methods (lsof, kill, pkill)
  - Ctrl+C for foreground processes
- test command
- reset-to-seed command/mutation
- verification commands/steps for:
  - seed invariants (`docs/Seed_Data.md`)
  - acceptance checks (`docs/Acceptance_Criteria.md`)

**CRITICAL:** All commands in the run instructions MUST be executable via `run_terminal_cmd` (or equivalent) without manual intervention. Do NOT create shell scripts or workflow automation scripts - the AI tool executes commands directly. All commands MUST be copy-paste friendly and non-interactive.

**CRITICAL — Server Management:** The run instructions MUST clearly state that:
- The server is stopped after testing completes (clean state)
- The operator must manually start the server before building the UI
- The API must be running for the UI to connect to it

If you cannot make instructions fully non-interactive, record a clearly labeled `ASM-####` and explain why, but avoid this unless strictly necessary.

---

### 7) Reporting Format (MUST)
At completion, output a final "Run Summary" with:
- Selected Target Model and API Style
- List of all assumptions (`ASM-*`)
- Paths to:
  - contract artifact
  - run instructions
  - AI run report (`benchmark/ai_run_report.md`)
  - reset-to-seed mechanism
  - acceptance checklist / evidence
  - automated tests
  - run folder bundle contents (artifacts required by `docs/Benchmarking_Method.md`)

Do NOT claim completion without providing these paths.

---

### 8) Final State (MUST)
At the end of this run:
- The **API server MUST be stopped** (clean state for operator)
- All tests MUST pass
- The AI run report MUST be complete with all timestamps
- The run instructions MUST document how to start the API for UI integration
- Provide a **clickable URL** for where the API will be accessible when started (e.g., `http://localhost:3000`)

---

### 9) LLM Usage Tracking (MUST)
**IMPORTANT — Operator Action Required:**

Before completing this run, you MUST prompt the operator to check their LLM usage/plan status. The operator needs to record their usage metrics to compare before and after the run.

**For the operator:**
1. **Check your current LLM usage/billing status NOW** (before the run completes)
2. After the run completes, check again to determine the usage for this run
3. Record the usage metrics in the AI run report if available from your tool

**Tool-specific usage checking instructions:**
- **Cursor**: Check Cursor Settings → Usage/Billing, or visit the Cursor dashboard/account page
- **GitHub Copilot**: Check GitHub Settings → Copilot → Usage, or GitHub account billing page
- **Codeium**: Check Codeium dashboard or account settings for usage metrics
- **Other tools**: Check your tool's billing/usage dashboard or account settings page

**If usage metrics are available from the tool**, include them in the AI run report under the "LLM Usage" section. If not available, note this in the report and the operator will need to estimate or record manually.

**Completion prompt to display:**
```
⚠️  LLM USAGE TRACKING REQUIRED

Before marking this run as complete, please:
1. Check your current LLM plan usage/billing status
2. Note the current token/request counts or cost
3. After completion, check again to calculate the difference
4. Record usage metrics in the AI run report if available

Tool: [Detected tool name]
Check usage at: [Tool-specific instructions based on detected tool]
```

---

### 8.5) Automated Results Submission (MUST)
Upon completion of the implementation and all verification steps, you MUST generate a standardized result file for submission.

#### 8.5.1 Generate Result File
Run the result generation script to create a standardized result file:
```bash
cd {Spec Root}
./scripts/generate_result_file.sh --run-dir {Workspace Path}/..
```

This script will:
- Extract metrics from your AI run report
- Parse run configuration
- Generate a standardized result file (defaults to current directory)
- **Note**: The result file should be copied to `pawmate-ai-results/results/submitted/` for processing

#### 8.5.2 Complete Result File
The generated result file will contain placeholders for metrics that must be manually completed. You MUST:
1. Review the generated result file
2. Extract and fill in any missing metrics from your run:
   - Acceptance criteria pass/fail counts and passrate
   - Determinism compliance status
   - Contract completeness passrate
   - Instructions quality rating
   - Any other metrics that can be determined from your run
3. Calculate scores using `docs/Scoring_Rubric.md` (if sufficient data is available)

#### 8.5.3 Validate Result File
Before submission, validate the result file (in the results repository):
```bash
cd /path/to/pawmate-ai-results
./scripts/validate_result.sh results/submitted/{generated-filename}.json
```

Fix any validation errors before proceeding.

#### 8.5.4 Submit Result File
After validation passes, the result file is ready for submission. The operator will:
1. Copy the result file to `pawmate-ai-results/results/submitted/`
2. Review the result file for completeness
3. In the results repository, commit it: `git add results/submitted/{filename}.json`
4. Create a pull request to submit the results

**Note**: If you cannot execute the generation script (e.g., no shell access), create the result file manually using `results/result_template.json` as a template, following `docs/Result_File_Spec.md` for the exact format.

#### 8.5.5 Result File Requirements
The result file MUST:
- Follow the naming convention: `{tool-slug}_{model}_{api-type}_{run-number}_{timestamp}.md`
- Include complete YAML frontmatter with all required fields
- Include human-readable content following `docs/Run_Log_Template.md` structure
- Reference all artifact paths correctly
- Be validated successfully before submission

---

### 9) Start Now
**YOUR VERY FIRST OUTPUT must include the `generation_started` timestamp (ISO-8601 UTC with milliseconds):**

```
generation_started: [current ISO-8601 UTC timestamp with milliseconds, e.g. 2025-12-17T22:59:33.123Z]
```

Then confirm you understand the constraints above and begin implementation for the selected Target Model and API Style.

