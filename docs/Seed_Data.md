# Deterministic Seed Data — Model A + Model B

## Purpose
This document defines a **canonical deterministic seed dataset** to support reproducible demos and benchmarking across AI-generated implementations.

It supports:
- Model A requirements: `REQ-DATA-0001-A`, `REQ-OPS-0001-A`, `REQ-OPS-0002-A`
- Contract expectations in `docs/API_Contract.md` (deterministic ordering, lifecycle enforcement, adoption workflow determinism, etc.)

This document is **technology-agnostic** and compatible with **REST or GraphQL** implementations.

---

## Determinism Principles (Normative)
- Seed data MUST be **fully deterministic**: the same seed operation produces the same baseline entities with the same identifiers and key fields.
- Identifiers in this appendix are **canonical conceptual IDs**. Implementations MAY store different internal IDs, but MUST expose stable IDs through the API that can be mapped to these conceptual IDs for verification.
- Timestamps included here are fixed constants in ISO-8601 UTC (`YYYY-MM-DDTHH:MM:SSZ`) for repeatable ordering tests. If an implementation exposes timestamps, it MUST preserve these values for seed records.

---

## Canonical Tag Set (Shared)
The seed uses a small, fixed tag vocabulary. Tags are strings.

Tag values (exact, lowercase):
- `dog`
- `cat`
- `adoptable`
- `foster`
- `kitten`
- `puppy`
- `senior`
- `vaccinated`
- `special-needs`
- `behavior-support`
- `indoor-only`

---

## Model A — Canonical Seed Dataset

### Model A Counts (Normative)
Model A seed MUST include at minimum:
- **Animals**: 12
- **Adoption Applications**: 6 (spanning eligible and ineligible scenarios)
- **History Events**: at least 40 (to exercise pagination + ordering determinism)
- **Images**:
  - At least 3 animals with **0 images**
  - At least 3 animals with **1 image**
  - At least 1 animal with **3 images** (seed-defined “max coverage”)

> Note: `docs/Image_Handling.md` defines formal image constraints. For seed coverage, this document uses **up to 3 images per animal** to ensure at least one “max images” case exists in the baseline.

---

### Model A Animals (Normative)
All animals MUST exist with these canonical IDs and key fields.

**Animal fields included in seed verification**
- `animalId` (canonical)
- `name`
- `species`
- `description`
- `status`
- `tags[]`
- `createdAt`
- `updatedAt`

#### Golden Animals (for benchmark verification)
These “golden” animals MUST exist exactly as specified:

| animalId | name | species | status | tags | createdAt | updatedAt |
|---|---|---|---|---|---|---|
| ANM-0001 | Luna | cat | AVAILABLE | `cat,adoptable,senior,vaccinated` | 2025-01-12T10:00:00Z | 2025-01-12T10:00:00Z |
| ANM-0002 | Milo | dog | AVAILABLE | `dog,adoptable,puppy,vaccinated` | 2025-01-13T10:00:00Z | 2025-01-13T10:00:00Z |
| ANM-0003 | Bella | dog | MEDICAL_EVALUATION | `dog,foster,special-needs` | 2025-01-14T10:00:00Z | 2025-01-14T10:00:00Z |
| ANM-0004 | Oreo | cat | AVAILABLE | `cat,adoptable,kitten,indoor-only` | 2025-01-15T10:00:00Z | 2025-01-15T10:00:00Z |
| ANM-0005 | Shadow | dog | ADOPTED | `dog,senior,adoptable` | 2025-01-16T10:00:00Z | 2025-01-16T10:00:00Z |

**Descriptions (golden records)**
- ANM-0001 description MUST contain: `Calm senior cat; great with quiet homes.`
- ANM-0002 description MUST contain: `Playful puppy; loves fetch.`
- ANM-0003 description MUST contain: `Tripod dog; needs gentle walks.`
- ANM-0004 description MUST contain: `Curious kitten; best as indoor-only.`
- ANM-0005 description MUST contain: `Senior dog; house-trained and calm.`

#### Remaining Animals (to reach 12 total)
The seed MUST include the following additional animal IDs (details may be minimal but MUST be deterministic and include tags + timestamps + valid lifecycle states):
- ANM-0006
- ANM-0007
- ANM-0008
- ANM-0009
- ANM-0010
- ANM-0011
- ANM-0012

For each of ANM-0006..ANM-0012, the seed MUST define:
- deterministic `name` (or null if unknown), `species`, and `description`,
- at least 1 tag from the canonical set,
- deterministic `createdAt` and `updatedAt` values,
- a valid `status` from the lifecycle state set.

---

### Model A Adoption Applications (Normative; Benchmark-Critical)
Applications MUST be seeded to exercise:
- eligibility rules (animal must be `AVAILABLE`),
- multi-application policy (contract must declare policy P1 or P2),
- evaluation explanations,
- decision explanations and overrides.

#### Canonical Adopter Identities
Model A does not require user accounts. Seed uses stable applicant identities as if provided by clients:
- `ADP-ALPHA`
- `ADP-BRAVO`
- `ADP-CHARLIE`
- `ADP-DELTA`

The API contract MUST specify the field name(s) used for applicant identity (e.g., `adopterKey`), but these values MUST be representable.

#### Seeded Applications (Minimum Required)
The seed MUST include at least the following canonical applications:

| applicationId | animalId | adopterKey | submittedAt |
|---|---|---|---|
| APP-0001 | ANM-0001 | ADP-ALPHA | 2025-01-20T10:00:00Z |
| APP-0002 | ANM-0002 | ADP-BRAVO | 2025-01-20T11:00:00Z |
| APP-0003 | ANM-0004 | ADP-CHARLIE | 2025-01-20T12:00:00Z |
| APP-0004 | ANM-0001 | ADP-DELTA | 2025-01-20T13:00:00Z |

To reach 6 total applications, seed MUST include:
- APP-0005..APP-0006 with deterministic animal/adopter associations and timestamps.

#### Seeded Evaluation + Decision Coverage (Required, but contract-defined)
The seed MUST support deterministic verification that:
- evaluation returns a **human-readable explanation** for APP-0001 and APP-0002,
- staff decision returns a **human-readable explanation** for at least one approval and at least one rejection,
- at least one decision is marked as an **override** of the evaluation (overrodeEvaluation=true) and is auditable in history.

> TODO (intentional): This document does not mandate the exact evaluation rule set. The contract MUST declare rule semantics so evaluation outcomes are testable and deterministic.

---

### Model A History Events (Normative)
History MUST be seeded to exercise deterministic ordering + pagination.

Minimum required event types present in the seed:
- `INTAKE`
- `STATUS_TRANSITION`
- `APPLICATION_SUBMITTED`
- `APPLICATION_EVALUATED`
- `DECISION_RECORDED`
- `OVERRIDE_RECORDED` (at least one)

Golden history expectations:
- For ANM-0001, history MUST include events for:
  - intake + status transitions to reach `AVAILABLE`,
  - application submissions (APP-0001 and APP-0004),
  - at least one evaluation event,
  - at least one decision event with an explanation.

---

### Model A Images (Normative)
Seed MUST include image associations to exercise 0/1/3 image cases.

Images are represented as metadata records with:
- `imageId` (canonical)
- `animalId`
- `fileName` (or logical name)
- `contentType` (recommended)
- `ordinal` (recommended; deterministic ordering within animal)

**Golden image associations**
- ANM-0002 has exactly 1 image:
  - IMG-0001 → ANM-0002 (`fileName: milo-1.jpg`, `contentType: image/jpeg`, `ordinal: 1`)
- ANM-0003 has exactly 3 images:
  - IMG-0002 → ANM-0003 (`bella-1.jpg`, `image/jpeg`, `ordinal: 1`)
  - IMG-0003 → ANM-0003 (`bella-2.jpg`, `image/jpeg`, `ordinal: 2`)
  - IMG-0004 → ANM-0003 (`bella-3.jpg`, `image/jpeg`, `ordinal: 3`)

Zero-image coverage:
- At least 3 animals (e.g., ANM-0006, ANM-0007, ANM-0008) MUST have `images[]` empty.

---

## Model B — Additional Seed Dataset (Model A + B Entities)

### Model B Counts (Normative)
Model B seed MUST include at minimum (in addition to Model A seed):
- **Users**: 4 (including 1 admin and at least 1 staff role)

Search coverage requirement:
- The seed MUST include animal text content such that a fixed set of queries (below) match deterministic known animal IDs.

---

### Model B Users (Normative)
Seed MUST include these canonical users:

| userId | username | role |
|---|---|---|
| USR-0001 | alice | staff |
| USR-0002 | bob | staff |
| USR-0003 | chris | staff |
| USR-0004 | admin | admin |

Authentication details (passwords/tokens) are intentionally not specified here; the API contract and implementation must provide a benchmark-friendly way to authenticate these users (Model B).

---

### Model B Search Coverage (Normative; Benchmark-Critical)
The following queries MUST match at least these animals (based on the matching semantics declared in the contract artifact):

**Required query → expected matches**
- Query: `senior cat` MUST match ANM-0001
- Query: `puppy` MUST match ANM-0002
- Query: `tripod` MUST match ANM-0003
- Query: `indoor-only` MUST match ANM-0004

The contract MUST define:
- case sensitivity,
- tokenization/substrings,
- how punctuation/hyphens are handled (e.g., `indoor-only`),
so these queries are testable and deterministic.

**Note on Search Field Coverage:**
While the above test queries can all be satisfied by matching terms in the `description` field alone (e.g., "Calm senior cat", "Playful puppy", "Tripod dog", "indoor-only"), implementations MUST search the `tags` field as well per REQ-CORE-0101-B. Tags are structured metadata intended for categorization and discovery (e.g., `vaccinated`, `senior`, `special-needs`, `indoor-only`). Including tags in search provides users with the ability to find animals by specific attributes and characteristics, which is a core use case for the tag system.

---

## Reset-to-Seed Behavior + Post-Reset Invariants (Normative; Benchmark-Critical)

### Reset Invocation (Implementer Choice; Must Be Documented)
Implementations MUST provide reset-to-seed in one of these benchmark-friendly ways:
- **API operation** (REST endpoint or GraphQL mutation), OR
- **Local operation** (documented command/script).

Whichever approach is chosen:
- It MUST be documented in the implementation’s run instructions.
- It MUST be usable non-interactively (no prompts) for benchmarking.

### Reset Semantics (What Is Wiped vs Restored)
On reset-to-seed, the system MUST:
- **Wipe all non-seed data** created after seeding, including at minimum:
  - any animals/applications/history/images created after seed,
  - any user accounts (Model B) created after seed,
  - any staff decisions/overrides performed after seed.
- **Restore the canonical baseline** exactly as defined in this appendix for the selected model:
  - Model A: restore Model A seed dataset only.
  - Model B: restore Model A seed dataset + Model B additional entities.

If reset is exposed via API, it MUST be idempotent and safe to call repeatedly.

### Identifier Stability Requirements
After reset-to-seed:
- All canonical seed identifiers in this appendix MUST be present and stable:
  - `animalId` values ANM-0001..ANM-0012
  - `applicationId` values APP-0001..APP-0006
  - `imageId` values IMG-0001..IMG-0004
  - Model B only: `userId` values USR-0001..USR-0004

### Post-Reset Invariants (MUST)
Immediately after a successful reset-to-seed, the system MUST satisfy:
- **Baseline existence**: all golden animals exist with correct key fields (name/species/description/tags/timestamps/status).
- **Lifecycle enforcement**: seeded statuses are valid lifecycle states.
- **History determinism**:
  - GetAnimalHistory for ANM-0001 returns a deterministic ordering for the same request parameters.
  - History includes required event types listed above.
- **Images determinism**:
  - ANM-0002 has exactly 1 image (IMG-0001).
  - ANM-0003 has exactly 3 images (IMG-0002..IMG-0004) in deterministic order (e.g., by `ordinal`).
  - At least three animals have zero images.
- **Model B invariants (if Model B selected)**:
  - users USR-0001..USR-0004 exist (including admin role for USR-0004).
  - the required search queries match the expected animal IDs per the contract’s matching semantics.

---

## Determinism Checks (MUST)
An implementation MUST satisfy all checks below for the selected model:

#### D-01: Seed Repeatability
- Running the seed procedure produces the same baseline state (same canonical entities, same canonical IDs, same key fields) each time.

#### D-02: Reset Idempotency
- Running reset-to-seed twice in a row results in an identical state after both resets (no drift).

#### D-03: Stable Identifier Mapping
- The API exposes stable identifiers for seeded entities such that a benchmark operator can reliably reference:
  - `animalId` ANM-0001..ANM-0012
  - `applicationId` APP-0001..APP-0006
  - `imageId` IMG-0001..IMG-0004
  - Model B only: `userId` USR-0001..USR-0004

#### D-04: Deterministic Collection Results
- For a fixed dataset state and request parameters, collection operations return deterministic results:
  - ListAnimals ordering and tie-break rules are explicit in the contract (`docs/API_Contract.md`) and are observed in responses.
  - GetAnimalHistory ordering and tie-break rules are explicit in the contract and are observed in responses.
  - SearchAnimals ordering and tie-break rules are explicit in the contract (Model B) and are observed in responses.


