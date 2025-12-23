# UI Implementation Requirements

> **Spec Version:** `v1.0.3`  
> **Purpose:** Define normative requirements and principles for UI implementations that consume the PawMate API

## Document Purpose

This document provides **principles-based guidance** for building user interfaces (web, mobile, desktop) that integrate with PawMate APIs. It ensures UI implementations:
- Discover and correctly consume the API contract artifact
- Understand which fields are user-provided vs system-generated
- Follow conventions appropriate to the API style (REST or GraphQL)
- Provide appropriate user experiences for consumers and staff

**IMPORTANT:** This document does NOT prescribe exact API endpoints or URL patterns. Those decisions are made by the API implementation and documented in the API contract artifact (OpenAPI or GraphQL schema). This document provides principles for UI-API integration.

---

## Relationship to Other Specs

This document is subordinate to:
- `docs/Master_Functional_Spec.md` - Core functional requirements
- `docs/API_Contract.md` - API surface requirements
- `docs/Acceptance_Criteria.md` - Observable behaviors

**Key Principle:** The UI is a **client** of the API. All business logic resides in the API. The UI's job is to:
1. Read the API contract artifact to understand available operations
2. Present data from the API
3. Collect user input according to API requirements
4. Submit requests following the API's conventions
5. Display responses and errors appropriately

---

## REQ-UI-0001-A: API Contract Discovery and Compliance

**NORMATIVE REQUIREMENT**

The UI MUST discover and use API operations from the API contract artifact (OpenAPI spec for REST, GraphQL schema for GraphQL). The UI MUST NOT:
- Invent operations not defined in the contract
- Use different request patterns than specified in the contract
- Send requests to operations that don't exist in the contract

### Contract-Driven Integration (REST)

For REST APIs, the UI MUST:
1. **Locate** the OpenAPI specification file (typically `openapi.yaml` or `openapi.json`)
2. **Read** operation definitions including:
   - HTTP method and path pattern
   - Required vs optional parameters
   - Parameter locations (path, query, header, body)
   - Request body schema (if applicable)
   - Response schema
   - Error responses
3. **Implement** API calls according to the discovered specification

**Example - Reading Operation from OpenAPI:**
```yaml
# OpenAPI defines an operation:
paths:
  /animals:
    post:
      summary: Intake a new animal
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [species, description]
              properties:
                name: { type: string }
                species: { type: string, enum: [dog, cat] }
                description: { type: string }
```

The UI reads this and knows:
- Endpoint: `POST /animals` (or whatever base path + path is defined)
- Required fields: `species`, `description`
- Optional fields: `name`
- Field types and constraints

### Contract-Driven Integration (GraphQL)

For GraphQL APIs, the UI MUST:
1. **Perform introspection** or read the schema file to discover:
   - Available queries and mutations
   - Required vs optional arguments
   - Input types and constraints
   - Return types
2. **Implement** queries/mutations according to the schema

**Example - Reading Operation from GraphQL Schema:**
```graphql
type Mutation {
  intakeAnimal(input: IntakeAnimalInput!): Animal!
}

input IntakeAnimalInput {
  name: String
  species: Species!
  description: String!
  ageYears: Int
  tags: [String!]
}
```

The UI reads this and knows:
- Operation: `intakeAnimal` mutation
- Required fields: `species`, `description`
- Optional fields: `name`, `ageYears`, `tags`
- Field types and constraints

### Required Operations (Model A)

The UI MUST provide interfaces for these functional capabilities (exact endpoint names/paths determined by API implementation):

| Capability | Description | User Type |
|------------|-------------|-----------|
| **Browse Animals** | List/search available animals with filtering | Consumer |
| **View Animal Details** | Get detailed information about one animal | Consumer |
| **View Animal History** | See audit trail of lifecycle events | Consumer/Staff |
| **Submit Application** | Submit adoption application for an animal | Consumer |
| **Intake Animal** | Add new animal to shelter | Staff |
| **Transition Status** | Move animal through lifecycle states | Staff |
| **List Applications** | View submitted applications | Staff |
| **Evaluate Application** | Trigger automatic evaluation | Staff |
| **Record Decision** | Approve or reject evaluated application | Staff |
| **Reset to Seed** | Restore canonical seed data | Staff/Demo |

---

## REQ-UI-0002-A: Field Submission Principles

**NORMATIVE REQUIREMENT**

The UI MUST distinguish between types of fields when submitting data to the API:

### Field Categories

1. **User-Provided Fields** - MUST be collected from user input or form fields
   - Example: animal name, species, adopter information
   - Submit to API as specified in the contract

2. **Optional Fields** - MAY be submitted if user provides them
   - Check contract for which fields are optional
   - Omit from request if not provided by user

3. **System-Generated Fields** - MUST NOT be submitted by UI
   - Resource identifiers (IDs)
   - Timestamps (created, updated, submitted, evaluated, decided)
   - System-calculated values
   - **The API will generate these and return them in the response**

4. **Read-Only Fields** - Returned by API but not submitted
   - Status values (calculated by API)
   - Derived/computed values

### Identifying Auto-Generated Fields

The API contract will typically indicate auto-generated fields by:
- **REST (OpenAPI)**: Fields marked as `readOnly: true` or omitted from request schemas but present in response schemas
- **GraphQL**: Fields on types but not in input types, or fields that don't accept arguments

### General Patterns for Auto-Generated Fields

While exact field names are defined by the API contract, these are common patterns:

**Resource Identifiers:**
- Entity IDs (animal ID, application ID, etc.)
- Event IDs (history event ID, evaluation ID, etc.)
- User/actor identifiers (adopter ID, user ID, etc.)
- **Rule:** Never send IDs when creating new resources
- **Example:** When submitting an adoption application, the API should auto-generate the adopter identifier, not require it from the user

**Timestamps:**
- Creation timestamps
- Update timestamps  
- Action timestamps (submitted, evaluated, decided)
- **Rule:** API manages all timestamps

**System Status:**
- Computed status values
- Workflow states
- **Rule:** Use transition operations, don't set status directly

### Example Pattern (Technology-Agnostic)

**CORRECT - Creating a Resource:**
```
User provides: name, species, description, age, tags
UI submits: name, species, description, age, tags
API returns: ID + user fields + createdAt + updatedAt + status
```

**INCORRECT - Creating a Resource:**
```
❌ UI submits: ID + name + createdAt + ...
   (ID and timestamps are auto-generated, not user input)
```

### Checking the Contract

For each operation:
1. Read the request schema/input type from the contract
2. Identify required vs optional fields
3. Collect required fields from user
4. Collect optional fields if provided
5. Submit only fields defined in request schema
6. Do NOT include fields only present in response schema

---

## REQ-UI-0003-A: RESTful Parameter Conventions

**NORMATIVE REQUIREMENT**

For REST APIs, the UI MUST follow standard REST conventions for parameter placement as defined in the OpenAPI contract.

### Parameter Location Rules

The OpenAPI specification defines where each parameter should be placed:

1. **Path Parameters** (`in: path`)
   - Part of the URL path
   - Used for resource identifiers
   - Required (cannot be omitted)
   - Example: `/animals/{animalId}` → ID goes in URL

2. **Query Parameters** (`in: query`)
   - Appended to URL after `?`
   - Used for filtering, pagination, sorting
   - Usually optional
   - Example: `/animals?status=AVAILABLE&limit=20`

3. **Body Parameters** (defined in `requestBody`)
   - Sent as JSON in request body
   - Used for resource data, complex inputs
   - Example: `{"name": "Luna", "species": "cat"}`

4. **Header Parameters** (`in: header`)
   - Sent in HTTP headers
   - Used for authentication, content negotiation
   - Example: `Authorization: Bearer token`

### Reading OpenAPI for Parameter Locations

**Example OpenAPI Definition:**
```yaml
paths:
  /applications/{applicationId}/evaluate:
    post:
      parameters:
        - name: applicationId
          in: path              # ← Goes in URL path
          required: true
      requestBody:
        content:
          application/json:
            schema:
              type: object      # ← Goes in request body
```

**Correct Implementation:**
```javascript
// applicationId from OpenAPI path parameter
const url = `/applications/${applicationId}/evaluate`
fetch(url, {
  method: 'POST',
  body: JSON.stringify({ /* body fields */ })
})
```

### Common Mistakes to Avoid

❌ **Putting path parameters in body:**
```javascript
// OpenAPI says applicationId is path parameter
fetch('/applications/evaluate', {  // Missing {applicationId}
  body: JSON.stringify({ applicationId: "123" })  // Wrong location
})
```

✅ **Following OpenAPI parameter locations:**
```javascript
// Read OpenAPI: applicationId is path parameter
fetch(`/applications/${applicationId}/evaluate`, {  // In path
  body: JSON.stringify({ /* other fields */ })
})
```

### GraphQL Note

GraphQL does not use path/query parameters. All inputs are passed as arguments to queries/mutations. Follow the GraphQL schema's argument definitions.

---

## REQ-UI-0004-A: Automatic Evaluation Understanding

**NORMATIVE REQUIREMENT**

Per `REQ-CORE-0022-A`, adoption application evaluation is **automatic and rule-based** (non-ML). The UI MUST understand this and MUST NOT collect manual evaluation criteria from staff.

### What "Automatic Evaluation" Means

The evaluation operation:
1. Takes only an application identifier as input
2. Automatically runs rule-based checks (household size, species compatibility, etc.)
3. Returns computed compatibility assessment and explanation
4. Does NOT accept manual "pass/fail" or "explanation" input from staff

### UI Implementation Guidance

**Evaluate Application Interface:**
- ✅ Display a list of applications that are ready to be evaluated (typically applications with SUBMITTED status)
- ✅ Allow staff to select an application from the list (not require manual ID entry)
- ✅ Show application details for the selected application
- ✅ Trigger button ("Run Evaluation", "Evaluate", or similar)
- ❌ NO manual input for compatibility assessment
- ❌ NO manual input for evaluation explanation
- ❌ NO manual scoring or checklist for staff to fill out

**Recommended UX Pattern:**
```
1. List pending applications in a table/list (applicationId, animalId, adopter name, submitted date)
2. "Select" button for each application
3. Display selected application details
4. "Run Evaluation" button
5. Display evaluation results
```

**What to Display:**
- Before evaluation: List of pending applications, then selected application details from API
- After evaluation: Results returned by API (compatibility, explanation, rule findings)

### Checking the API Contract

The evaluation operation's request schema should be minimal:
- **REST**: Request body will be empty or contain only application identifier (if not in path)
- **GraphQL**: Mutation will require only application ID argument

The response schema will include computed evaluation data:
- Compatibility result (PASS/FAIL/etc.)
- System-generated explanation
- Optional rule findings/details

**Recommended: List Applications Query**
To improve staff UX, the API should provide a way to list applications (e.g., `GET /applications?status=SUBMITTED` or `listApplications(applicationStatus: SUBMITTED)`). If not available, the UI may need to list animals and their related applications, but a direct applications list is more efficient.

### Principle

The API performs the evaluation logic. The UI is a **trigger** for that process, not a **data collector** for manual assessment.

---

## REQ-UI-0005-A: Field Name Fidelity

**NORMATIVE REQUIREMENT**

The UI MUST use the exact field names defined in the API contract. The UI MUST NOT:
- Rename fields based on UI preferences
- Use synonyms or abbreviations
- Guess at field names

### Why Exact Field Names Matter

APIs define specific field names in their contracts. Using different names causes:
- **400 Bad Request** errors (unknown fields)
- **422 Validation** errors (missing required fields)
- Data not reaching the API as intended

### Reading Field Names from Contracts

**REST (OpenAPI):**
```yaml
# Field names are in schema property names
schema:
  type: object
  properties:
    adopterName:      # ← Exact field name
      type: string
    hasOtherPets:     # ← Use exactly this, not "otherPets"
      type: boolean
```

**GraphQL:**
```graphql
# Field names are in input type field names
input ApplicationInput {
  adopterName: String!    # ← Exact field name
  hasOtherPets: Boolean   # ← Use exactly this
}
```

### Common Pitfalls

❌ **Assuming similar fields have same names:**
- One operation uses `reason`, another uses `explanation`
- One entity has `status`, another has `applicationStatus`
- Check each operation's contract independently

❌ **Simplifying field names:**
- Contract says `hasOtherPets` → Don't use `otherPets`
- Contract says `householdSize` → Don't use `household`

❌ **Using display labels as field names:**
- UI shows "Reason for decision" → Field might be `explanation` or `rationale`
- UI shows "Pet Species" → Field might be `species`, `animalType`, etc.

### Best Practice

1. Read the operation's contract definition
2. Extract exact property/field names
3. Use those names in API requests
4. Map to different labels in UI if needed for UX

**Example:**
```javascript
// UI displays "Reason for Decision"
// But API contract shows field is "explanation"

// Code:
const uiLabel = "Reason for Decision"
const apiFieldName = "explanation"  // From contract

fetch(url, {
  body: JSON.stringify({
    [apiFieldName]: userInput  // Use API field name, not UI label
  })
})
```

---

## REQ-UI-0006-A: Optimistic Concurrency for State Transitions

**NORMATIVE REQUIREMENT**

Per `REQ-CORE-0011-A`, the API enforces a lifecycle state machine. The transition operation requires BOTH current state and target state to prevent stale updates.

### Principle: Optimistic Concurrency Control

When transitioning an entity's state, the API may require you to specify:
1. **Current state** (what you believe the state is now)
2. **Target state** (what you want to transition to)

This allows the API to:
- Verify the entity is still in the expected state
- Reject stale updates (another user already changed it)
- Validate the transition is allowed from that state

### Checking the Contract

Look for transition operations that require both `from` and `to` state parameters:
- Field names might be: `fromStatus`/`toStatus`, `currentState`/`newState`, etc.
- Check which parameters are required

**Example OpenAPI pattern:**
```yaml
requestBody:
  content:
    application/json:
      schema:
        required: [animalId, fromStatus, toStatus, reason]
        properties:
          animalId: { type: string }
          fromStatus: { type: string }   # ← Current state required
          toStatus: { type: string }     # ← Target state required
```

### UI Implementation Pattern

1. **Fetch current state** before showing transition form
2. **Display current state** to user (for confirmation)
3. **Include current state** in transition request
4. **Handle 409 Conflict** if state changed since fetch

**General Pattern:**
```javascript
// 1. Fetch entity to get current state
const entity = await api.getEntity(id)

// 2. User selects target state
const targetState = userSelection

// 3. Submit transition with both states
await api.transitionState({
  entityId: id,
  from: entity.currentState,  // What we fetched
  to: targetState,             // What user chose
  reason: userReason
})
```

### Error Handling

If transition fails with 409 Conflict:
- Current state no longer matches what UI sent
- Re-fetch entity to get latest state
- Show user the new current state
- Let user decide whether to retry

---

## REQ-UI-0007-A: Enum Value Compliance

**NORMATIVE REQUIREMENT**

The UI MUST use the exact enum values defined in the API contract for constrained fields.

### Understanding API Enums

Many fields accept only specific values (enums):
- Decision outcomes (APPROVE, REJECT, etc.)
- Animal species (dog, cat, etc.)
- Lifecycle states (AVAILABLE, ADOPTED, etc.)

The API contract specifies the exact allowed values.

### Reading Enums from Contract

**REST (OpenAPI):**
```yaml
schema:
  properties:
    decision:
      type: string
      enum: [APPROVE, REJECT]  # ← Only these values accepted
```

**GraphQL:**
```graphql
enum Decision {
  APPROVE    # ← Exact value
  REJECT     # ← Exact value
}
```

### UI Implementation

**Dropdowns/Select Elements:**
- Use enum values as `<option value="...">`
- Display user-friendly labels
- Submit enum values to API

```html
<!-- Display labels can differ from API values -->
<select name="decision">
  <option value="APPROVE">Approve Application</option>
  <option value="REJECT">Reject Application</option>
</select>
```

### Common Mistakes

❌ **Using UI labels as values:**
```html
<option value="Approve">Approve</option>  <!-- API expects "APPROVE" not "Approve" -->
```

❌ **Using synonyms:**
```html
<option value="DENY">Deny</option>  <!-- API might expect "REJECT" -->
```

❌ **Case sensitivity errors:**
```html
<option value="approve">Approve</option>  <!-- API expects "APPROVE" (uppercase) -->
```

### Validation

If UI sends invalid enum value:
- API will return 400 Bad Request or 422 Validation Error
- Check contract for exact allowed values
- Ensure UI dropdown matches contract exactly

---

## REQ-UI-0008-A: Consumer vs Staff Interfaces

**NORMATIVE REQUIREMENT**

The UI MUST provide distinct interfaces or feature segregation for:
1. **Consumer Interface** - Public-facing, adoption-focused
2. **Staff Interface** - Administrative, lifecycle management

### Consumer Interface Requirements

**MUST include:**
- Browse available animals (with filtering)
- View animal details
- View animal history (for transparency)
- Submit adoption application
- View images (if any)

**MUST NOT include:**
- Animal intake form
- Status transition controls
- Evaluation triggers
- Decision recording
- Reset to seed

### Staff Interface Requirements

**MUST include:**
- Animal intake form
- Status transition form
- List of submitted applications
- Evaluate application trigger
- Record decision form
- Reset to seed capability (for demos/benchmarking)

**MAY include:**
- All consumer interface features
- Staff dashboard
- Application management

---

## REQ-UI-0009-A: Form Validation

**NORMATIVE REQUIREMENT**

The UI SHOULD perform client-side validation before submitting to the API to improve user experience, but MUST NOT rely solely on client-side validation for correctness.

### Client-Side Validation Approach

Read the API contract to understand:
- Required vs optional fields
- Field types (string, number, boolean, enum)
- Value constraints (min/max, length, regex patterns)
- Enum allowed values

Implement client-side validation based on contract constraints:
- Required fields: Check non-empty
- Numbers: Check type, min/max if specified
- Strings: Check length limits if specified
- Emails: Check format if field suggests email
- Enums: Restrict to allowed values

**Example validations based on common PawMate fields:**
- Species enum: Validate against allowed values from contract
- Description: If required, check non-empty
- Age: If numeric with constraints, check range
- Email: If email field, validate format

The UI MUST still handle API validation errors gracefully and display them to the user, as client-side validation is for UX only.

---

## REQ-UI-0010-A: Staff Workflow UX

**NORMATIVE REQUIREMENT**

The UI SHOULD provide efficient workflows for staff operations. For operations that work on specific records (evaluate application, record decision, etc.):

**Recommended Pattern:**
1. Display a list/table of pending items (applications, animals, etc.)
2. Allow staff to select an item from the list
3. Show details of the selected item
4. Provide action buttons for the selected item

**Anti-Pattern to Avoid:**
- Requiring staff to manually type resource IDs (application IDs, animal IDs) from memory or external sources
- Forcing staff to navigate away to find IDs before performing actions

**Example (Evaluate Application):**
- ✅ Good: Show list of submitted applications → Select → Display details → Evaluate button
- ❌ Bad: Show text input "Enter Application ID" → Require staff to type ID manually

This improves usability by reducing context switching and manual ID entry errors.

---

## REQ-UI-0011-A: Error Display

**NORMATIVE REQUIREMENT**

The UI MUST display API errors in a user-friendly manner. The UI SHOULD distinguish between error categories.

### Error Categories to Handle

| API Error Category | HTTP Status | UI Display Guidance |
|-------------------|-------------|---------------------|
| `ValidationError` | 400 | "Please correct the following: {message}" |
| `NotFound` | 404 | "Resource not found: {message}" |
| `Conflict` | 409 | "Cannot complete: {message}" (explain why) |
| `AuthRequired` | 401 | "Please log in to continue" (Model B) |
| `Forbidden` | 403 | "You don't have permission for this action" (Model B) |
| Network Error | N/A | "Cannot connect to server. Please try again." |

### Example Error Handling

```javascript
try {
  const response = await fetch(apiEndpoint, {
    method: httpMethod,
    body: JSON.stringify(requestData)
  })
  
  if (!response.ok) {
    const error = await response.json()
    // API should return error with category/type and message
    // Display error.message to user with appropriate styling
    showError(error.message, error.category || error.type)
    return
  }
  
  // Success flow
} catch (networkError) {
  // Network/connection failure
  showError('Cannot connect to server. Please try again.', 'network')
}
```

---

## REQ-UI-0012-A: Loading States

**NORMATIVE REQUIREMENT**

The UI SHOULD provide visual feedback during API requests to improve perceived performance and prevent duplicate submissions.

### Recommended Patterns

1. **Disable submit buttons** during request
2. **Show loading spinners** for data fetching
3. **Display "Submitting..." text** on form buttons
4. **Prevent duplicate submissions** via button state

---

## REQ-UI-0013-A: Success Feedback

**NORMATIVE REQUIREMENT**

The UI MUST provide clear success feedback after successful operations.

### Recommended Success Messages

| Operation | Success Message | Additional Actions |
|-----------|----------------|-------------------|
| Intake Animal | "Animal successfully added! ID: {animalId}" | Clear form, show animal in list |
| Submit Application | "Application submitted! ID: {applicationId}" | Show next steps, application ID |
| Transition Status | "Status updated to {newStatus}" | Refresh animal list |
| Evaluate Application | "Application evaluated. Result: {compatibility}" | Show evaluation details |
| Record Decision | "Decision recorded: {decision}" | Show updated status |
| Reset to Seed | "Database reset to seed data" | Refresh all data |

---

## REQ-UI-0014-A: Image Display

**NORMATIVE REQUIREMENT**

The UI MUST display animal images when available and handle missing images gracefully.

### Image Handling Rules

1. **Maximum Images:** 3 per animal (per `REQ-IMG-0002-A`)
2. **Ordering:** Display in order returned by API (`ordinal ASC, imageId ASC`)
3. **Missing Images:** Show placeholder (emoji, icon, or generic image)
4. **Alt Text:** Use `altText` field from API for accessibility
5. **Broken Images:** Handle 404s gracefully with fallback

### Example

```javascript
const animal = await fetch(`/v1/animals/${animalId}`).then(r => r.json())

// Animal has embedded images array
animal.images.forEach(img => {
  displayImage(img.contentUrl, img.altText)
})

// Or fetch separately
const images = await fetch(`/v1/images/${animalId}`).then(r => r.json())
```

---

## REQ-UI-0015-A: History Timeline Display

**NORMATIVE REQUIREMENT**

The UI SHOULD display animal history in reverse chronological order (most recent first) to provide transparency.

### History Display Requirements

1. **Ordering:** Most recent events first (`occurredAt DESC`)
2. **Event Types:** Show all event types with appropriate icons/labels
3. **Timestamps:** Display in user-friendly format
4. **Details:** Show reason, explanation, status transitions
5. **Performer:** Show who performed the action

### Recommended Event Type Labels

| API `eventType` | UI Display |
|----------------|------------|
| `INTAKE` | "Animal Intake" |
| `STATUS_TRANSITION` | "Status Changed" |
| `APPLICATION_SUBMITTED` | "Application Submitted" |
| `APPLICATION_EVALUATED` | "Application Evaluated" |
| `DECISION_RECORDED` | "Decision Recorded" |
| `OVERRIDE_RECORDED` | "Decision Override" |

---

## REQ-UI-0016-A: Dependent Form Field Management

**NORMATIVE REQUIREMENT**

When a form has dependent fields (where the value of one field affects the valid options for another field), the UI MUST ensure form state consistency when the controlling field changes.

### Dependent Field Pattern

Common scenario: A dropdown selection determines valid options for a subsequent dropdown.

**Example: Animal Status Transition Form**
- Field A (controlling): "Select Animal" → determines current status
- Field B (dependent): "New Status" → valid values depend on current status

**Required Behavior:**
1. When the controlling field changes, the dependent field MUST be updated to a valid value
2. The dependent field SHOULD default to the first valid option for the new context
3. If no valid options exist for the new context, the dependent field should be cleared/disabled with appropriate messaging

### Anti-Pattern: Stale Dependent Values

❌ **WRONG - Leaving Stale Values:**
```javascript
// User selects Animal 1 (status: INTAKE)
// Form state: { fromStatus: 'INTAKE', toStatus: 'MEDICAL_EVALUATION' } ✓

// User selects Animal 2 (status: AVAILABLE)
// Form state: { fromStatus: 'AVAILABLE', toStatus: 'MEDICAL_EVALUATION' } ✗
// Problem: MEDICAL_EVALUATION is not a valid transition from AVAILABLE
```

✅ **CORRECT - Updating Dependent Values:**
```javascript
// User selects Animal 1 (status: INTAKE)
// Form state: { fromStatus: 'INTAKE', toStatus: 'MEDICAL_EVALUATION' } ✓

// User selects Animal 2 (status: AVAILABLE)
// Form state: { fromStatus: 'AVAILABLE', toStatus: 'APPLICATION_PENDING' } ✓
// Correct: toStatus updated to first valid transition for AVAILABLE
```

### Implementation Guidance

```javascript
// Example: Handling animal selection that affects valid status transitions
const handleAnimalChange = (selectedAnimalId) => {
  const animal = animals.find(a => a.id === selectedAnimalId);
  const currentStatus = animal.status;
  
  // Determine valid next states based on current status
  const validTransitions = getValidTransitionsFor(currentStatus);
  
  // Update form state with consistent values
  setFormData({
    animalId: selectedAnimalId,
    fromStatus: currentStatus,
    toStatus: validTransitions[0] || currentStatus // Default to first valid option
  });
};
```

### Other Examples of Dependent Fields

This pattern applies to any form where fields have dependencies:
- **Species → Breed:** When species changes, breed options must be updated
- **Country → State/Province:** When country changes, state options must be updated
- **Application → Animal Details:** When application changes, display corresponding animal info

**Key Principle:** Never allow form state to contain logically inconsistent or invalid combinations of values. Always update dependent fields when their controlling field changes.

---

## REQ-UI-0017-A: Development Server Management

**NORMATIVE REQUIREMENT**

The UI implementation MUST provide clear, documented commands to start and stop the development server. This enables developers and evaluators to easily run and test the UI during development and benchmarking.

### Required Commands

The UI project MUST include:

1. **Start Server Command** - Starts the development server
2. **Stop Server Instruction** - Clear method to stop the development server
3. **Build Command** (optional) - Creates production build if applicable

### Documentation Requirements

The UI project MUST document these commands in a README file or package.json scripts section.

### Implementation Examples

**Node.js/npm Projects:**
```json
// package.json
{
  "scripts": {
    "dev": "vite",           // or "react-scripts start", "next dev", etc.
    "start": "vite",         // alias for consistency
    "build": "vite build",   // production build
    "preview": "vite preview" // preview production build
  }
}
```

**Usage:**
- Start: `npm run dev` or `npm start`
- Stop: `Ctrl+C` in terminal (document this)
- Build: `npm run build`

**Python Projects:**
```python
# README.md should document:
# Start: python -m http.server 8080
# Stop: Ctrl+C
# Or for frameworks like Flask/Django, document their specific commands
```

**Other Frameworks:**
- Document the framework-specific commands
- Include port number information
- Include any required environment setup

### README Documentation

The UI project MUST include a README that specifies:
```markdown
## Running the UI

### Development Server
Start the development server:
```
npm run dev
```

The UI will be available at: http://localhost:5173

To stop the server, press `Ctrl+C` in the terminal.

### Production Build
Create a production build:
```
npm run build
```
```

### Rationale

Clear server management instructions:
- Enable quick setup for evaluators during benchmarking
- Reduce friction during development handoffs
- Prevent confusion about how to run the UI
- Allow for clean restarts when troubleshooting

**Anti-Pattern:** Undocumented or unclear process for starting/stopping the UI, requiring evaluators to search through code or guess commands.

---

## REQ-UI-0018-B: Search Field Coverage (Model B)

**NORMATIVE REQUIREMENT (Model B Only)**

When implementing search functionality for Model B, the UI MUST call an API search endpoint that queries at minimum the `name`, `description`, and `tags` fields as specified in REQ-CORE-0101-B.

### Search Field Requirements

The search API endpoint MUST search across:
- **name** (animal name, may be null)
- **description** (animal description, required)
- **tags** (array of tags, required)

Implementations MAY search additional fields (e.g., species) but MUST include these three minimum fields.

### UI Placeholder Text Guidance

Search input placeholder text SHOULD accurately reflect what fields are searchable. 

**Recommended Placeholders:**
- "Search by name, description, or tags..."
- "Find pets by name, traits, or characteristics..."
- "Search animals by keywords..."

**Avoid:**
- "Search by name, description, or breed..." - `breed` is not a field in the data model
- "Search by breed..." - Use `species` for dog/cat distinction; `tags` for breed-like characteristics

### Rationale

Tags are structured metadata designed for categorization and discovery (e.g., `vaccinated`, `senior`, `special-needs`, `indoor-only`, `behavior-support`). These attributes are exactly what users search for when finding animals. Making tags searchable is essential to providing effective search functionality.

While the seed data includes test terms in descriptions (e.g., "senior cat", "indoor-only"), implementations must not rely solely on description matching. Tags provide structured, standardized attributes that enable consistent, effective search across all animals.

### Checking the Contract

**REST (OpenAPI):**
```yaml
/animals/search/query:
  parameters:
    - name: q
      description: Search query (searches name, description, and tags)
```

**GraphQL:**
```graphql
searchAnimals(query: String!): [Animal!]!
# Schema documentation should specify: "Searches name, description, and tags fields"
```

### UI Implementation

When the user enters a search query:
1. Call the search API endpoint with the query string
2. Display results in the same format as browse/list
3. Maintain pagination and ordering
4. Show "No results found" message for empty results
5. Provide clear way to exit search mode and return to browse

**Example User Flow:**
- User enters "senior" in search box
- UI calls API: `GET /v1/animals/search/query?q=senior`
- API searches name, description, AND tags
- Results include animals with "senior" in any of these fields
- User can clear search to return to browse mode

---

## Implementation Checklist

Use this checklist to verify UI implementation compliance:

### Contract Discovery
- [ ] Located API contract artifact (OpenAPI spec or GraphQL schema)
- [ ] Read all operation definitions
- [ ] Identified all required capabilities (browse, intake, apply, evaluate, decide, etc.)
- [ ] Understood parameter locations (path, query, body for REST; arguments for GraphQL)

### API Integration Principles
- [ ] All operations discovered from contract (not invented)
- [ ] Request patterns follow contract exactly
- [ ] Required fields identified from contract and collected
- [ ] Optional fields identified and collected if provided
- [ ] Auto-generated fields (IDs, timestamps) NOT sent
- [ ] Field names match contract exactly (no synonyms)

### For Each Operation

**Creating Resources (Intake, Submit Application, etc.):**
- [ ] Does NOT send resource ID (auto-generated)
- [ ] Does NOT send timestamps (auto-generated)
- [ ] Sends only user-provided data
- [ ] Collects required fields per contract
- [ ] Displays API-generated ID after successful create

**Reading Resources (Get Animal, List Animals, etc.):**
- [ ] Uses correct HTTP method (GET) or GraphQL query
- [ ] Includes required parameters (filters, pagination, IDs)
- [ ] Handles empty results gracefully
- [ ] Displays all relevant fields from response

**Updating/Transitioning Resources:**
- [ ] If contract requires current state, fetches and includes it
- [ ] Sends both fromState and toState if contract requires
- [ ] Includes reason/explanation as required
- [ ] Handles 409 Conflict (stale state) appropriately

**Evaluation Operation:**
- [ ] Does NOT collect manual evaluation input (auto-evaluation)
- [ ] Sends minimal request (just ID, no manual criteria)
- [ ] Displays evaluation results returned by API

**Decision Operation:**
- [ ] Uses exact enum values from contract
- [ ] Includes required explanation/reason field (check contract for name)
- [ ] Sends all required fields per contract

### Path Parameters (REST APIs)
- [ ] IDs in URL path when contract specifies `in: path`
- [ ] NOT putting path parameters in request body
- [ ] Correctly substituting IDs into URL templates

### User Experience
- [ ] Consumer interface separate from staff interface
- [ ] Clear success messages (display generated IDs)
- [ ] User-friendly error messages by category
- [ ] Loading states during API calls
- [ ] Images displayed with graceful fallbacks
- [ ] History timeline in reverse chronological order
- [ ] Dependent form fields update when controlling field changes (no stale values)

### Development & Deployment
- [ ] README documents how to start development server
- [ ] README documents how to stop development server (e.g., Ctrl+C)
- [ ] Server start command included in package.json scripts (if Node.js)
- [ ] Port number documented
- [ ] Any required environment setup documented

### Testing
- [ ] Captured actual API requests in browser dev tools
- [ ] Verified endpoints match contract
- [ ] Verified field names match contract
- [ ] Verified no extra fields sent
- [ ] Verified all required fields sent

---

## Common Mistakes to Avoid

### ❌ Inventing Endpoints Not in Contract
```
Problem: UI calls an endpoint that doesn't exist in the API contract
Solution: Read the contract artifact (OpenAPI/GraphQL schema) to discover all available operations
```

### ❌ Putting IDs in Wrong Location
```javascript
// WRONG - Ignoring path parameter definition
// OpenAPI says: /applications/{applicationId}/evaluate
fetch('/applications/evaluate', {  // Missing path param
  body: JSON.stringify({ applicationId: "123" })  // Putting in body instead
})

// RIGHT - Following path parameter definition
fetch('/applications/123/evaluate', {  // ID in path as specified
  body: JSON.stringify({})
})
```

### ❌ Sending Auto-Generated Fields
```javascript
// WRONG - Sending fields API generates
// Creating new animal:
{ "animalId": "A001", "createdAt": "2025...", "species": "dog" }

// RIGHT - Only sending user-provided fields
// Creating new animal:
{ "species": "dog", "description": "Friendly dog" }
// API will return: { "animalId": "generated-id", "createdAt": "timestamp", ...userFields }
```

### ❌ Using Wrong Field Names
```javascript
// WRONG - Guessing field name or using synonym
// Contract says field is "explanation"
{ "reason": "User provided reason" }

// RIGHT - Using exact field name from contract
{ "explanation": "User provided reason" }
```

### ❌ Missing Required Fields
```javascript
// WRONG - Omitting required field
// Contract says fromStatus and toStatus are required
{ "animalId": "A001", "toStatus": "ADOPTED" }

// RIGHT - Including all required fields
{ "animalId": "A001", "fromStatus": "APPROVED", "toStatus": "ADOPTED", "reason": "..." }
```

### ❌ Using Wrong Enum Values
```javascript
// WRONG - Using display label or synonym
// Contract says enum is [APPROVE, REJECT]
{ "decision": "Approve" }  // Wrong case
{ "decision": "DENY" }     // Wrong value

// RIGHT - Using exact enum value from contract
{ "decision": "APPROVE" }
```

---

## Testing UI Compliance

### Manual Testing Checklist

For each operation:
1. Fill out UI form
2. Submit and capture network request (browser dev tools)
3. Verify:
   - Correct endpoint called
   - Correct HTTP method
   - Correct fields in body/path/query
   - No extra fields sent
   - Field names match exactly

### Automated Testing

If automated UI tests exist:
1. Assert correct API endpoints called (mock/spy)
2. Assert request bodies match expected shape
3. Assert path parameters extracted correctly
4. Assert error handling works
5. Assert success feedback displays

---

## Version History

- `v1.0.3` (2025-12-23): Added development server management requirements
  - REQ-UI-0017-A: Development Server Management
  - Requires documented commands to start/stop development server
  - Ensures clear setup instructions for evaluators and developers
- `v1.0.2` (2025-12-23): Added dependent form field management guidance
  - REQ-UI-0016-A: Dependent Form Field Management
  - Addresses form state consistency when one field affects valid options for another
  - Prevents invalid form submissions due to stale dependent values
- `v1.0.1` (2025-12-18): Initial UI requirements specification
  - Principles-based guidance for UI-API integration
  - Contract-driven approach (not hardcoded endpoints)
  - Aligned with Master Functional Spec v1.0.0
  - Technology-agnostic (REST and GraphQL)
- Addresses common UI-API integration issues

---

## Relationship to Acceptance Criteria

UI implementations MUST satisfy all relevant acceptance criteria from `docs/Acceptance_Criteria.md`. This document provides implementation guidance; acceptance criteria provide verification criteria.

---

**End of UI Requirements Specification**

