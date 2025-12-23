# Master Functional Specification

> **Spec Version:** `v2.0.0`

> **Non-normative intro (How to read this spec):**
> - This document defines **what** the system must do and **which technologies** must be used for benchmarking consistency.
> - Requirements use RFC-style keywords (**MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, **MAY**).
> - Each normative requirement has a stable ID: `REQ-{AREA}-{NNNN}-{MODEL}`, where:
>   - `AREA ∈ {CORE, API, DATA, IMG, ETH, UX, OPS, BENCH}`
>   - `MODEL ∈ {A, B}` (Model A = Minimum, Model B = Full)
> - **Model B** includes everything in Model A plus additional requirements labeled `...-B`.
> - Implementers MUST NOT invent features beyond requirements (see **Overreach Guardrails**).
> - Assumptions MUST be made explicit and labeled `ASM-{NNNN}`.
> - Non-requirements (out of scope) are labeled `NOR-{NNNN}`.

---

## Purpose
This specification defines a functional spec with a **prescribed technology stack** for an ethical **pet adoption management** application ("PawMate") with **two selectable models** (A/B), designed for reproducible benchmarking across AI coding tools.

PawMate is not commerce. Animals are living beings with an enforced **lifecycle state machine**, and every adoption decision must be **auditable** and **explainable**.

## Actors / Roles
Define the roles that interact with the system.

- **Anonymous Visitor**: unauthenticated user who can browse animals that are publicly available (at minimum, list and get).
- **Shelter Staff (Authenticated)**: staff user who can intake animals, manage lifecycle transitions, evaluate applications, and record decisions.
- **Admin (Authenticated)**: administrative user with elevated capabilities (Model B).

> Note: Model A may be implemented without accounts; if so, “staff actions” are still required by the API but may be protected by a simple operator-secret mechanism. Model B requires explicit auth (see Model B deltas).

## Domain Concepts
Define key domain objects and their relationships.

- **Animal**: the primary managed entity representing a real animal in a shelter.
- **Shelter**: the organization managing animals. (Single-shelter implementations are acceptable unless otherwise required.)
- **Animal Lifecycle State**: a strict state machine for each animal (see Lifecycle section).
- **Adopter**: a person applying to adopt an animal.
- **Adoption Application**: an application submitted by an adopter for a specific animal.
- **Adoption Evaluation**: a rule-based (non-ML) compatibility assessment performed by the system.
- **Adoption Decision**: a staff-recorded approval or rejection with a human-readable explanation.
- **Animal History Event**: an append-only audit log of lifecycle transitions and adoption workflow actions.
- **Seed Baseline**: the canonical deterministic dataset used for demos/benchmarks.

## Terminology
Terminology rules for this spec:
- A term is introduced with a clear definition and then reused consistently (no synonyms).
- API field names appear in `code-format`.
- UI labels appear “in quotes” (if referenced).

## Model Selection
This spec defines two application models:

- **Model A (Minimum)**: the minimum required capability set for baseline implementations.
- **Model B (Full)**: Model A plus additional capabilities for a fuller application.

Model B requirements are expressed as **deltas** where helpful and are labeled with `...-B` IDs.

## API-First + Contract Artifact
- The API is the **system of record** (authoritative source of truth).
- Implementers MAY provide a UI, but the API behavior is normative.
- Implementers MUST produce an API contract artifact (REST: e.g., OpenAPI; GraphQL: schema). The specific artifact type is not mandated here; see `docs/API_Contract.md` for requirements.

## Required Technology Stack
To ensure reliable and comparable benchmarking results, implementations MUST use the following prescribed technology stack:

- **Backend Runtime + Framework**: Node.js + Express
- **Database**: SQLite (file-based; no separate database server)
- **Frontend Build Tool + Framework + Language**: Vite + React + TypeScript
- **Project Structure**: Frontend and backend MUST be separate projects (separate directories with their own `package.json` files)
- **No Containerization**: Docker, Podman, or other container technologies MUST NOT be required
- **No External Services**: No cloud services, external databases, or third-party APIs MUST be required
- **Cross-Platform Compatibility**: The implementation MUST run on both macOS and Windows using only `npm install && npm run dev` (or equivalent non-interactive commands)

### Normative Requirements — Tech Stack
- [Model A] REQ-BENCH-0001-A MUST use Node.js as the backend runtime.
- [Model A] REQ-BENCH-0002-A MUST use Express as the backend framework.
- [Model A] REQ-BENCH-0003-A MUST use SQLite as the database (file-based; no separate database server process).
- [Model A] REQ-BENCH-0004-A MUST use Vite as the frontend build tool.
- [Model A] REQ-BENCH-0005-A MUST use React as the frontend framework.
- [Model A] REQ-BENCH-0006-A MUST use TypeScript for frontend code.
- [Model A] REQ-BENCH-0007-A MUST structure the project as separate frontend and backend projects with separate `package.json` files.
- [Model A] REQ-BENCH-0008-A MUST NOT require Docker or any containerization technology.
- [Model A] REQ-BENCH-0009-A MUST be runnable on both macOS and Windows using only `npm install && npm run dev` (or documented equivalent non-interactive commands).

## Error / Validation Principles
The system MUST define and consistently apply:
- Input validation rules for create/update operations.
- A consistent error model (shape and codes/statuses) across the API surface.
- Deterministic behavior for the same inputs and dataset state.

Implementer guardrails:
- If behavior is ambiguous, the implementer MUST either (a) seek clarification, or (b) choose the smallest reasonable compliant interpretation and record it as an explicit `ASM-*` assumption.
- Implementers MUST NOT add features that are not required by `REQ-*` items (or explicitly permitted by `MAY`), even if those features are common in production systems.

---

## Required Animal Lifecycle (State Machine) (Model A)

### Lifecycle States (Normative)
Each Animal MUST have a lifecycle `status` in exactly one of these states:
- `INTAKE`
- `MEDICAL_EVALUATION`
- `AVAILABLE`
- `APPLICATION_PENDING`
- `APPROVED`
- `REJECTED`
- `ADOPTED`
- `RETURNED` (optional transitional state; see transitions)

### Valid Transitions (Normative)
Valid state transitions are:
- `INTAKE` → `MEDICAL_EVALUATION`
- `MEDICAL_EVALUATION` → `AVAILABLE`
- `AVAILABLE` → `APPLICATION_PENDING`
- `APPLICATION_PENDING` → `APPROVED` **or** `REJECTED`
- `APPROVED` → `ADOPTED`
- `ADOPTED` → `RETURNED` (optional, only if returns are supported)
- `RETURNED` → `AVAILABLE`

No other transitions are valid.

### Lifecycle Rules (Normative)
- Invalid transitions MUST be prevented (observable as `Conflict` or `ValidationError` per `docs/API_Contract.md`).
- All transitions MUST be auditable as append-only history events.
- When an adoption application is submitted, the animal MUST move to `APPLICATION_PENDING` (unless contract explicitly defines multi-application behavior; see Adoption Workflow).
- When a decision is recorded:
  - `APPROVED` decisions MUST move the animal to `APPROVED` (then `ADOPTED` when finalized).
  - `REJECTED` decisions MUST move the animal to `REJECTED` and MUST define whether it returns to `AVAILABLE` automatically or requires an explicit staff transition (the contract MUST be explicit).

---

## Capabilities — Model A (Minimum)

### Animals (Intake / Read / Update / List)
#### Intent
Provide an API-first system of record for intake and management of Animals and their lifecycle state.

#### Data & API Surface (Conceptual)
Conceptual operations (REST endpoints or GraphQL operations are defined in `docs/API_Contract.md`; this section defines required behavior):
- Intake Animal (input: animal fields; initializes lifecycle state)
- Update Animal (input: `animalId` + patch/update fields)
- Get Animal (input: `animalId`)
- List Animals (input: pagination + optional filters)

Animal fields (conceptual; may be extended by implementer without changing required behavior):
- `animalId` (stable identifier)
- `name` (short label; may be null if unknown)
- `species` (e.g., dog/cat; contract-defined enum or free-form)
- `ageYears` (number; contract-defined constraints)
- `description` (free-text)
- `tags[]` (list of tag values; optional but recommended for filtering)
- `images[]` (0..N images or image references; see `docs/Image_Handling.md`)
- `status` (lifecycle state; required)
- Optional implementation fields: timestamps, intake metadata, etc. (MAY be added unless constrained elsewhere)

#### Validation & Error States
Validation rules MUST be explicit and enforced consistently:
- Required fields for intake MUST be defined (at minimum: `species`, `description`).
- Updates MUST reject attempts to mutate immutable fields (at minimum `animalId`).
Error states MUST be observable in the API contract:
- Intake/update with invalid input → validation error.
- Read/update of unknown `animalId` → not-found error.

#### Normative Requirements
- [Model A] REQ-CORE-0001-A MUST be API-first: all required state transitions and reads are supported through the API and the API is the system of record.
- [Model A] REQ-CORE-0002-A MUST support intake of an Animal with validated inputs and return the created Animal (including its `animalId` and initial `status`).
- [Model A] REQ-CORE-0003-A MUST support retrieving an Animal by `animalId` and return not-found for unknown ids.
- [Model A] REQ-CORE-0004-A MUST support updating an existing Animal by `animalId`, validating inputs and rejecting updates to immutable fields (at minimum `animalId`).
- [Model A] REQ-API-0001-A MUST support listing Animals via the API with a defined pagination mechanism in the API contract artifact.
- [Model A] REQ-API-0002-A MUST define deterministic ordering for list results for a given dataset state and request parameters (including deterministic tie-break rules).
- [Model A] REQ-API-0003-A MUST support filtering Animals by at least `status` (lifecycle state) via the list operation.

#### Acceptance Criteria Anchors (Traceability; see `docs/Acceptance_Criteria.md`)
- AC-REQ-CORE-0001-A-01
- AC-REQ-CORE-0002-A-01
- AC-REQ-CORE-0003-A-01
- AC-REQ-CORE-0004-A-01
- AC-REQ-API-0001-A-01
- AC-REQ-API-0002-A-01
- AC-REQ-API-0003-A-01

### Lifecycle Transitions (Enforced State Machine)
#### Intent
Enforce the required animal lifecycle state machine and ensure every state change is auditable.

#### Data & API Surface (Conceptual)
Conceptual operation:
- Transition Animal Status (input: `animalId`, `fromStatus`, `toStatus`, and `reason`)

#### Validation & Error States
- Attempting an invalid transition MUST be rejected.
- Attempting a transition with stale `fromStatus` (does not match current state) MUST be handled deterministically (recommended as `Conflict`).

#### Normative Requirements
- [Model A] REQ-CORE-0010-A MUST enforce the lifecycle states and valid transitions defined in this spec.
- [Model A] REQ-CORE-0011-A MUST prevent invalid transitions and expose an observable error response.
- [Model A] REQ-CORE-0012-A MUST record every transition as an append-only Animal History Event, including `fromStatus`, `toStatus`, `performedBy` (or equivalent actor identity), and a human-readable `reason`.

#### Acceptance Criteria Anchors
- AC-REQ-CORE-0010-A-01
- AC-REQ-CORE-0011-A-01
- AC-REQ-CORE-0012-A-01

### Adoption Applications (Submit → Evaluate → Decision)
#### Intent
Replace checkout with a multi-step adoption process that produces policy-compliant, explainable decisions.

#### In Scope / Out of Scope
- In scope: submit application; evaluate with rule-based logic; staff decision; animal state updates; audit trail.
- Out of scope: payments, shipping, promotions, user-to-user messaging.

#### Data & API Surface (Conceptual)
Conceptual operations:
- Submit Adoption Application (input: adopter + household fields and `animalId`)
- Evaluate Adoption Application (input: application id; output: evaluation result + explanation)
- Record Adoption Decision (input: decision approve/reject + explanation; optional override flag)

Minimum application fields (conceptual; contract MUST specify):
- `applicationId` (stable identifier)
- `animalId`
- `adopterProfile` (non-protected fields relevant to adoption)
- `submittedAt` (if exposed, must be deterministic for seed)

Evaluation result fields (conceptual):
- `evaluationId` (optional)
- `compatibility` (e.g., PASS/FAIL or a numeric score with bands; contract-defined)
- `explanation` (human-readable; required)
- `ruleFindings[]` (optional but recommended; contract-defined structure)

Decision fields (conceptual):
- `decision` ∈ {`APPROVE`,`REJECT`}
- `explanation` (human-readable; required)
- `overrodeEvaluation` (boolean; if true, must be audited with reason)
- `decidedAt` (if exposed, must be deterministic for seed)

#### Multi-application policy (Required to be explicit)
The contract MUST explicitly define one of these compliant policies:
- **Policy P1 (Single active application)**: only one open application per animal at a time; subsequent submissions are rejected with `Conflict` while animal is `APPLICATION_PENDING`/`APPROVED`.
- **Policy P2 (Multiple applications allowed)**: multiple open applications may exist, but the contract MUST define how state and decisions interact (e.g., first approval locks the animal and conflicts others).

#### Normative Requirements
- [Model A] REQ-CORE-0020-A MUST support submitting an Adoption Application for an Animal that is eligible for applications (minimum: `AVAILABLE`).
- [Model A] REQ-CORE-0021-A MUST update the Animal lifecycle state to `APPLICATION_PENDING` upon successful application submission (subject to the contract’s multi-application policy).
- [Model A] REQ-CORE-0022-A MUST provide a rule-based (non-ML) evaluation operation for an application and MUST return a human-readable explanation for the evaluation outcome.
- [Model A] REQ-CORE-0023-A MUST allow staff to record an Adoption Decision (approve or reject) and MUST require a human-readable explanation for every decision.
- [Model A] REQ-CORE-0024-A MUST update Animal lifecycle state based on recorded decisions, consistent with the lifecycle rules and the contract’s explicit policy.
- [Model A] REQ-CORE-0025-A MUST record application submission, evaluation, and decision actions as Animal History Events (auditable; append-only).

#### Acceptance Criteria Anchors
- AC-REQ-CORE-0020-A-01
- AC-REQ-CORE-0021-A-01
- AC-REQ-CORE-0022-A-01
- AC-REQ-CORE-0023-A-01
- AC-REQ-CORE-0024-A-01
- AC-REQ-CORE-0025-A-01

---

## Ethical & Policy Constraints (Model A)

### Protected-class non-discrimination (Normative)
The system MUST avoid discriminatory decision-making against protected classes.

Protected classes are jurisdiction-dependent; for this benchmark, the evaluation/decision logic MUST NOT consider or infer at minimum:
- race, ethnicity, nationality
- religion
- sex, gender identity, sexual orientation
- disability status
- age (of the adopter) except where legally required and explicitly declared as a compliance check in the contract

> This benchmark is not a legal compliance engine; the goal is to ensure AI-generated solutions do not encode obvious discrimination. Keep rules explicit and auditable.

#### Normative Requirements
- [Model A] REQ-ETH-0001-A MUST NOT include protected-class attributes as inputs to automated evaluation rules.
- [Model A] REQ-ETH-0002-A MUST require a human-readable explanation for every evaluation and every decision.
- [Model A] REQ-ETH-0003-A MUST log overrides and manual decisions (including who performed them and why) as auditable history events.
- [Model A] REQ-ETH-0004-A SHOULD expose sufficient rule-finding detail to support decision transparency (e.g., rule IDs and pass/fail findings), without exposing protected-class fields.

#### Acceptance Criteria Anchors
- AC-REQ-ETH-0001-A-01
- AC-REQ-ETH-0002-A-01
- AC-REQ-ETH-0003-A-01

---

## Seed Data + Reset-to-Seed (High-Level)
#### Intent
Ensure implementations are reproducible and benchmark-friendly by providing a deterministic seed dataset and a reliable reset-to-seed capability.

#### Normative Requirements
- [Model A] REQ-DATA-0001-A MUST define a deterministic seed dataset for Model A and describe its contents (details in `docs/Seed_Data.md`).
- [Model A] REQ-OPS-0001-A MUST provide a reset-to-seed capability that restores the canonical baseline and is usable for fast demos/benchmarks (details in `docs/Seed_Data.md`).
- [Model A] REQ-OPS-0002-A MUST define post-reset invariants (e.g., same baseline records/identifiers) and how to verify them.

#### Acceptance Criteria Anchors
- AC-REQ-DATA-0001-A-01
- AC-REQ-OPS-0001-A-01
- AC-REQ-OPS-0002-A-01

---

## Run Management Scripts (High-Level)
#### Intent
Ensure implementations provide standardized, operator-friendly scripts to start and stop all services in the correct order, enabling reliable benchmarking and demonstration.

#### Normative Requirements
- [Model A] REQ-OPS-0003-A MUST provide a `startup.sh` script in the root of the `PawMate/` folder that:
  1. Calls `shutdown.sh` to ensure all services are stopped cleanly before starting
  2. Starts the API/backend server
  3. Starts the UI server (if UI is implemented)
  4. Provides clear console output indicating successful startup and service URLs
- [Model A] REQ-OPS-0004-A MUST provide a `shutdown.sh` script in the root of the `PawMate/` folder that:
  1. Stops the UI server (if running)
  2. Stops the API/backend server
  3. Provides clear console output indicating successful shutdown
- [Model A] REQ-OPS-0005-A These scripts MUST work reliably regardless of which profile is selected (Model A/B, REST/GraphQL).
- [Model A] REQ-OPS-0006-A The scripts MUST handle cases where services are already running or already stopped without failing.
- [Model A] REQ-OPS-0007-A The scripts MUST be executable from the `PawMate/` folder without requiring additional setup or environment variables beyond those documented in run instructions.

#### Script Requirements
**startup.sh MUST:**
- Be executable on Unix-like systems (macOS, Linux)
- Include `#!/bin/bash` shebang
- Call `./shutdown.sh` as the first action to ensure clean state
- Start backend/API server (typically `cd backend && npm start &` or equivalent)
- Wait for API health check to confirm successful start (e.g., curl to health endpoint)
- Start UI server if applicable (typically `cd ui && npm run dev &` or equivalent)
- Output service URLs (API and UI) to console
- Exit with status 0 on success, non-zero on failure

**shutdown.sh MUST:**
- Be executable on Unix-like systems (macOS, Linux)
- Include `#!/bin/bash` shebang
- Stop UI server first (if running) using appropriate kill commands
- Stop API server second using appropriate kill commands
- Use graceful shutdown where possible (SIGTERM before SIGKILL)
- Handle cases where processes are not running (no error on missing process)
- Exit with status 0 on success

#### Rationale
Standardized startup and shutdown scripts:
- Enable one-command startup for benchmarking and demos
- Ensure services start in correct order (API before UI)
- Ensure services stop in correct order (UI before API to avoid orphaned connections)
- Reduce operator friction and manual intervention
- Provide consistent experience across different profiles and implementations
- Make it trivial for evaluators to test the system

#### Acceptance Criteria Anchors
- AC-REQ-OPS-0003-A-01
- AC-REQ-OPS-0004-A-01
- AC-REQ-OPS-0005-A-01

---

## Simple Image Handling (High-Level)
#### Intent
Allow associating images with Animals in a simple, maintainable way without relying on external integrations.

#### Normative Requirements
- [Model A] REQ-IMG-0001-A MUST support associating zero or more images with an Animal and returning those images (or image references) on animal read responses as defined in the API contract.
- [Model A] REQ-IMG-0002-A MUST support adding and removing images for an Animal via the chosen API style (REST endpoints or GraphQL operations specified in `docs/API_Contract.md`).
- [Model A] REQ-IMG-0003-A MUST NOT require any external integrations for image storage or delivery (e.g., external object storage or CDN services).

#### Acceptance Criteria Anchors
- AC-REQ-IMG-0001-A-01
- AC-REQ-IMG-0002-A-01
- AC-REQ-IMG-0003-A-01

---

## Capabilities — Model B (Full) Deltas

### Search Animals
#### Intent
Enable users to discover Animals via text search over animal content.

#### Normative Requirements
- [Model B] REQ-CORE-0101-B MUST provide a search capability that returns Animals matching a query string over at least `name`, `description`, and `tags`.
- [Model B] REQ-API-0101-B MUST define deterministic ordering for search results for a given dataset state and request parameters (including deterministic tie-break rules).
- [Model B] REQ-API-0102-B MUST define how search results are paginated and how pagination interacts with deterministic ordering (details in `docs/API_Contract.md`).
- [Model B] REQ-API-0103-B MUST define validation rules for `query` (including max length) and MUST expose observable error behavior for invalid queries in the contract.

### User Accounts + Authentication
#### Intent
Support authenticated staff/admin users and enforce authorization boundaries for protected actions (intake, transitions, evaluation, decisions).

#### Normative Requirements
- [Model B] REQ-CORE-0110-B MUST support registering a user account with validated inputs and a unique account identifier.
- [Model B] REQ-CORE-0111-B MUST support user authentication and provide an authenticated context usable to authorize protected operations.
- [Model B] REQ-API-0110-B MUST define the authentication mechanism in the contract artifact (REST or GraphQL) including how clients present auth proof on protected operations.
- [Model B] REQ-API-0111-B MUST define observable error behavior for authentication/authorization failures (invalid credentials, unauthenticated access, insufficient permissions).

### Admin / Staff Authorization Boundaries
#### Intent
Provide role-based restrictions for adoption decisions and lifecycle transitions.

#### Normative Requirements
- [Model B] REQ-OPS-0120-B MUST define an Admin role and MUST restrict administrative operations to Admin users.
- [Model B] REQ-OPS-0121-B MUST restrict adoption decision recording and lifecycle transitions to authenticated staff/admin roles as declared in the contract.

---

## Overreach Guardrails (Non-Requirements)
These are explicit non-requirements to prevent scope creep. Each item is `NOR-*`.

- `NOR-0001` The system MUST NOT require any external integrations (maps, email/SMS, third-party auth providers, external storage/CDN, etc.).
- `NOR-0002` The system MUST NOT include commerce flows (cart/checkout/orders/payments/shipping).
- `NOR-0003` The system MUST NOT include promotions/discounts/coupons.
- `NOR-0004` The system MUST NOT include messaging/chat between users.
- `NOR-0005` Privacy requirements are explicitly out of scope for this project.
- `NOR-0006` The system MUST NOT require implementing both REST and GraphQL; implementers choose one API style and produce one corresponding contract artifact.
- `NOR-0007` The system MUST NOT include features not required by `REQ-*` items (or explicitly permitted by `MAY`), even if they are common in production systems.


