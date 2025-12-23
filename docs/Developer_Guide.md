# Developer Guide (Entrypoint)

This is the **single entrypoint** into the numbered `docs/` set. Use it to navigate the spec, appendices, and operator templates without introducing tool- or technology-specific assumptions.

## Where to start (by intent)
- **I want a high-level repo overview**: start at `../README.md`
- **I want to run a benchmark quickly**: see the [Quick Start](../README.md#quick-start-5-steps) in the README
- **I want an end-to-end operator checklist**: start at `../README.md` (see "Operator Guide (step-by-step)")
- **I want the canonical spec + appendices/templates**: start here, then follow the doc map below

## Starting a benchmark run (recommended flow)
Use the **prompt renderer** to generate a run folder and pre-filled prompt wrapper:

```bash
./scripts/initialize_run.sh --profile model-a-rest --tool "YourTool" --tool-ver "1.0"
```

This creates:
- `runs/YYYYMMDDTHHmm/` — timestamped run folder
- `runs/.../run.config` — run parameters (spec_version, tool, model, api_type)
- `runs/.../start_build_api_prompt.txt` — the prompt to paste into the AI tool for API/backend generation
- `runs/.../start_build_ui_prompt.txt` — the prompt to paste after API is complete for UI generation
- `runs/.../PawMate/` — workspace for the implementation (backend + UI)

## UI expectation (for future runs)
The UI prompt template is intended to yield a **consumer-first UI**:
- Default flow should be **Browse pets → Pet details → Apply**
- Staff/admin capabilities (intake, transitions, evaluation/decisions, reset) should exist but be in a clearly labeled **Staff tools** area

Available profiles: `model-a-rest`, `model-a-graphql`, `model-b-rest`, `model-b-graphql`

See `profiles/README.md` for details on profile contents.

## Doc map (numbered, canonical)
### Core spec + appendices (source of truth)
1. `Master_Functional_Spec.md` — Normative functional spec (requirements `REQ-*`, non-requirements `NOR-*`, assumptions `ASM-*`, Models A/B).
2. `API_Contract.md` — API contract artifact requirements (choose REST *or* GraphQL; pagination, errors, ordering determinism).
3. `Seed_Data.md` — Deterministic seed dataset + reset-to-seed + post-reset invariants (benchmark-critical).
4. `Image_Handling.md` — Simple image handling constraints (no external integrations; deterministic image ordering).
5. `Acceptance_Criteria.md` — Observable acceptance criteria + use-case catalog (Model A and Model B).
6. `Benchmarking_Method.md` — Benchmark method, required artifacts, metrics, evidence-first rules.

### Operator templates (in `docs/`)
7. `Run_Log_Template.md` — Run log template (per tool, per run) including M-01..M-11 metrics and evidence pointers.
8. `Scoring_Rubric.md` — Evidence-based scoring rubric (Unknown handling, overreach penalties).
9. `Comparison_Report_Template.md` — Cross-tool comparison report template + standard table schema.

### Technical guidance (in `docs/`)
- `SANDBOX_SOLUTION.md` — Handling sandbox restrictions during npm install (network permissions)
- `GRAPHQL_RESOLVER_PATTERN.md` — Critical GraphQL resolver structure requirements for express-graphql + buildSchema

### Prompt templates (in `prompts/` — NOT read by AI during implementation)
- `prompts/api_start_prompt_template.md` — API/backend generation prompt template (rendered by `initialize_run.sh`)
- `prompts/ui_start_prompt_template.md` — UI generation prompt template (rendered by `initialize_run.sh`)

## Links (relative)
### Spec documents (in `docs/`)
- [Master Functional Spec](Master_Functional_Spec.md)
- [API Contract](API_Contract.md)
- [Seed Data](Seed_Data.md)
- [Image Handling](Image_Handling.md)
- [Acceptance Criteria](Acceptance_Criteria.md)
- [Benchmarking Method](Benchmarking_Method.md)
- [Run Log Template](Run_Log_Template.md)
- [Scoring Rubric](Scoring_Rubric.md)
- [Comparison Report Template](Comparison_Report_Template.md)

### Technical guidance (in `docs/`)
- [Sandbox Solution](SANDBOX_SOLUTION.md)
- [GraphQL Resolver Pattern](GRAPHQL_RESOLVER_PATTERN.md)

### Prompt templates (in `prompts/`)
- [API Start Prompt Template](../prompts/api_start_prompt_template.md)
- [UI Start Prompt Template](../prompts/ui_start_prompt_template.md)

## Conventions (keywords, IDs, scope control)
This guide is navigation + conventions only. It must not introduce new requirements.

### RFC-style keywords
Requirements are written using RFC-style keywords:
- **MUST / MUST NOT**: mandatory requirement (or prohibition)
- **SHOULD / SHOULD NOT**: strong recommendation; deviations require justification
- **MAY**: optional behavior permitted by the spec

See the “How to read this spec” intro in `docs/Master_Functional_Spec.md`.

### Requirement IDs, non-requirements, and assumptions
The canonical traceability tokens used across the doc set:
- **`REQ-*`**: normative requirements (the only source of “required” behavior)
- **`NOR-*`**: explicit non-goals / out-of-scope guardrails (prevent overreach)
- **`ASM-*`**: explicit assumptions (used only when the spec is ambiguous; must be “smallest compliant”)
- **`AC-*`**: acceptance criteria IDs (observable checks used to verify implementations)

Primary sources:
- `REQ-*` / `NOR-*` / `ASM-*`: `docs/Master_Functional_Spec.md`
- `AC-*` conventions: `docs/Acceptance_Criteria.md`

### “Do not overreach” rule
If a behavior is not required by a `REQ-*` item (or explicitly permitted by `MAY`), it is out of scope. Overreach incidents (including `NOR-*` violations) are tracked and penalized during benchmarking.

## Model selection (A vs B) and global guardrails
The spec supports **two selectable models**:
- **Model A (Minimum)**: baseline requirements only.
- **Model B (Full)**: Model A **plus** additional “delta” requirements labeled `...-B`.

Global guardrails to preserve across all work:
- **API-first**: the API is the system of record.
- **Choose exactly one API style**: **REST _or_ GraphQL** (not both).
- **Exactly one contract artifact**: OpenAPI-like REST contract OR GraphQL schema.
- **Determinism**: deterministic seed data + **non-interactive reset-to-seed**.
- **No external integrations**; **privacy is out of scope**.

## Note on legacy Pet Store docs
This PawMate spec was derived from a prior Pet Store benchmarking harness. The PawMate source of truth is `docs/` at the repository root.


