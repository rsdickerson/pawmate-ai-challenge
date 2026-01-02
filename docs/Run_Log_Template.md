# Run Log Template — Copy/Paste

> **Operator instructions:** Create one copy of this file per **Tool Under Test (TUT)** per **run** (Run 1 and Run 2). Fill all fields. If a metric cannot be supported by evidence, record **Unknown** and explain what evidence is missing (do not guess).

> **AI Run Report:** The AI tool should generate `benchmark/ai_run_report.md` containing timestamps, tech stack, and test results. These timestamps are **tool-reported milestones** (including the tool starting the API and confirming it responds before running tests). This report provides machine-comparable data for cross-tool benchmarking. Reference it in Section 5 below.

---

### 0) Run Identity (Operator fills)
- **tool_name**: [name]
- **tool_version**: [version/build id]
- **run_id**: [e.g., ToolX-ModelA-Run1]
- **run_number**: [1|2]
- **target_model**: [A|B]
- **api_style**: [REST|GraphQL]
- **spec_reference**: [commit/tag/hash]
- **workspace_path**: [path]
- **run_environment**: [OS/arch + key runtime versions]

---

### 1) Prompt + Scope Control (Operator fills)
- **prompt_wrapper_path**: [path to saved wrapper text]
- **prompt_submit_timestamp**: [ISO-8601]
- **in_scope_docs**:
  - `docs/Master_Functional_Spec.md`
  - `docs/API_Contract.md`
  - `docs/Seed_Data.md`
  - `docs/Image_Handling.md`
  - `docs/Acceptance_Criteria.md`
  - `docs/Benchmarking_Method.md`
- **api_style_choice_validation**:
  - [ ] Implemented exactly one API style
  - [ ] Contract artifact produced for that style
  - **notes**: [e.g., evidence pointer or issue]

---

### 2) Assumptions + Clarifications (Operator fills)
#### 2.1 Assumptions (`ASM-*`)
- **assumptions_list**:
  - [ASM-####: ...]
- **assumptions_notes**: [why needed; ensure “smallest compliant”]

#### 2.2 Clarifications (M-03)
- **clarifications_count**: [number|Unknown]
- **clarifications_log** (copy/paste verbatim Q/A pairs):
  - **Q1**: [tool question]
    - **A1**: [operator answer]
  - **Q2**: ...
- **clarifications_evidence_ref**: [path/anchor into transcript]

---

### 3) Run Timeline (TTFR/TTFC) (Operator fills)
#### 3.1 TTFR (M-01)
- **ttfr_start_timestamp**: [ISO-8601] (prompt submit)
- **ttfr_end_timestamp**: [ISO-8601] (first runnable)
- **ttfr_minutes**: [number|Unknown]
- **ttfr_stop_condition_evidence**: [log/screenshot pointer showing first successful start]

#### 3.2 TTFC (M-02)
- **ttfc_start_timestamp**: [ISO-8601] (prompt submit)
- **ttfc_end_timestamp**: [ISO-8601] (feature-complete evidence produced)
- **ttfc_minutes**: [number|Unknown]
- **ttfc_stop_condition_evidence**: [acceptance+determinism evidence pointers]

---

### 4) Reruns + Operator Interventions (Operator fills)
#### 4.1 Reruns / Regeneration attempts (M-05)
- **reruns_count**: [number|Unknown]
- **reruns_log**:
  - [timestamp] [what was re-issued] — **reason**: [build failure / missing instructions / failing acceptance / etc.]
- **reruns_evidence_ref**: [path/anchor into transcript]

#### 4.2 Operator interventions (manual edits) (M-04)
- **interventions_count**: [number|Unknown]
- **interventions_log** (each is one intervention event):
  - [timestamp] **path**: [file/dir] — **change**: [what changed] — **reason**: [why]
- **interventions_diff_ref** (optional): [patch/diff path if captured]

---

### 5) Artifact Bundle Checklist (`docs/Benchmarking_Method.md`) (Operator fills)
#### 5.1 Required artifact paths
- **tool_transcript_path**: [path]
- **run_instructions_path**: [path] (benchmark/run_instructions.md at run level, sibling of PawMate folder)
- **contract_artifact_path**: [path] (in application code: PawMate/backend/src/schema.graphql for GraphQL or PawMate/backend/openapi.yaml for REST)
- **acceptance_checklist_path**: [path] (benchmark/acceptance_checklist.md at run level, sibling of PawMate folder)
- **acceptance_evidence_path**: [path to logs/screenshots]
- **determinism_evidence_path**: [path]
- **overreach_evidence_path**: [path]
- **ai_run_report_path**: benchmark/ai_run_report.md (at run level, sibling of PawMate folder)
- **automated_tests_path**: [path to test folder/files] (in application code: PawMate/backend/tests/ or similar)
- **result_file_path**: benchmark/{tool-slug}_{model}_{api-type}_run{number}_{timestamp}.json (at run level, sibling of PawMate folder)
- **result_submission_instructions_path**: benchmark/result_submission_instructions.md (at run level, sibling of PawMate folder)

#### 5.2 Completeness check
- [ ] Prompt wrapper saved
- [ ] Full transcript saved
- [ ] Run instructions saved
- [ ] Contract artifact saved
- [ ] Acceptance checklist + evidence saved
- [ ] Determinism evidence saved
- [ ] Overreach notes/evidence saved
- [ ] AI run report saved (benchmark/ai_run_report.md)
- [ ] Automated tests saved
- [ ] Result file generated (benchmark/{tool-slug}_{model}_{api-type}_run{number}_{timestamp}.json)
- [ ] Result submission instructions saved (benchmark/result_submission_instructions.md)
- **notes**: [missing items or Unknowns]

**Note**: All benchmark-related files (result files, AI run reports, submission instructions) should be stored in the `benchmark/` folder at the run level (sibling of `PawMate/` folder). Only application code and operational files belong in the `PawMate/` folder.

---

### 6) Contract Artifact Evaluation (M-10) (Operator fills)
- **contract_checklist_path**: [path to completed contract checklist derived from `docs/API_Contract.md`]
- **contract_completeness_passrate**: [0..1|Unknown]
- **contract_findings**:
  - **pagination declared**: [yes/no/Unknown] — [evidence pointer]
  - **error categories declared**: [yes/no/Unknown] — [evidence pointer]
  - **ordering + tie-break declared**: [yes/no/Unknown] — [evidence pointer]

---

### 7) Determinism / Reset-to-Seed (M-09) (Operator fills)
- **reset_to_seed_mechanism**: [API operation | local command | Unknown]
- **reset_to_seed_instructions_ref**: [path/anchor]
- **reset_idempotency_demonstrated**: [Pass|Fail|Unknown]
- **golden_checks_summary** (`docs/Seed_Data.md`):
  - **animals present** (ANM-0001..): [Pass|Fail|Unknown] — [evidence]
  - **applications/history** (seeded IDs + deterministic ordering): [Pass|Fail|Unknown] — [evidence]
  - **images seeded + ordering**: [Pass|Fail|Unknown] — [evidence]
  - **Model B users/search** (if Model B): [Pass|Fail|N/A|Unknown] — [evidence]
- **determinism_compliance**: [Pass|Fail|Unknown]
- **determinism_notes**: [what failed or what was Unknown]

---

### 8) Acceptance Verification (M-06) (Operator fills)
- **acceptance_model**: [A|B]
- **acceptance_pass_count**: [number|Unknown]
- **acceptance_fail_count**: [number|Unknown]
- **acceptance_not_run_count**: [number|Unknown]
- **acceptance_passrate**: [0..1|Unknown]
- **acceptance_failures_summary** (list the top failures with AC IDs):
  - [AC-...]: [short description] — [evidence pointer]

---

### 9) Overreach Tracking (M-07) (Operator fills)
- **overreach_incidents_count**: [number|Unknown]
- **overreach_incidents**:
  - [NOR-#### or “no supporting REQ-*”] — **what**: [...] — **evidence**: [path/anchor]
- **overreach_notes**: [impact / how detected]

---

### 10) Run Instructions Quality (M-11) (Operator fills)
- **instructions_quality_rating**: [100|70|40|0|Unknown]
- **issues**:
  - [missing prereq / interactive prompt / ambiguous step / requires operator inference]
- **evidence_ref**: [path/anchor]

---

### 11) Reproducibility Notes (M-08) (Operator fills)
> Fill this section after Run 2, comparing Run 1 vs Run 2 for the same tool/model/spec ref.

- **reproducibility_rating**: [None|Minor|Major|Unknown]
- **differences_observed**:
  - **TTFR/TTFC diffs**: [...]
  - **acceptance diffs**: [...]
  - **determinism diffs**: [...]
  - **artifact diffs**: [...]
- **evidence_ref**: [comparison note path]


