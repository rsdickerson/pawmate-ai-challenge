# API Contract Requirements — REST or GraphQL Choice

## Purpose
This document defines what the **API contract artifact** MUST contain so that implementations are verifiable and benchmarkable while still allowing implementers to choose **REST or GraphQL** (choice, not both).

This document is normative for the contract artifact and is aligned to `docs/Master_Functional_Spec.md` requirement IDs.

## Scope and Constraints (Normative)
- Exactly **two selectable models** exist: **Model A (Minimum)** and **Model B (Full)**.
- Implementers MUST choose **one** API style:
  - REST (with a contract artifact such as OpenAPI), OR
  - GraphQL (with a schema contract artifact).
- Implementers MUST NOT be required to implement both REST and GraphQL (see `NOR-0006`).
- No external integrations are required. Privacy requirements are out of scope.

---

## Definitions

### API Contract Artifact (Normative Definition)
An **API contract artifact** is a single, versioned, machine-readable description of the API surface for the selected model and chosen API style.

The artifact MUST be sufficient for a benchmark operator to:
- enumerate all required operations,
- understand request/response shapes and validation rules,
- understand error behavior and status/category mapping,
- verify deterministic ordering + pagination behavior,
- verify lifecycle state-machine enforcement,
- verify decision transparency requirements (explanations),
- verify Model A vs Model B capability coverage,
with minimal human interpretation.

---

## Contract Artifact Requirements (Normative)

### A. Versioning
- The artifact MUST declare a version identifier for the API contract (e.g., `v1`).
- The artifact MUST declare whether it is describing Model A or Model B (or both with clear labeling).

### B. Operations List (REST or GraphQL)
The artifact MUST list all required operations for the selected model:
- **REST**: endpoints + HTTP methods + required path/query/body parameters.
- **GraphQL**: queries/mutations + required arguments + return types.

### C. Request/Response Shapes
The artifact MUST define (via schemas and/or concrete examples) request and response shapes for each operation, including:
- required vs optional fields,
- field types and constraints (length, numeric bounds, enums),
- nullability rules,
- array semantics (ordering if relevant).

### D. Identifier Conventions (Conceptual)
The artifact MUST specify identifier fields and their intended properties:
- `animalId` MUST be stable and unique within the system.
- Any additional IDs (e.g., `applicationId`, `historyEventId`, `imageId`, `userId`) MUST be clearly defined if used.

No specific ID encoding is mandated, but the chosen format MUST be stated (conceptually) and used consistently.

### E. Content Types (Conceptual)
The artifact MUST declare content-type expectations conceptually:
- For REST: JSON request/response bodies for standard operations; image upload/download content types if images are binary.
- For GraphQL: schema types and scalar representations for binary/image handling (if applicable).

### F. Error Model + Validation Rules
The artifact MUST define:
- a common error shape (or GraphQL error conventions) that includes a machine-readable error category/type,
- validation rules per operation (field constraints, required fields),
- observable behaviors for errors (status codes for REST; error codes/categories for GraphQL).

Minimum required error categories:
- **ValidationError** (invalid input / constraint violation)
- **NotFound** (unknown resource id)
- **Conflict** (uniqueness violations, invalid lifecycle transition, stale state conflicts)
- **AuthRequired** (unauthenticated access to protected operation; Model B)
- **Forbidden** (authenticated but insufficient permissions; Model B)

### G. Pagination (Implementer Choice; Must Be Explicit)
For any operation that returns a collection (list/search/history/applications), the artifact MUST:
- pick one pagination style for that operation (offset or cursor),
- define request parameters/arguments and response fields,
- define how pagination interacts with ordering determinism.

### H. Deterministic Ordering + Tie-Break Rules (Benchmark-Critical)
For collection-returning operations (at minimum: List Animals, Search Animals, History list), the artifact MUST define:
- the primary ordering keys (e.g., `createdAt desc`, `animalId asc`),
- deterministic tie-break rules that guarantee stable ordering for the same dataset state and request parameters.

This requirement is critical to satisfy:
- `REQ-API-0002-A` (list ordering determinism)
- `REQ-API-0101-B` (search ordering determinism)

### I. Authentication Declaration (Model B)
If Model B is selected, the artifact MUST:
- specify which operations require authentication,
- specify how the client presents auth proof (token/session/etc.),
- specify auth failure behaviors (invalid credentials, unauthenticated, forbidden).

### J. Traceability (Recommended)
Each operation SHOULD list the relevant `REQ-*` IDs it satisfies (recommended for traceability).

---

## Mandatory API Surface Areas by Capability (Normative)
This section defines the **minimum** API operations and contract-visible behaviors required for each capability in the master spec. Implementers MUST express these operations in the chosen API style:
- **REST**: endpoints + methods, or
- **GraphQL**: queries + mutations.

This section intentionally describes **operations** and **fields/behaviors** without mandating endpoint paths, method names, or GraphQL naming.

### General Conventions (Applies to All Capabilities)
- Each operation definition in the contract MUST include:
  - required inputs (parameters/arguments and required body fields),
  - response shape (success and error),
  - validation constraints (bounds/lengths/enums where applicable),
  - required error categories (from section **F**),
  - pagination + ordering rules for collection results (if operation returns a collection).

---

### Model A — Animals (Intake / Update / Get / List)
Required operations (contract MUST define equivalents):
- **IntakeAnimal**
  - Inputs MUST include: `species`, `description`, and optional `name`, `ageYears`, `tags[]`, `images[]` association if supported on intake.
  - Response MUST include: `animalId` and the created Animal representation (including initial `status`).
  - Errors MUST include: ValidationError.
- **UpdateAnimal**
  - Inputs MUST include: `animalId` and update fields.
  - Contract MUST state immutable fields (at minimum `animalId`) and the error behavior when attempted.
  - Errors MUST include: ValidationError, NotFound.
- **GetAnimal**
  - Inputs MUST include: `animalId`.
  - Response MUST include: Animal representation including `status`, `tags[]`, `images[]` (or image references).
  - Errors MUST include: NotFound.
- **ListAnimals**
  - Inputs MUST include: pagination parameters and `status` filter parameters.
  - Response MUST include: a collection of Animals and the pagination response fields (offset or cursor).
  - Contract MUST define deterministic ordering and tie-break rules (`REQ-API-0002-A`).
  - Errors MUST include: ValidationError (for invalid pagination inputs).

Animal representation (minimum contract-visible fields):
- `animalId` (required)
- `species` (required)
- `description` (required)
- `status` (required)
- `tags[]` (required; may be empty)
- `images[]` (required; may be empty; entries may be metadata objects or references)

---

### Model A — Lifecycle Transitions (State Machine Enforcement)
Required operations (contract MUST define equivalents):
- **TransitionAnimalStatus**
  - Inputs MUST include: `animalId`, `fromStatus`, `toStatus`, and `reason`.
  - Contract MUST enumerate the allowed lifecycle states and allowed transitions (or reference a single source of truth section within the contract).
  - If `toStatus` is not valid from the current status → Conflict (recommended) or ValidationError (must be explicit).
  - If `fromStatus` does not match current state (stale request) → Conflict (recommended; must be explicit).
  - Response MUST include the updated Animal `status` and SHOULD return the created History Event.

---

### Model A — Adoption Applications (Submit / Evaluate / Decision)
Required operations (contract MUST define equivalents):
- **SubmitAdoptionApplication**
  - Inputs MUST include: `animalId` and the contract-defined adopter/application fields (name, email, household details).
  - Inputs MUST NOT include: `applicationId` (auto-generated), adopter identifier/key (auto-generated), or timestamps.
  - Success MUST create `applicationId` and any adopter identifier needed for tracking.
  - Eligibility MUST be explicit: at minimum, animal must be `AVAILABLE`.
  - Errors MUST include: ValidationError, NotFound (unknown `animalId`), Conflict (animal not eligible or policy violation).
- **EvaluateAdoptionApplication**
  - Inputs MUST include: `applicationId`.
  - Response MUST include: evaluation outcome and a required human-readable `explanation`.
  - Errors MUST include: NotFound, Conflict (if evaluation is not allowed in current workflow state), ValidationError (if applicable).
- **RecordAdoptionDecision**
  - Inputs MUST include: `applicationId`, `decision` (APPROVE/REJECT), and required human-readable `explanation`.
  - Contract MUST define override semantics (e.g., `overrodeEvaluation`) and require an explanation regardless.
  - Errors MUST include: NotFound, Conflict (invalid workflow/lifecycle state), ValidationError.

Contract-visible workflow state:
- The contract MUST specify how application state is represented (e.g., `applicationStatus`) and which operations are permitted in which states.
- The contract MUST declare one multi-application policy (P1 or P2) and how conflicts are surfaced.

---

### Model A — Animal History (Audit)
Required operations (contract MUST define equivalents):
- **GetAnimalHistory**
  - Inputs MUST include: `animalId` and pagination parameters.
  - Response MUST be an ordered collection of History Events with deterministic ordering + tie-break rules.
  - History Event minimum fields MUST include:
    - `historyEventId` (or stable identifier)
    - `animalId`
    - `eventType` (e.g., INTAKE, STATUS_TRANSITION, APPLICATION_SUBMITTED, APPLICATION_EVALUATED, DECISION_RECORDED, OVERRIDE_RECORDED)
    - `occurredAt` (if present; deterministic for seed)
    - `performedBy` (or equivalent actor identity; may be “system” for automated steps)
    - `reason` or `explanation` (human-readable; required for transitions/decisions)
  - Errors MUST include: NotFound (unknown animal).

---

### Model A — Images (Associate/Add/Remove + Retrieval)
This section is intentionally high-level; detailed constraints are in `docs/Image_Handling.md`.

Required contract-defined behaviors:
- The contract MUST specify whether images are:
  - uploaded binary/media stored locally (e.g., filesystem) and served via the API, OR
  - stored as image references with deterministic placeholder content served via the API (no external integrations).
- The contract MUST define the image association model: image records/references are associated to exactly one `animalId` unless otherwise stated.

Required operations (contract MUST define equivalents):
- **AddImageToAnimal**
- **RemoveImageFromAnimal**
- **GetImageMetadata** — retrieve image metadata by `imageId`
- **GetImageContent** — retrieve image binary content by `imageId` (MUST return valid image bytes with correct `Content-Type`; for stored references, return deterministic placeholder bytes)

Minimum image metadata/reference fields (if images are structured objects):
- `imageId` OR stable reference string
- `contentType` (required; e.g., `image/jpeg`)
- `fileName`
- `ordinal` (for deterministic ordering)
- `contentUrl` (required; URL/path to retrieve image content)

---

### Model B — Search Animals
Required operations (contract MUST define equivalents):
- **SearchAnimals**
  - Inputs MUST include: `query` and pagination parameters; MAY include status filter reuse if supported.
  - Contract MUST define matching semantics, including:
    - which fields are searched (at minimum `name`, `description`, and `tags`),
    - case sensitivity,
    - substring vs token matching (and any tokenization rules).
  - Contract MUST define empty-query behavior (ValidationError vs match-all).
  - Contract MUST define deterministic ordering + tie-break rules (`REQ-API-0101-B`).
  - Errors MUST include: ValidationError (invalid query/pagination).

---

### Model B — Accounts/Auth + Roles
Required operations (contract MUST define equivalents):
- **RegisterUser**
- **Login**
- **Logout / InvalidateAuthProof** (if applicable)

Required contract-wide elements:
- Protected operations list: which operations require authentication (recommended: intake, transitions, evaluate, decision).
- Role/permission model: how staff/admin are represented and enforced.

---

## Cross-Cutting Contract Rules + Benchmark Hooks (Normative)

### Filtering and Sorting (What Is Required vs Optional)
- The contract MUST explicitly list supported filters per collection operation (e.g., `status` filter on ListAnimals).
- If a filter is not supported, the contract MUST define how the API represents that (e.g., ValidationError for unknown filter parameters/arguments).
- Sorting:
  - The contract MUST define whether the caller can choose sort keys or whether a single fixed ordering is used.
  - If caller-selectable sort is supported, the contract MUST list supported sort keys and directions and MUST define tie-break rules.

### Deterministic Ordering + Tie-Break Rules (Applies Everywhere)
For every collection operation (ListAnimals, SearchAnimals, GetAnimalHistory, etc.), the contract MUST specify:
- Primary ordering keys (e.g., by `createdAt desc`)
- Deterministic tie-break rule(s) (e.g., `animalId asc`, `historyEventId asc`)
- Whether ordering is fixed or caller-selectable

### Idempotency and “Safe Replays”
To support benchmarking (retries, flaky runs), the contract SHOULD specify idempotency expectations:
- Intake operations: whether duplicate submits are allowed and how conflicts are surfaced.
- Transition operations: whether repeating a transition is conflict/no-op (must be explicit).
- Decision operations: whether repeating a decision is conflict/no-op (must be explicit).
- Reset-to-seed (if exposed via API): MUST be idempotent.

---

## Contract Completeness Checklist (Benchmark-Ready)
Use this checklist to evaluate an implementation’s contract artifact without reading code.

### Global
- [ ] Artifact clearly declares: API style (REST or GraphQL), contract version, and target model (A or B).
- [ ] Artifact enumerates all required operations and their request/response shapes.
- [ ] Error model defined with minimum required categories and observable mapping.
- [ ] Pagination style defined for each collection operation (list/search/history/applications), including parameters and responses.
- [ ] Deterministic ordering + tie-break rules explicitly specified for required collection operations.
- [ ] Lifecycle state machine is enumerated and transition enforcement error behavior is explicit.
- [ ] Every evaluation and decision includes required human-readable `explanation` fields in responses.


