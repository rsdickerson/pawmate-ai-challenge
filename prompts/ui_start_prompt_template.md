## UI Start Prompt (Template)

> **Recommended:** Use the prompt renderer to generate a pre-filled version of this template:
> ```bash
> ./scripts/initialize_run.sh --profile model-a-rest --tool "YourTool" --tool-ver "1.0"
> ```
> This auto-creates a run folder with both API and UI start prompts.

> **When to use:** Submit this prompt **after** the API/backend has been successfully generated and is running. The UI prompt assumes the backend already exists in the workspace.

---

### 0) Benchmark Header (Operator fills)
- **Tool Under Test (TUT)**: [Tool name + version/build id]
- **Run ID**: [e.g., ToolX-ModelA-Run1-UI]
- **Frozen Spec Reference**: [commit/tag/hash or immutable archive id]
- **Spec Root**: [repo-root-path]
- **Workspace Path**: [workspace-path]
- **Target Model (choose exactly one)**:
  - [ ] **Model A (Minimum)**
  - [ ] **Model B (Full)**
- **API Style (the backend uses)**:
  - [ ] **REST**
  - [ ] **GraphQL**

---

### 1) Role + Objective (Tool must follow)
You are an implementation agent continuing a reproducible benchmarking run. The **API/backend has already been generated** and exists in the workspace. Your objective is to produce a **frontend/UI** that integrates with the existing backend API.

**⏱️ FIRST ACTION — Record Start Time:**
Before doing anything else, record the current timestamp in **ISO-8601 UTC with milliseconds** (e.g., `YYYY-MM-DDTHH:MM:SS.sssZ`) as `ui_generation_started`. Output it immediately in your first response, like this:

```
ui_generation_started: 2024-12-17T11:00:00.000Z
```

This timestamp is critical for benchmarking and MUST be recorded before any code generation begins.

---

### 1.0) Run Independence — No Cross-Run References (MUST)
This UI run MUST be treated as fully independent:
- You MUST NOT reference, rely on, or mention any previous runs, prior attempts, earlier chats, or other run folders.
- You MUST treat this prompt, the frozen spec files, and the existing backend present in the **Workspace Path** as the complete context for this run.
- Do not say "as before", "like last run", or similar. If something is missing or ambiguous, ask a clarification question or record a minimal `ASM-####`.

**CRITICAL — Existing backend:**
- The backend implementation already exists under the **Workspace Path** (likely in `backend/` or at the workspace root).
- You MUST NOT rebuild, replace, or significantly modify the existing backend unless required for integration fixes.
- You MUST integrate the UI with the existing API endpoints/operations.

**IMPORTANT — File locations:**
- **Read spec files from:** the **Spec Root** path (frozen spec docs live there under `docs/`)
- **Write UI files to:** `{Workspace Path}/ui/` (create this folder if it doesn't exist)
- **Do NOT overwrite backend code** unless making minimal integration fixes (e.g., CORS configuration)

You MUST work strictly within scope and MUST NOT invent requirements. If something is ambiguous, you MUST either ask a clarification question or record the smallest compliant assumption as an explicit `ASM-####`.

### 1.1) Autonomous Completion — Work Until 100% Done (MUST)
**CRITICAL — DO NOT STOP UNTIL COMPLETE:**

You MUST continue working autonomously until ALL of the following are complete:
- ✅ All UI code files are written
- ✅ UI build completes successfully (`npm install` finishes with no errors)
- ✅ UI runs without runtime errors
- ✅ API server is running and responsive (verify before UI development, start if needed)
- ✅ Both servers (API and UI) are running simultaneously
- ✅ All benchmark artifacts are updated (run instructions, UI run summary with all timestamps)
- ✅ Startup/shutdown scripts are updated to manage both services

**DO NOT STOP OR PAUSE** after:
- Writing UI code files (you must continue to build)
- Successful build (you must continue to start services)
- Starting only the API (you must also start the UI)
- Starting only the UI (you must verify API is running too)
- Partial artifact updates (you must complete ALL required updates)

**If you encounter errors or failures:**
- Fix them yourself and continue
- Iterate as many times as needed
- DO NOT ask the operator for help or wait for input
- DO NOT stop with build or runtime errors — keep iterating until everything works

**Completion criteria:**
You have NOT completed your work until both the API and UI are running, accessible, and all benchmark artifacts are updated with complete content including all timestamps.

If the operator sends "continue", it means you stopped prematurely. Resume work from where you left off and proceed to 100% completion.

---

### 2) In-Scope Inputs (Frozen Spec Files)
You MUST treat the following files (located under the **Spec Root**) as the sole source of truth:
- `{Spec Root}/docs/Master_Functional_Spec.md`
- `{Spec Root}/docs/API_Contract.md`
- `{Spec Root}/docs/UI_Requirements.md` **← CRITICAL: Read this first for API integration guidance**
- `{Spec Root}/docs/Acceptance_Criteria.md`

Additionally, reference the existing backend's contract artifact (OpenAPI or GraphQL schema) in the workspace.

**IMPORTANT:** The `UI_Requirements.md` document contains **prescriptive, normative requirements** for:
- Exact API endpoint patterns to call
- Required vs optional vs auto-generated fields
- RESTful path parameter conventions
- Field name mappings (e.g., `explanation` vs `reason`)
- Common mistakes to avoid

You MUST follow `UI_Requirements.md` exactly. It prevents common API integration errors.

---

### 3) Hard Guardrails (MUST)

#### 3.0 Required Tech Stack (MUST)
To ensure reliable and comparable benchmarking results, you MUST use the following technology stack for the UI:

- **Frontend**: Vite + React + TypeScript
- **Project structure**: Frontend as a separate project under `{Workspace Path}/ui/` with its own `package.json`
- **No Docker**: Do not use Docker or any containerization
- **No external services**: No cloud services or third-party APIs
- **Cross-platform**: The UI MUST run on both macOS and Windows using only `npm install && npm run dev`

**CRITICAL:** You MUST NOT use any other frontend framework (e.g., Vue, Angular, Svelte, Next.js) or build tool (e.g., webpack, Parcel, Rollup). Use Vite + React + TypeScript exactly as specified.

The backend was already built with Node.js + Express + SQLite per the API prompt constraints.

#### 3.1 Backend preservation
- You MUST NOT delete or replace existing backend code.
- You MUST NOT change the API contract (operations, request/response shapes).
- You MAY make minimal backend changes for integration (e.g., CORS headers, static file serving) if clearly documented.

#### 3.2 Overreach guardrails (`NOR-*`)
You MUST comply with all `NOR-*` items in the Master Spec. In particular:
- You MUST NOT require any external integrations (`NOR-0001`).
- You MUST NOT implement commerce flows (`NOR-0002`), promotions (`NOR-0003`), or messaging/chat (`NOR-0004`).
- You MUST NOT add UI features not required by `REQ-*` items (`NOR-0007`).

#### 3.3 Assumptions (`ASM-*`)
- Any assumption MUST be explicitly labeled `ASM-####` and listed in an "Assumptions" section.
- Assumptions MUST be the smallest reasonable interpretation that remains compliant.

---

### 4) Required Outputs (MUST)
Your deliverable MUST include:

#### 4.1 UI Implementation
- A working frontend under `{Workspace Path}/ui/`
- Must integrate with the existing backend API
- Must be buildable and runnable from a clean state using non-interactive commands

#### 4.2 UI capabilities (based on Target Model)
The UI MUST provide interfaces for the API operations defined in `docs/API_Contract.md` for the selected model:
- **Model A**: Animal intake/view/update, lifecycle transitions, adoption workflow (submit/evaluate/decide), history view
- **Model B**: All of Model A plus search, authentication UI elements

#### 4.2.1 Consumer-first UX posture (MUST)
The UI MUST be **consumer-focused by default** (not developer/admin-focused):
- **Primary navigation** MUST emphasize the end-user journey:
  - **Browse pets** (default landing): show `AVAILABLE` animals in a card/grid layout with basic details.
  - **Pet details**: friendly profile view (photos, description, tags) and **history view** (audit trail) in a readable format.
  - **Apply**: guided application form and submission flow.
- **Staff tools** (intake/update/transitions/evaluate/decide/reset) MUST exist (per §4.2) but SHOULD be:
  - placed in a clearly labeled **“Staff tools”** area, and
  - visually separated from the consumer flow to avoid confusing end users.
- The UI MUST NOT require users to read raw JSON to use the primary consumer flow.
  - Debug output MAY exist, but MUST be secondary (e.g., collapsible “Details/Debug”).
- The UI SHOULD be accessible and “consumer nice”:
  - clear labels and helper text
  - readable typography and spacing
  - simple error messages that map to error categories (ValidationError/Conflict/NotFound/AuthRequired)

#### 4.3 Update Run Instructions
Update or extend the existing `{Workspace Path}/../benchmark/run_instructions.md` to include:
- UI prerequisites (if any beyond the backend)
- UI install/build commands (non-interactive)
- UI start command
- How to access the UI (URL/port)

#### 4.4 Update Run Management Scripts (MUST)
You MUST update the `startup.sh` and `shutdown.sh` scripts in the root of the `PawMate/` folder to include UI server management:

**Update `startup.sh` to:**
- Start the UI server after the API server is confirmed running
- Wait for UI server to be responsive (if applicable)
- Display the UI URL in the success output (e.g., `http://localhost:5173`)

**Update `shutdown.sh` to:**
- Stop the UI server before stopping the API server
- Use appropriate port/process kill commands for the UI technology stack (e.g., Vite typically runs on port 5173)

**If scripts don't exist:**
- Create both scripts following the requirements in `docs/Master_Functional_Spec.md` REQ-OPS-0003-A through REQ-OPS-0007-A
- See the API prompt template for example script templates

**Script Update Example:**
In `startup.sh`, add after API starts:
```bash
# Start UI server
if [ -d "ui" ]; then
  echo "Starting UI server..."
  cd ui
  npm run dev &
  UI_PID=$!
  cd ..
  sleep 3
  echo "✓ UI server running at http://localhost:5173"
fi
```

In `shutdown.sh`, add before API shutdown:
```bash
# Stop UI server
echo "Stopping UI server..."
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
```

---

### 5) API Server Verification (MUST)
**CRITICAL — Before Starting UI Development:**

Before generating any UI code, you MUST verify that the API server is running:

1. **Check API health endpoint**: Execute `curl http://localhost:3000/health` (or equivalent health check endpoint)
2. **If API is NOT running**: 
   - Output a clear message: "⚠️ API server is not running. Starting API server..."
   - Start the API server: `cd backend && npm start &`
   - Wait for server initialization (3-5 seconds)
   - Verify health check succeeds
   - Output confirmation: "✅ API server is running and responsive"
3. **If API is running**: Output confirmation: "✅ API server is already running"

**IMPORTANT:** The UI cannot be developed or tested without a running API. You MUST ensure the API is accessible before proceeding with UI implementation.

---

### 6) Run Instructions Requirements (Non-interactive) (MUST)
The updated run instructions MUST include:
- **Prerequisites section** stating:
  - The API server MUST be running before starting the UI
  - How to start the API server: `cd backend && npm start`
  - How to verify API is running: `curl http://localhost:3000/health`
- UI build command (e.g., `npm run build` in the ui folder)
- UI start command (e.g., `npm run dev` or serve from backend)
- UI access URL (e.g., `http://localhost:5173`)
- **Troubleshooting section** for "API not running" errors with instructions to start the backend

**CRITICAL:** The instructions MUST make it explicit that both the API and UI servers need to be running simultaneously, typically in separate terminal windows.

If you cannot make instructions fully non-interactive, record a clearly labeled `ASM-####`.

---

### 7) Reporting Format (MUST)
At completion, output a "UI Run Summary" at `{Workspace Path}/../benchmark/ui_run_summary.md` that includes:
- **Timestamps** (**ISO-8601 UTC with milliseconds**, e.g. `2025-12-17T22:59:33.123Z`):
  - `ui_generation_started`: When you began generating UI code
  - `ui_code_complete`: When all UI files have been written
  - `ui_build_success`: When the UI builds successfully with no errors
  - `ui_running`: When the UI is running and accessible (no runtime errors)
- **Build success**: Confirmation that UI builds and runs without errors (boolean: true/false)
- UI technology stack used
- List of any assumptions (`ASM-*`)
- List of any backend changes made (if any)
- **LLM Usage** (operator must record):
  - `ui_model_used`: Model name/version used (e.g., "claude-sonnet-4.5", "gpt-4-turbo")
  - `ui_requests`: Total number of LLM API requests made for UI generation
  - `ui_tokens`: Total tokens used for UI generation (input + output combined)
  - `usage_source`: Source of data (`tool_reported`, `operator_estimated`, or `unknown`)
  - *Optional*: `estimated_cost_usd`, `input_tokens`, `output_tokens` if available separately
- Paths to:
  - UI source folder
  - Updated run instructions

---

### 8) Final State (MUST)
At the end of this run:
- The **API server MUST be running** and responsive at `http://localhost:3000`
  - Verify with: `curl http://localhost:3000/health`
  - If not running, start it: `cd backend && npm start &`
- The **UI MUST be running** and accessible
- The **UI MUST build successfully** with no errors (`ui_build_success` = true)
- The **UI MUST run without runtime errors** (`ui_running` = true)
- Provide **clickable URLs** for both:
  - API: `http://localhost:3000` (or configured port)
  - UI: `http://localhost:5173` (or configured port)

**CRITICAL:** Before providing the final URLs, you MUST verify both servers are running:
1. Check API health: `curl http://localhost:3000/health`
2. Check UI accessibility: `curl http://localhost:5173` (or configured UI port)
3. Only after both respond successfully, provide the clickable URLs

**IMPORTANT:** The user will click the URL to open the UI in their browser. Make sure both backend and UI are running before providing the final URL.

**Note:** We do not evaluate UI correctness or UX quality automatically. The build success check only verifies that the UI compiles and runs without errors.

---

### 8.5) Automated Results Submission (MUST)
Upon completion of the UI implementation, you MUST update the result file to reflect UI completion.

#### 8.5.1 Update Result File
If a result file was already generated for the API run, update it to include UI completion metrics:
- Update timestamps if UI completion affects TTFC
- Note UI completion in the human-readable section
- Update artifact paths if UI artifacts were created

#### 8.5.2 Generate/Update Result File
Run the result generation script to create or update the standardized result file:
```bash
cd {Spec Root}
./scripts/generate_result_file.sh --run-dir {Workspace Path}/..
```

This will generate a result file in `{Workspace Path}/../benchmark/` that includes both API and UI completion.

**Note**: All benchmark-related files (result files, AI run reports, UI run summaries, submission instructions) are stored in the `benchmark/` folder at the run level (sibling of `PawMate/` folder).

#### 8.5.3 Submit Result File (Email Submission - Recommended)
**For external developers (recommended method):**

After generating/updating the result file, the operator should submit via email:

```bash
cd {Spec Root}
./scripts/submit_result.sh {Workspace Path}/../benchmark/{generated-filename}.json
```

**Note**: The result file is located in `{Workspace Path}/../benchmark/` folder (benchmark folder is at run level, sibling of PawMate folder). Use the full path or navigate to the benchmark folder.

This script will:
- Validate the result file
- Prompt for optional attribution (name/GitHub username)
- Open your email client with pre-filled content (To, Subject, Body)
- Include JSON result data in email body (no attachment needed)

**IMPORTANT**: The script opens your email client but does NOT send the email automatically. You must:
1. Review the pre-filled email in your email client
2. Click "Send" to submit the result

**Email will be sent to**: `pawmate.ai.challenge@gmail.com` (or configured submission email)

**Note**: The `submit_result.sh` script validates the file automatically, so separate validation is not required.

**Viewing Results**: After submission, aggregated results are published in the `pawmate-ai-results` repository for public viewing. See the challenge documentation for the repository URL and viewing instructions.

#### 8.5.4 Alternative: Git-Based Submission (For Maintainers Only)
**Only for maintainers with write access to the `pawmate-ai-results` repository:**

If the operator has write access to the results repository, they may submit via pull request:
1. Copy the result file to `pawmate-ai-results/results/submitted/`
2. In the results repository, validate: `./scripts/validate_result.sh results/submitted/{filename}.json`
3. Commit and create a pull request

**Important**: External developers should use email submission (section 8.5.3), not git-based submission.

**Note**: The UI run is typically part of the same benchmark run as the API. The result file should reflect the complete implementation (API + UI) when both are finished.

---

### 9) LLM Usage Tracking (MUST)
**IMPORTANT — Operator Action Required:**

Before completing this run, you MUST prompt the operator to check their LLM usage/plan status. The operator needs to record their usage metrics to compare before and after the run.

**For the operator:**
1. **Check your current LLM usage/billing status NOW** (before the UI run completes)
2. After the run completes, check again to determine the usage for this run
3. **Record the following metrics in the UI run summary** at `{Workspace Path}/../benchmark/ui_run_summary.md` under the "LLM Usage" section:
   - `ui_model_used`: Model name/version (e.g., "claude-sonnet-4.5", "gpt-4-turbo")
   - `ui_requests`: Total number of LLM API requests made for UI generation
   - `ui_tokens`: Total tokens used for UI generation (input + output combined)
   - `usage_source`: `tool_reported` (if from tool), `operator_estimated` (if manually calculated), or `unknown` (if unavailable)

**Tool-specific usage checking instructions:**
- **Cursor**: Check Cursor Settings → Usage/Billing, or visit the Cursor dashboard/account page
- **GitHub Copilot**: Check GitHub Settings → Copilot → Usage, or GitHub account billing page
- **Codeium**: Check Codeium dashboard or account settings for usage metrics
- **Other tools**: Check your tool's billing/usage dashboard or account settings page

**If usage metrics are available from the tool**, include them in the UI run summary under the "LLM Usage" section. If not available, note this in the summary and the operator will need to estimate or record manually.

**Completion prompt to display:**
```
⚠️  LLM USAGE TRACKING REQUIRED

Before marking this UI run as complete, please:
1. Check your LLM usage/billing status
2. Record the following metrics in the UI run summary at {Workspace Path}/../benchmark/ui_run_summary.md under the "LLM Usage" section:
   - ui_model_used: [Model name/version]
   - ui_requests: [Number of LLM API requests for UI]
   - ui_tokens: [Total tokens used for UI]
   - usage_source: tool_reported | operator_estimated | unknown

Tool: [Detected tool name]
Check usage at: [Tool-specific instructions based on detected tool]
```

**Next steps for operator:**
1. **Record LLM usage metrics** in `{Workspace Path}/../benchmark/ui_run_summary.md` (see LLM Usage section above)
2. **Generate/update result file** (includes both API and UI):
   ```bash
   cd {Spec Root}
   ./scripts/generate_result_file.sh --run-dir {Workspace Path}/..
   ```
   **Note**: The result file will be generated in `{Workspace Path}/../benchmark/` folder (benchmark folder is at run level, sibling of PawMate folder).
3. **Submit result file via email** (recommended):
   ```bash
   cd {Spec Root}
   ./scripts/submit_result.sh {Workspace Path}/../benchmark/{generated-filename}.json
   ```
   **Note**: The script will open your email client with pre-filled content. You must manually click "Send" to submit the email.
4. **Follow submission instructions**: See `{Workspace Path}/../benchmark/result_submission_instructions.md` for detailed submission instructions.

See `{Spec Root}/docs/Submitting_Results.md` for detailed submission instructions.

---

### 10) Start Now
**YOUR VERY FIRST OUTPUT must include the `ui_generation_started` timestamp (ISO-8601 UTC with milliseconds):**

```
ui_generation_started: [current ISO-8601 UTC timestamp with milliseconds, e.g. 2025-12-17T22:59:33.123Z]
```

**THEN, immediately verify the API server is running** (see section 5). If not running, start it before proceeding.

Then confirm you understand that the backend already exists and begin UI implementation for the selected Target Model.

**REMINDER — You MUST work autonomously until 100% complete:**
- Do NOT stop after writing UI code
- Do NOT stop after successful build
- Do NOT stop with only API running (UI must also be running)
- Do NOT stop with only UI running (API must also be running)
- Do NOT stop without updating all benchmark artifacts
- Continue iterating until BOTH services are running and ALL artifacts are complete

If you stop prematurely, the operator will send "continue" to prompt you to resume. Avoid this by completing all work in one autonomous session.

