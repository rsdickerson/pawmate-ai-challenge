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
Update or extend the existing `benchmark/run_instructions.md` to include:
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
At completion, output a "UI Run Summary" at `{Workspace Path}/benchmark/ui_run_summary.md` that includes:
- **Timestamps** (**ISO-8601 UTC with milliseconds**, e.g. `2025-12-17T22:59:33.123Z`):
  - `ui_generation_started`: When you began generating UI code
  - `ui_code_complete`: When all UI files have been written
  - `ui_build_success`: When the UI builds successfully with no errors
  - `ui_running`: When the UI is running and accessible (no runtime errors)
- **Build success**: Confirmation that UI builds and runs without errors (boolean: true/false)
- UI technology stack used
- List of any assumptions (`ASM-*`)
- List of any backend changes made (if any)
- **LLM Usage** (if available from tool):
  - `input_tokens`: Total input tokens used
  - `output_tokens`: Total output tokens used
  - `total_tokens`: Sum of input and output tokens
  - `requests_count`: Number of API requests made
  - `estimated_cost_usd`: Estimated cost in USD (if calculable)
  - `cost_currency`: Currency code (default: USD)
  - `usage_source`: Source of data (`tool_reported`, `operator_estimated`, or `unknown`)
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

This will generate a result file that includes both API and UI completion.

#### 8.5.3 Validate and Submit
Follow the same validation and submission steps as in the API prompt (section 8.5.3-8.5.5).

**Note**: The UI run is typically part of the same benchmark run as the API. The result file should reflect the complete implementation (API + UI) when both are finished.

---

### 9) LLM Usage Tracking (MUST)
**IMPORTANT — Operator Action Required:**

Before completing this run, you MUST prompt the operator to check their LLM usage/plan status. The operator needs to record their usage metrics to compare before and after the run.

**For the operator:**
1. **Check your current LLM usage/billing status NOW** (before the UI run completes)
2. After the run completes, check again to determine the usage for this run
3. Record the usage metrics in the UI run summary if available from your tool

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
1. Check your current LLM plan usage/billing status
2. Note the current token/request counts or cost
3. After completion, check again to calculate the difference
4. Record usage metrics in the UI run summary if available

Tool: [Detected tool name]
Check usage at: [Tool-specific instructions based on detected tool]
```

---

### 10) Start Now
**YOUR VERY FIRST OUTPUT must include the `ui_generation_started` timestamp (ISO-8601 UTC with milliseconds):**

```
ui_generation_started: [current ISO-8601 UTC timestamp with milliseconds, e.g. 2025-12-17T22:59:33.123Z]
```

**THEN, immediately verify the API server is running** (see section 5). If not running, start it before proceeding.

Then confirm you understand that the backend already exists and begin UI implementation for the selected Target Model.

