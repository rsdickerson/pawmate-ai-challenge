# Submitting Results Guide

## Overview

This guide explains how to submit benchmark results for inclusion in the comparison database. External developers submit results via email, while maintainers with repo access can use git-based submission.

## Quick Submit (Recommended for External Developers)

The easiest way to submit your benchmark results:

1. **Complete your benchmark run** (API and optionally UI)
2. **Generate result file**: `./scripts/generate_result_file.sh --run-dir runs/YYYYMMDDTHHmm`
3. **Submit via email**: `./scripts/submit_result.sh your-result-file.json`

The submission script will:
- Validate your result file
- Prompt for optional attribution (name/GitHub username)
- Include the JSON result data in the email body (no attachment needed)
- Open your email client with pre-filled content
- Provide manual instructions if automatic email fails

### Privacy & Attribution

- **Anonymous submission is allowed**: You can skip the attribution prompt to submit anonymously
- **Optional identification**: Provide your name or GitHub username if you want to be credited
- **Your choice**: The decision is entirely yours

The submission email is stored in `.submission.config` (defaults to: `pawmate.ai.challenge@gmail.com`)

## Traditional Git-Based Submission (For Maintainers)

If you have write access to the `pawmate-ai-results` repository, you can submit via pull request:

1. **Complete your benchmark run** (API and optionally UI)
2. **Generate result file**: `./scripts/generate_result_file.sh --run-dir runs/YYYYMMDDTHHmm`
3. **Complete and validate**: Review the file, fill in metrics, then validate
4. **Submit via PR**: Commit, push, and create a pull request

## Email Submission Workflow (Detailed)

### Step 1: Generate Result File

After completing your benchmark run, generate a standardized result file:

```bash
cd /path/to/pawmate-ai-challenge
./scripts/generate_result_file.sh --run-dir runs/20241218T1430
```

This script:
- Reads your `run.config` file
- Extracts metrics from your AI run report (if available)
- Generates a standardized result file (defaults to current directory)
- Names the file according to the convention: `{tool-slug}_{model}_{api-type}_{run-number}_{timestamp}.json`

**Output**: The script will tell you the path to the generated file and next steps.

### Step 2: Submit via Email Script

Run the submission script:

```bash
./scripts/submit_result.sh your-result-file.json
```

The script will:

1. **Validate your result file**:
   - Check JSON format
   - Verify filename convention
   - Check for required fields
   - Display validation results

2. **Prompt for attribution (optional)**:
   - Enter your name or GitHub username if you want credit
   - Press Enter to submit anonymously
   - Your choice is completely optional

3. **Open your email client**:
   - Pre-filled email with subject and body
   - Includes submission metadata
   - **JSON result data is included in the email body** (no attachment needed)
   
4. **Fallback instructions**:
   - If email client doesn't open automatically
   - Clear manual instructions are displayed
   - Copy-paste friendly format with full email body

**Important**: The JSON result data is included directly in the email body. No file attachment is needed.

### Step 3 (Alternative): Manual Email Submission

If you prefer not to use the script, you can submit manually:

1. **Email to**: `pawmate.ai.challenge@gmail.com` (or the configured submission email)
2. **Subject**: `[PawMate Result] {your-filename-without-.json}`
3. **Body**: Copy the entire contents of your result JSON file into the email body
4. **Optional**: Include your name/GitHub username in the email body

**Note**: Include the JSON directly in the email body - no file attachment is needed.

### Step 4: Confirmation

After submitting, you should receive a confirmation that your result has been received and will be processed.

---

## Git-Based Submission Workflow (For Maintainers)

This section is for maintainers who have write access to the `pawmate-ai-results` repository.

### Step 1: Generate Result File

Same as email submission workflow above.

### Step 2: Complete Result File

The generated file contains placeholders that must be filled in. Open the file and complete:

#### Required Metrics

1. **Acceptance Criteria Results**
   - Count pass/fail/not-run from your acceptance checklist
   - Calculate passrate: `pass_count / (pass_count + fail_count)`
   - Reference: `docs/Acceptance_Criteria.md`

2. **Determinism Compliance**
   - Verify reset-to-seed works and is idempotent
   - Run golden checks from `docs/Seed_Data.md`
   - Mark as "Pass", "Fail", or "Unknown"
   - Reference: `docs/Seed_Data.md`

3. **Contract Completeness**
   - Review contract artifact against `docs/API_Contract.md` checklist
   - Calculate passrate (items passed / total items)
   - Reference: `docs/API_Contract.md`

4. **Instructions Quality**
   - Rate: 100 (perfect), 70 (minor issues), 40 (significant gaps), 0 (unusable)
   - Consider: copy/paste friendly, non-interactive, unambiguous
   - Reference: `docs/Benchmarking_Method.md` M-11

5. **Scores**
   - Calculate using `docs/Scoring_Rubric.md`
   - Fill in C, R, D, E, K scores
   - S (Speed) will be calculated during aggregation (cohort comparison)
   - Overall score requires Run 2 for final calculation

#### Human-Readable Content

The result file is JSON-only. All information should be captured in the structured JSON fields. For human-readable reports, see the generated comparison reports in `pawmate-ai-results/results/compiled/` (generated after submitting result files to the results repository).

### Step 3: Validate Result File

Before submitting, validate your result file:

```bash
# Validate using the script in the results repository
cd /path/to/pawmate-ai-results
./scripts/validate_result.sh results/submitted/your-result-file.json
```

The validator checks:
- File format and naming convention
- YAML frontmatter validity
- Required fields presence
- Data type correctness
- Enum value validity
- Timestamp format

**Fix any errors** before proceeding. Warnings are acceptable but should be reviewed.

For strict validation (treats warnings as errors):

```bash
# In the results repository
cd /path/to/pawmate-ai-results
./scripts/validate_result.sh results/submitted/your-result-file.json --strict
```

### Step 4: Submit via Git (Maintainers with Repo Access)

#### Option A: Automated (Recommended)

If your AI tool generated the result file automatically:

1. **Copy file to results repository**:
   ```bash
   cp your-result-file.json /path/to/pawmate-ai-results/results/submitted/
   ```

2. **In the results repository, review and commit**:
   ```bash
   cd /path/to/pawmate-ai-results
   git add results/submitted/your-result-file.json
   git commit -m "Add benchmark result: ToolName Model A REST Run 1"
   git push origin HEAD
   ```
3. **Create pull request** on GitHub

#### Option B: Manual Submission

1. **Copy file to results repository**:
   ```bash
   cp your-result-file.json /path/to/pawmate-ai-results/results/submitted/
   ```

2. **In the results repository, create a branch**:
   ```bash
   cd /path/to/pawmate-ai-results
   git checkout -b submit-results-toolname-modelA-run1
   ```

3. **Add and commit**:
   ```bash
   git add results/submitted/your-result-file.json
   git commit -m "Add benchmark result: ToolName Model A REST Run 1"
   ```

3. **Push and create PR**:
   ```bash
   git push origin submit-results-toolname-modelA-run1
   ```
   Then create a pull request on GitHub.

### Step 5: Review and Merge

1. **CI Validation**: GitHub Actions will automatically validate your result file
2. **Review**: Maintainers will review your submission
3. **Merge**: Once approved, your results will be merged
4. **Compilation**: After merge, comparison reports will be automatically generated

## What Happens After Submission

### Email Submissions

After you email your result file:
1. **Receipt**: The maintainer receives your result file via email
2. **Processing**: The file is processed and added to the results database
3. **Validation**: The result is validated against the schema
4. **Compilation**: Results are aggregated into comparison reports
5. **Publication**: Your results appear in the compiled reports (attribution as specified)

### Git-Based Submissions (PR workflow)

When you create a PR with result files:
- GitHub Actions runs `validate-results.yml` (if configured)
- Validates file format, schema, and data
- Comments on PR with validation status
- Blocks merge if validation fails

After merge:
- Aggregates all results by spec version, model, and API type
- Generates comparison reports in `results/compiled/`
- Commits reports back to the repository (if configured)

### Comparison Reports

Comparison reports show:
- Side-by-side tool comparisons
- Timing comparisons (TTFR, TTFC)
- Test iteration counts
- LLM usage metrics
- Acceptance pass rates
- Detailed metrics and evidence pointers

## Result File Format

See `docs/Result_File_Spec.md` for the complete specification.

Key requirements:
- JSON file format
- Naming: `{tool-slug}_{model}_{api-type}_{run-number}_{timestamp}.json`
- All required fields in JSON structure
- Valid JSON that passes schema validation

## Troubleshooting

### Validation Errors

**Error: "Filename does not match naming convention"**
- Ensure filename follows: `{tool-slug}_{model}_{api-type}_{run-number}_{timestamp}.json`
- Tool slug: lowercase, alphanumeric + hyphens only
- Example: `cursor-v0-43_modelA_REST_run1_20241218T1430.json`

**Error: "Required field missing"**
- Check that all fields in `result_data` are present
- Use `results/result_template.md` as a reference

**Error: "Invalid timestamp format"**
- Use ISO-8601 format: `YYYY-MM-DDTHH:MM:SS.sssZ`
- Example: `2024-12-18T14:30:00.000Z`

**Error: "Schema validation failed"**
- Check the error message for the specific field
- Ensure enum values match allowed values (A/B, REST/GraphQL, etc.)
- Verify numeric ranges (0-100 for scores, 0-1 for passrates)

### Generation Script Issues

**Error: "run.config not found"**
- Ensure you're running from the repository root
- Check that the run directory path is correct
- Verify `run.config` exists in the run directory

**Error: "Required config value missing"**
- Check that `run.config` has all required fields
- Re-run `initialize_run.sh` if needed

### Missing Metrics

If you cannot determine a metric value:
- Use `"Unknown"` (not empty string or null)
- Explain why in the human-readable section
- Reference missing evidence

### Submission Script Issues

**Error: "Email client could not be opened"**
- Use the manual instructions displayed by the script
- Email address, subject, and full email body (with JSON) are shown clearly
- Copy and paste the email body into your email application
- No file attachment needed - JSON is in the body

**Script validation fails**
- Review the validation errors displayed
- Fix issues in your result file
- Re-run the submission script

**Want to change submission email**
- Edit `.submission.config` in the repository root
- Set `SUBMISSION_EMAIL=your-email@example.com`
- File is gitignored for local customization

## Best Practices

1. **Complete Run 1 and Run 2** before submitting (for reproducibility scoring)
2. **Fill in all available metrics** (don't leave placeholders if data exists)
3. **Reference evidence paths** correctly (relative to repo root)
4. **Review before submitting** (catch errors early)
5. **Follow naming conventions** (prevents validation errors)
6. **Include detailed notes** in human-readable section (helps reviewers)

## Resources

- `docs/Result_File_Spec.md` - Complete specification
- `docs/Benchmarking_Method.md` - Metric definitions
- `scripts/generate_result_file.sh` - Generation script
- `scripts/submit_result.sh` - Email submission script
- `scripts/validate_result.sh` - Validation script (in pawmate-ai-results repo)
- `.submission.config.template` - Email configuration template

## Support

If you encounter issues:
1. Check this guide and related documentation
2. Review example result files in `results/submitted/` (if any exist)
3. Open an issue on GitHub with:
   - Error message
   - Result file (if validation error)
   - Steps to reproduce

