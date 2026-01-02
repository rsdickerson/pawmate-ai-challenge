#!/usr/bin/env bash
#
# generate_result_file.sh — Generate standardized result file from run directory
#
# Usage:
#   ./scripts/generate_result_file.sh --run-dir <run-directory> [--output-dir <output-dir>]
#
# Options:
#   --run-dir <path>      Required. Path to run directory (e.g., runs/20241218T1430)
#   --output-dir <path>   Optional. Output directory (default: current directory)
#                         Note: Result files should be copied to pawmate-ai-results/results/submitted/ for processing
#   --help                Show this help message
#

set -euo pipefail

# Resolve script and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Defaults
RUN_DIR=""
OUTPUT_DIR=""  # Default to run directory - result file belongs with the run

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --run-dir)
            RUN_DIR="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            sed -n '2,/^$/p' "$0" | grep '^#' | sed 's/^# \?//'
            exit 0
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$RUN_DIR" ]]; then
    echo "Error: --run-dir is required" >&2
    exit 1
fi

# Resolve absolute paths
RUN_DIR="$(cd "$RUN_DIR" && pwd)"
# Default OUTPUT_DIR to benchmark folder at run level (sibling of PawMate folder)
if [[ -z "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="$RUN_DIR/benchmark"
fi
OUTPUT_DIR="$(mkdir -p "$OUTPUT_DIR" && cd "$OUTPUT_DIR" && pwd)"

# Check run directory exists
if [[ ! -d "$RUN_DIR" ]]; then
    echo "Error: Run directory does not exist: $RUN_DIR" >&2
    exit 1
fi

# Check run.config exists
RUN_CONFIG="$RUN_DIR/run.config"
if [[ ! -f "$RUN_CONFIG" ]]; then
    echo "Error: run.config not found in run directory: $RUN_CONFIG" >&2
    exit 1
fi

# Source run.config
# shellcheck disable=SC1090
source "$RUN_CONFIG"

# Validate required config values
REQUIRED_VARS=("spec_version" "tool" "model" "api_type" "workspace")
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "Error: Required config value missing: $var" >&2
        exit 1
    fi
done

# Generate tool slug (lowercase, alphanumeric + hyphens)
TOOL_SLUG=$(echo "$tool" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

# Determine run number from run_id or default to 1
RUN_NUMBER=1
if [[ -n "${run_id:-}" ]]; then
    if echo "$run_id" | grep -qi "run2\|run-2"; then
        RUN_NUMBER=2
    fi
fi

# Generate timestamp from run directory name or current time
RUN_DIR_NAME=$(basename "$RUN_DIR")
TIMESTAMP=""
if [[ "$RUN_DIR_NAME" =~ ^[0-9]{8}T[0-9]{4}$ ]]; then
    TIMESTAMP="$RUN_DIR_NAME"
else
    TIMESTAMP=$(date +%Y%m%dT%H%M)
fi

# Generate output filename
MODEL_STR="model${model}"
API_STR="$api_type"
RUN_STR="run${RUN_NUMBER}"
OUTPUT_FILENAME="${TOOL_SLUG}_${MODEL_STR}_${API_STR}_${RUN_STR}_${TIMESTAMP}.json"
OUTPUT_PATH="$OUTPUT_DIR/$OUTPUT_FILENAME"

# Get current timestamp for submission
SUBMITTED_TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)

# Try to detect submission method (check if AI run report exists)
SUBMISSION_METHOD="manual"
AI_RUN_REPORT="$workspace/benchmark/ai_run_report.md"
if [[ -f "$AI_RUN_REPORT" ]]; then
    SUBMISSION_METHOD="automated"
fi

# Try to get submitter info
SUBMITTED_BY="${USER:-unknown}"
if command -v git &> /dev/null && git -C "$REPO_ROOT" rev-parse --git-dir &> /dev/null; then
    GIT_USER=$(git -C "$REPO_ROOT" config user.name 2>/dev/null || echo "")
    if [[ -n "$GIT_USER" ]]; then
        SUBMITTED_BY="$GIT_USER"
    fi
fi

# Extract metrics from AI run report if it exists
# Use absolute path for reading, but relative path for artifact reference
# Benchmark folder is at run level, not inside workspace
AI_RUN_REPORT_ABS="$RUN_DIR/benchmark/ai_run_report.md"
GENERATION_STARTED=""
CODE_COMPLETE=""
BUILD_CLEAN=""
SEED_LOADED=""
APP_STARTED=""
ALL_TESTS_PASS=""
TOTAL_MINUTES=""
TEST_TOTAL=""
TEST_PASSED=""
TEST_FAILED=""
TEST_PASS_RATE=""
BACKEND_RUNTIME=""
BACKEND_FRAMEWORK=""
DATABASE=""

if [[ -f "$AI_RUN_REPORT_ABS" ]]; then
    # Extract all timestamps from AI run report (handle markdown backticks and list format)
    # Pattern: - `field_name`: timestamp (need to match first colon after field name)
    if grep -q "generation_started" "$AI_RUN_REPORT"; then
        GENERATION_STARTED=$(grep "generation_started" "$AI_RUN_REPORT" | head -1 | sed 's/.*`generation_started`: *//' | sed 's/`//g' | sed 's/ (.*//' | tr -d '[:space:]')
    fi
    
    if grep -q "code_complete" "$AI_RUN_REPORT"; then
        CODE_COMPLETE=$(grep "code_complete" "$AI_RUN_REPORT" | head -1 | sed 's/.*`code_complete`: *//' | sed 's/`//g' | sed 's/ (.*//' | tr -d '[:space:]')
    fi
    
    if grep -q "build_clean" "$AI_RUN_REPORT"; then
        BUILD_CLEAN=$(grep "build_clean" "$AI_RUN_REPORT" | head -1 | sed 's/.*`build_clean`: *//' | sed 's/`//g' | sed 's/ (.*//' | tr -d '[:space:]')
    fi
    
    if grep -q "seed_loaded" "$AI_RUN_REPORT"; then
        SEED_LOADED=$(grep "seed_loaded" "$AI_RUN_REPORT" | head -1 | sed 's/.*`seed_loaded`: *//' | sed 's/`//g' | sed 's/ (.*//' | tr -d '[:space:]')
    fi
    
    if grep -q "app_started" "$AI_RUN_REPORT"; then
        APP_STARTED=$(grep "app_started" "$AI_RUN_REPORT" | head -1 | sed 's/.*`app_started`: *//' | sed 's/`//g' | sed 's/ (.*//' | tr -d '[:space:]')
    fi
    
    if grep -q "all_tests_pass" "$AI_RUN_REPORT"; then
        ALL_TESTS_PASS=$(grep "all_tests_pass" "$AI_RUN_REPORT" | head -1 | sed 's/.*`all_tests_pass`: *//' | sed 's/`//g' | sed 's/ (.*//' | tr -d '[:space:]')
    fi
    
    # Calculate total minutes from generation_started to all_tests_pass
    if [[ -n "$GENERATION_STARTED" && -n "$ALL_TESTS_PASS" ]]; then
        if command -v python3 &> /dev/null; then
            TOTAL_MINUTES=$(python3 -c "
from datetime import datetime
start = datetime.fromisoformat('${GENERATION_STARTED}'.replace('Z', '+00:00'))
end = datetime.fromisoformat('${ALL_TESTS_PASS}'.replace('Z', '+00:00'))
print(round((end - start).total_seconds() / 60, 1))
" 2>/dev/null || echo "")
        fi
    fi
    
    # Extract test results (handle markdown formatting with **bold**)
    # Try to get from Test Summary section first, then fall back to individual patterns
    if grep -q "\*\*Total Tests\*\*" "$AI_RUN_REPORT_ABS"; then
        TEST_TOTAL=$(grep "\*\*Total Tests\*\*" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*\*\*Total Tests\*\*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
    fi
    
    # Extract final pass rate from "Final Pass Rate: X% (Y/Z passing)" format
    if grep -qi "Final Pass Rate" "$AI_RUN_REPORT_ABS"; then
        FINAL_PASS_LINE=$(grep -i "Final Pass Rate" "$AI_RUN_REPORT_ABS" | head -1)
        # Extract "Y/Z passing" pattern
        if echo "$FINAL_PASS_LINE" | grep -q "([0-9]*/[0-9]* passing)"; then
            TEST_PASSED=$(echo "$FINAL_PASS_LINE" | sed 's/.*(\([0-9]*\)\/.*/\1/')
            TEST_TOTAL=$(echo "$FINAL_PASS_LINE" | sed 's/.*\/\([0-9]*\) passing.*/\1/')
            TEST_PASS_RATE=$(echo "$FINAL_PASS_LINE" | sed 's/.*Final Pass Rate.*: *\([0-9\.]*\)%.*/\1/')
        fi
    fi
    
    # Fallback to individual patterns if not found
    if [[ -z "$TEST_PASSED" ]] && grep -q "\*\*Passed\*\*" "$AI_RUN_REPORT_ABS"; then
        TEST_PASSED=$(grep "\*\*Passed\*\*" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*\*\*Passed\*\*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
    fi
    
    if [[ -z "$TEST_FAILED" ]] && grep -q "\*\*Failed\*\*" "$AI_RUN_REPORT_ABS"; then
        TEST_FAILED=$(grep "\*\*Failed\*\*" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*\*\*Failed\*\*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
    fi
    
    if [[ -z "$TEST_PASS_RATE" ]] && grep -q "\*\*Pass Rate\*\*" "$AI_RUN_REPORT_ABS"; then
        TEST_PASS_RATE=$(grep "\*\*Pass Rate\*\*" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*\*\*Pass Rate\*\*: *//' | sed 's/%//' | sed 's/\*\*//g' | tr -d '[:space:]')
    fi
    
    # Extract tech stack
    if grep -q "Backend Runtime" "$AI_RUN_REPORT_ABS"; then
        BACKEND_RUNTIME=$(grep "Backend Runtime" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*Backend Runtime.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
    fi
    
    if grep -q "Backend Framework" "$AI_RUN_REPORT_ABS"; then
        BACKEND_FRAMEWORK=$(grep "Backend Framework" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*Backend Framework.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
    fi
    
    if grep -q "Database:" "$AI_RUN_REPORT_ABS"; then
        DATABASE=$(grep "Database:" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*Database: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
    fi
    
    # Extract LLM model
    LLM_MODEL="Unknown"
    if grep -qi "LLM Model\|llm_model\|Model:" "$AI_RUN_REPORT_ABS"; then
        LLM_MODEL=$(grep -i "LLM Model\|llm_model\|Model:" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*[Ll][Ll][Mm] [Mm]odel.*: *//' | sed 's/.*Model: *//' | sed 's/\*\*//g' | sed 's/`//g' | head -c 100 | tr -d '[:space:]')
        if [[ -z "$LLM_MODEL" || "$LLM_MODEL" == ":" ]]; then
            LLM_MODEL="Unknown"
        fi
    fi
    
    # Extract test iterations count
    TEST_ITERATIONS_COUNT=""
    if grep -qi "test_iterations" "$AI_RUN_REPORT_ABS"; then
        TEST_ITERATIONS_COUNT=$(grep -i "test_iterations" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*test_iterations.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
    fi
    
    # Extract operator intervention metrics
    CLARIFICATIONS_COUNT=""
    INTERVENTIONS_COUNT=""
    RERUNS_COUNT=""
    
    if grep -qi "clarifications_count\|clarifications:" "$AI_RUN_REPORT_ABS"; then
        CLARIFICATIONS_COUNT=$(grep -i "clarifications_count\|clarifications:" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*clarifications.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
    fi
    
    if grep -qi "interventions_count\|interventions:" "$AI_RUN_REPORT_ABS"; then
        INTERVENTIONS_COUNT=$(grep -i "interventions_count\|interventions:" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*interventions.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
    fi
    
    if grep -qi "reruns_count\|reruns:" "$AI_RUN_REPORT_ABS"; then
        RERUNS_COUNT=$(grep -i "reruns_count\|reruns:" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*reruns.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
    fi
    
    # Extract LLM usage metrics
    LLM_INPUT_TOKENS=""
    LLM_OUTPUT_TOKENS=""
    LLM_TOTAL_TOKENS=""
    LLM_REQUESTS_COUNT=""
    LLM_ESTIMATED_COST=""
    LLM_COST_CURRENCY="USD"
    LLM_USAGE_SOURCE="unknown"
    
    if grep -qi "backend_tokens\|total_tokens" "$AI_RUN_REPORT_ABS"; then
        # Extract token value, handling markdown backticks and various formats
        TOKEN_VALUE=$(grep -i "backend_tokens\|total_tokens" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*backend_tokens.*: *//' | sed 's/.*total_tokens.*: *//' | sed 's/`//g' | sed 's/\*\*//g' | sed 's/\[.*\]//g' | tr -d '[:space:]')
        # Convert M/K suffixes to numbers
        if echo "$TOKEN_VALUE" | grep -qi "M"; then
            # Handle decimal M values like "11.2M"
            NUM=$(echo "$TOKEN_VALUE" | sed 's/M//i' | sed 's/m//i')
            LLM_TOTAL_TOKENS=$(echo "$NUM * 1000000" | bc 2>/dev/null | tr -d '[:space:]' || echo "")
        elif echo "$TOKEN_VALUE" | grep -qi "K"; then
            NUM=$(echo "$TOKEN_VALUE" | sed 's/K//i' | sed 's/k//i')
            LLM_TOTAL_TOKENS=$(echo "$NUM * 1000" | bc 2>/dev/null | tr -d '[:space:]' || echo "")
        else
            # Plain number
            LLM_TOTAL_TOKENS=$(echo "$TOKEN_VALUE" | tr -d '[:space:]')
        fi
        # Only set usage_source if we successfully extracted a value
        if [[ -n "${LLM_TOTAL_TOKENS:-}" ]]; then
            LLM_USAGE_SOURCE="tool_reported"
        fi
    fi
    
    if grep -qi "backend_requests\|requests_count" "$AI_RUN_REPORT_ABS"; then
        LLM_REQUESTS_COUNT=$(grep -i "backend_requests\|requests_count" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*backend_requests.*: *//' | sed 's/.*requests_count.*: *//' | sed 's/`//g' | sed 's/\*\*//g' | sed 's/\[.*\]//g' | tr -d '[:space:]')
    fi
    
    if grep -qi "input_tokens" "$AI_RUN_REPORT_ABS"; then
        LLM_INPUT_TOKENS=$(grep -i "input_tokens" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*input_tokens.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
        LLM_USAGE_SOURCE="tool_reported"
    fi
    
    if grep -qi "output_tokens" "$AI_RUN_REPORT_ABS"; then
        LLM_OUTPUT_TOKENS=$(grep -i "output_tokens" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*output_tokens.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
    fi
    
    if grep -qi "estimated_cost" "$AI_RUN_REPORT_ABS"; then
        LLM_ESTIMATED_COST=$(grep -i "estimated_cost" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*estimated_cost.*: *//' | sed 's/\*\*//g' | sed 's/USD//' | tr -d '[:space:]')
    fi
    
    if grep -qi "cost_currency" "$AI_RUN_REPORT_ABS"; then
        LLM_COST_CURRENCY=$(grep -i "cost_currency" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*cost_currency.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
        if [[ -z "$LLM_COST_CURRENCY" ]]; then
            LLM_COST_CURRENCY="USD"
        fi
    fi
    
    if grep -qi "usage_source" "$AI_RUN_REPORT_ABS"; then
        USAGE_SRC=$(grep -i "usage_source" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*usage_source.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [[ "$USAGE_SRC" == "tool_reported" || "$USAGE_SRC" == "operator_estimated" || "$USAGE_SRC" == "unknown" ]]; then
            LLM_USAGE_SOURCE="$USAGE_SRC"
        fi
    fi
    
    # Extract backend_model_used if available
    if grep -qi "backend_model_used" "$AI_RUN_REPORT_ABS"; then
        BACKEND_MODEL=$(grep -i "backend_model_used" "$AI_RUN_REPORT_ABS" | head -1 | sed 's/.*backend_model_used.*: *//' | sed 's/\*\*//g' | sed 's/`//g' | tr -d '[:space:]')
        if [[ -n "$BACKEND_MODEL" && "$BACKEND_MODEL" != ":" ]]; then
            LLM_MODEL="$BACKEND_MODEL"
        fi
    fi
    
    # Extract test runs - parse all test_run_N_start, test_run_N_end, etc.
    # We'll pass the AI run report absolute path to Python script to parse test runs properly
fi

# Get run environment
RUN_ENV="${run_environment:-$(uname -s) $(uname -r)}"

# Generate run_id if not set
RUN_ID="${run_id:-${tool// /-}-Model${model}-$(basename "$RUN_DIR")}"

# Determine artifact paths (relative to run folder, or empty if not accessible)
# Note: Artifacts are in the run folder, so paths should be relative to run folder or empty
TOOL_TRANSCRIPT_PATH=""
RUN_INSTRUCTIONS_PATH=""
CONTRACT_ARTIFACT_PATH=""
ACCEPTANCE_CHECKLIST_PATH=""
ACCEPTANCE_EVIDENCE_PATH=""
DETERMINISM_EVIDENCE_PATH=""
OVERREACH_EVIDENCE_PATH=""
AUTOMATED_TESTS_PATH=""
AI_RUN_REPORT_PATH=""

# Find artifacts relative to run folder
if [[ -f "$RUN_DIR/transcript.md" ]]; then
    TOOL_TRANSCRIPT_PATH="transcript.md"
fi

if [[ -f "$workspace/benchmark/run_instructions.md" ]]; then
    RUN_INSTRUCTIONS_PATH=$(realpath --relative-to="$RUN_DIR" "$workspace/benchmark/run_instructions.md" 2>/dev/null || echo "")
fi

# Find contract artifact (in application code, not benchmark folder)
if [[ "$api_type" == "REST" ]]; then
    # Check backend directory first, then workspace root
    if [[ -f "$workspace/backend/openapi.yaml" ]]; then
        CONTRACT_ARTIFACT_PATH=$(realpath --relative-to="$RUN_DIR" "$workspace/backend/openapi.yaml" 2>/dev/null || echo "")
    elif [[ -f "$workspace/openapi.yaml" ]]; then
        CONTRACT_ARTIFACT_PATH=$(realpath --relative-to="$RUN_DIR" "$workspace/openapi.yaml" 2>/dev/null || echo "")
    fi
else
    # GraphQL - check backend/src directory
    if [[ -f "$workspace/backend/src/schema.graphql" ]]; then
        CONTRACT_ARTIFACT_PATH=$(realpath --relative-to="$RUN_DIR" "$workspace/backend/src/schema.graphql" 2>/dev/null || echo "")
    elif [[ -f "$workspace/schema.graphql" ]]; then
        CONTRACT_ARTIFACT_PATH=$(realpath --relative-to="$RUN_DIR" "$workspace/schema.graphql" 2>/dev/null || echo "")
    fi
fi

if [[ -f "$workspace/benchmark/acceptance_checklist.md" ]]; then
    ACCEPTANCE_CHECKLIST_PATH=$(realpath --relative-to="$RUN_DIR" "$workspace/benchmark/acceptance_checklist.md" 2>/dev/null || echo "")
fi

# AI run report path - artifacts are in run folder, paths not needed in result file
AI_RUN_REPORT_PATH=""

# Evidence paths - these are typically in run folder
if [[ -d "$RUN_DIR/acceptance_evidence" ]]; then
    ACCEPTANCE_EVIDENCE_PATH="acceptance_evidence"
fi

if [[ -f "$RUN_DIR/determinism_evidence.md" ]] || [[ -d "$RUN_DIR/determinism_evidence" ]]; then
    if [[ -f "$RUN_DIR/determinism_evidence.md" ]]; then
        DETERMINISM_EVIDENCE_PATH="determinism_evidence.md"
    else
        DETERMINISM_EVIDENCE_PATH="determinism_evidence"
    fi
fi

if [[ -f "$RUN_DIR/overreach_notes.md" ]]; then
    OVERREACH_EVIDENCE_PATH="overreach_notes.md"
fi

# Check for tests - relative to run folder
if [[ -d "$workspace/backend/tests" ]]; then
    AUTOMATED_TESTS_PATH=$(realpath --relative-to="$RUN_DIR" "$workspace/backend/tests" 2>/dev/null || echo "")
elif [[ -d "$workspace/tests" ]]; then
    AUTOMATED_TESTS_PATH=$(realpath --relative-to="$RUN_DIR" "$workspace/tests" 2>/dev/null || echo "")
fi

# Check for UI implementation
UI_SOURCE_PATH=""
UI_RUN_SUMMARY_PATH=""
UI_BUILD_SUCCESS=""
UI_START_TIMESTAMP=""
UI_END_TIMESTAMP=""
UI_DURATION_MINUTES=""
UI_LLM_MODEL="Unknown"
UI_LLM_INPUT_TOKENS=""
UI_LLM_OUTPUT_TOKENS=""
UI_LLM_TOTAL_TOKENS=""
UI_LLM_REQUESTS_COUNT=""
UI_LLM_ESTIMATED_COST=""
UI_LLM_COST_CURRENCY="USD"
UI_LLM_USAGE_SOURCE="unknown"
UI_CLARIFICATIONS_COUNT=""
UI_INTERVENTIONS_COUNT=""
UI_RERUNS_COUNT=""
UI_BACKEND_CHANGES_REQUIRED=false

if [[ -d "$workspace/ui" ]]; then
    UI_SOURCE_PATH=$(realpath --relative-to="$RUN_DIR" "$workspace/ui" 2>/dev/null || echo "")
    
    # Check for UI run summary
    if [[ -f "$workspace/benchmark/ui_run_summary.md" ]]; then
        UI_RUN_SUMMARY_PATH=$(realpath --relative-to="$RUN_DIR" "$workspace/benchmark/ui_run_summary.md" 2>/dev/null || echo "")
        
        # Extract UI metrics from UI run summary
        if grep -qi "ui_generation_started\|ui_build_success" "$workspace/benchmark/ui_run_summary.md"; then
            if grep -qi "ui_build_success.*true\|build_success.*true" "$workspace/benchmark/ui_run_summary.md"; then
                UI_BUILD_SUCCESS="true"
            elif grep -qi "ui_build_success.*false\|build_success.*false" "$workspace/benchmark/ui_run_summary.md"; then
                UI_BUILD_SUCCESS="false"
            fi
            
            if grep -qi "ui_generation_started" "$workspace/benchmark/ui_run_summary.md"; then
                UI_START_TIMESTAMP=$(grep -i "ui_generation_started" "$workspace/benchmark/ui_run_summary.md" | head -1 | sed 's/.*ui_generation_started.*: *//' | sed 's/`//g' | sed 's/ (.*//' | tr -d '[:space:]')
            fi
            
            if grep -qi "ui_running\|ui_code_complete" "$workspace/benchmark/ui_run_summary.md"; then
                UI_END_TIMESTAMP=$(grep -i "ui_running\|ui_code_complete" "$workspace/benchmark/ui_run_summary.md" | head -1 | sed 's/.*ui_running.*: *//' | sed 's/.*ui_code_complete.*: *//' | sed 's/`//g' | sed 's/ (.*//' | tr -d '[:space:]')
            fi
            
            # Extract UI LLM usage if available
            if grep -qi "input_tokens" "$workspace/benchmark/ui_run_summary.md"; then
                UI_LLM_INPUT_TOKENS=$(grep -i "input_tokens" "$workspace/benchmark/ui_run_summary.md" | head -1 | sed 's/.*input_tokens.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
                UI_LLM_USAGE_SOURCE="tool_reported"
            fi
            
            if grep -qi "output_tokens" "$workspace/benchmark/ui_run_summary.md"; then
                UI_LLM_OUTPUT_TOKENS=$(grep -i "output_tokens" "$workspace/benchmark/ui_run_summary.md" | head -1 | sed 's/.*output_tokens.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
            fi
            
            if grep -qi "total_tokens" "$workspace/benchmark/ui_run_summary.md"; then
                UI_LLM_TOTAL_TOKENS=$(grep -i "total_tokens" "$workspace/benchmark/ui_run_summary.md" | head -1 | sed 's/.*total_tokens.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
            fi
            
            if grep -qi "requests_count" "$workspace/benchmark/ui_run_summary.md"; then
                UI_LLM_REQUESTS_COUNT=$(grep -i "requests_count" "$workspace/benchmark/ui_run_summary.md" | head -1 | sed 's/.*requests_count.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
            fi
            
            if grep -qi "estimated_cost" "$workspace/benchmark/ui_run_summary.md"; then
                UI_LLM_ESTIMATED_COST=$(grep -i "estimated_cost" "$workspace/benchmark/ui_run_summary.md" | head -1 | sed 's/.*estimated_cost.*: *//' | sed 's/\*\*//g' | sed 's/USD//' | tr -d '[:space:]')
            fi
            
            # Extract UI intervention metrics
            if grep -qi "clarifications_count\|clarifications:" "$workspace/benchmark/ui_run_summary.md"; then
                UI_CLARIFICATIONS_COUNT=$(grep -i "clarifications_count\|clarifications:" "$workspace/benchmark/ui_run_summary.md" | head -1 | sed 's/.*clarifications.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
            fi
            
            if grep -qi "interventions_count\|interventions:" "$workspace/benchmark/ui_run_summary.md"; then
                UI_INTERVENTIONS_COUNT=$(grep -i "interventions_count\|interventions:" "$workspace/benchmark/ui_run_summary.md" | head -1 | sed 's/.*interventions.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
            fi
            
            if grep -qi "reruns_count\|reruns:" "$workspace/benchmark/ui_run_summary.md"; then
                UI_RERUNS_COUNT=$(grep -i "reruns_count\|reruns:" "$workspace/benchmark/ui_run_summary.md" | head -1 | sed 's/.*reruns.*: *//' | sed 's/\*\*//g' | tr -d '[:space:]')
            fi
        fi
    fi
fi

# Generate result file as JSON - v2.0 schema format
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" <<'PYTHON_EOF'
import json
import sys
import re
from datetime import datetime
from pathlib import Path

def to_num(val):
    """Convert value to number if possible, else return None."""
    if not val or val == "" or val == "Unknown":
        return None
    try:
        if '.' in str(val):
            return float(val)
        return int(val)
    except (ValueError, TypeError):
        return None

def parse_test_runs(ai_run_report_path):
    """Parse test run iterations from AI run report."""
    test_runs = []
    if not ai_run_report_path or not Path(ai_run_report_path).exists():
        return test_runs
    
    try:
        with open(ai_run_report_path, 'r') as f:
            content = f.read()
        
        # Find all test_run_N_start patterns (handle markdown format: - `test_run_N_start`: timestamp)
        # Pattern matches: `test_run_N_start`: timestamp or test_run_N_start: timestamp
        pattern = r'`?test_run_(\d+)_start`?[:\s]*([0-9TZ:\.-]+)'
        matches = re.findall(pattern, content, re.IGNORECASE)
        
        for run_num_str, start_ts in matches:
            run_num = int(run_num_str)
            
            # Clean timestamp (remove trailing "(estimated)" or other text)
            start_ts = start_ts.split('(')[0].strip()
            
            # Find corresponding end timestamp
            end_pattern = r'`?test_run_{}_end`?[:\s]*([0-9TZ:\.-]+)'.format(run_num)
            end_match = re.search(end_pattern, content, re.IGNORECASE)
            end_ts = None
            if end_match:
                end_ts = end_match.group(1).split('(')[0].strip()
            
            # Find test results for this run
            total_pattern = r'`?test_run_{}_total`?[:\s]*(\d+)'.format(run_num)
            passed_pattern = r'`?test_run_{}_passed`?[:\s]*(\d+)'.format(run_num)
            failed_pattern = r'`?test_run_{}_failed`?[:\s]*(\d+)'.format(run_num)
            passrate_pattern = r'`?test_run_{}_pass_rate`?[:\s]*([0-9\.]+)'.format(run_num)
            
            total_match = re.search(total_pattern, content, re.IGNORECASE)
            passed_match = re.search(passed_pattern, content, re.IGNORECASE)
            failed_match = re.search(failed_pattern, content, re.IGNORECASE)
            passrate_match = re.search(passrate_pattern, content, re.IGNORECASE)
            
            total = to_num(total_match.group(1)) if total_match else None
            passed = to_num(passed_match.group(1)) if passed_match else None
            failed = to_num(failed_match.group(1)) if failed_match else None
            pass_rate = to_num(passrate_match.group(1)) if passrate_match else None
            
            # Calculate duration if we have both timestamps
            duration_minutes = None
            if start_ts and end_ts:
                try:
                    start_dt = datetime.fromisoformat(start_ts.replace('Z', '+00:00'))
                    end_dt = datetime.fromisoformat(end_ts.replace('Z', '+00:00'))
                    duration_minutes = round((end_dt - start_dt).total_seconds() / 60, 2)
                except:
                    pass
            
            if start_ts and end_ts and total is not None and passed is not None:
                test_runs.append({
                    "run_number": run_num,
                    "start_timestamp": start_ts,
                    "end_timestamp": end_ts,
                    "duration_minutes": duration_minutes or 0,
                    "total_tests": total,
                    "passed": passed or 0,
                    "failed": failed or 0,
                    "pass_rate": pass_rate if pass_rate is not None else (passed / total if passed and total else 0.0)
                })
    except Exception as e:
        pass  # If parsing fails, return empty list
    
    return sorted(test_runs, key=lambda x: x['run_number'])

# Read values from command line args
args = sys.argv[1:]
i = 0

# Extract arguments
tool_name = args[i]
tool_version = args[i+1] or ""
run_id = args[i+2]
target_model = args[i+3]
api_style = args[i+4]
spec_reference = args[i+5]
run_environment = args[i+6]
generation_started = args[i+7] if len(args) > i+7 else ""
code_complete = args[i+8] if len(args) > i+8 else ""
build_clean = args[i+9] if len(args) > i+9 else ""
seed_loaded = args[i+10] if len(args) > i+10 else ""
app_started = args[i+11] if len(args) > i+11 else ""
all_tests_pass = args[i+12] if len(args) > i+12 else ""
total_minutes = to_num(args[i+13]) if len(args) > i+13 and args[i+13] else None
test_total = to_num(args[i+14]) if len(args) > i+14 and args[i+14] else None
test_passed = to_num(args[i+15]) if len(args) > i+15 and args[i+15] else None
test_failed = to_num(args[i+16]) if len(args) > i+16 and args[i+16] else None
test_pass_rate = to_num(args[i+17]) if len(args) > i+17 and args[i+17] else None
test_iterations_count = to_num(args[i+18]) if len(args) > i+18 and args[i+18] else None
clarifications_count = to_num(args[i+19]) if len(args) > i+19 and args[i+19] else 0
interventions_count = to_num(args[i+20]) if len(args) > i+20 and args[i+20] else 0
reruns_count = to_num(args[i+21]) if len(args) > i+21 and args[i+21] else 0
llm_input_tokens = to_num(args[i+22]) if len(args) > i+22 and args[i+22] else None
llm_output_tokens = to_num(args[i+23]) if len(args) > i+23 and args[i+23] else None
llm_total_tokens = to_num(args[i+24]) if len(args) > i+24 and args[i+24] else None
llm_requests_count = to_num(args[i+25]) if len(args) > i+25 and args[i+25] else None
llm_estimated_cost = to_num(args[i+26]) if len(args) > i+26 and args[i+26] else None
llm_cost_currency = args[i+27] if len(args) > i+27 and args[i+27] else "USD"
llm_usage_source = args[i+28] if len(args) > i+28 and args[i+28] in ["tool_reported", "operator_estimated", "unknown"] else "unknown"
llm_model = args[i+29] if len(args) > i+29 else "Unknown"
ai_run_report_path = args[i+30] if len(args) > i+30 and args[i+30] else ""
contract_artifact_path = args[i+31] if len(args) > i+31 else ""
run_instructions_path = args[i+32] if len(args) > i+32 else ""
acceptance_checklist_path = args[i+33] if len(args) > i+33 else ""
run_number = int(args[i+34]) if len(args) > i+34 and args[i+34] else 1
workspace_path = args[i+35] if len(args) > i+35 else ""
ui_source_path = args[i+36] if len(args) > i+36 else ""
ui_run_summary_path = args[i+37] if len(args) > i+37 else ""
ui_build_success = args[i+38] if len(args) > i+38 else ""
ui_start_timestamp = args[i+39] if len(args) > i+39 else ""
ui_end_timestamp = args[i+40] if len(args) > i+40 else ""
ui_duration_minutes = to_num(args[i+41]) if len(args) > i+41 and args[i+41] else None
ui_llm_model = args[i+42] if len(args) > i+42 else "Unknown"
ui_llm_input_tokens = to_num(args[i+43]) if len(args) > i+43 and args[i+43] else None
ui_llm_output_tokens = to_num(args[i+44]) if len(args) > i+44 and args[i+44] else None
ui_llm_total_tokens = to_num(args[i+45]) if len(args) > i+45 and args[i+45] else None
ui_llm_requests_count = to_num(args[i+46]) if len(args) > i+46 and args[i+46] else None
ui_llm_estimated_cost = to_num(args[i+47]) if len(args) > i+47 and args[i+47] else None
ui_llm_cost_currency = args[i+48] if len(args) > i+48 and args[i+48] else "USD"
ui_llm_usage_source = args[i+49] if len(args) > i+49 and args[i+49] in ["tool_reported", "operator_estimated", "unknown"] else "unknown"
ui_clarifications_count = to_num(args[i+50]) if len(args) > i+50 and args[i+50] else 0
ui_interventions_count = to_num(args[i+51]) if len(args) > i+51 and args[i+51] else 0
ui_reruns_count = to_num(args[i+52]) if len(args) > i+52 and args[i+52] else 0
ui_backend_changes_required = args[i+53].lower() == "true" if len(args) > i+53 and args[i+53] else False
submitted_timestamp = args[i+54] if len(args) > i+54 else ""
submitted_by = args[i+55] if len(args) > i+55 else ""
submission_method = args[i+56] if len(args) > i+56 else "automated"

# Parse test runs from AI run report
test_runs = []
if ai_run_report_path and ai_run_report_path.strip():
    try:
        from pathlib import Path
        if Path(ai_run_report_path).exists():
            test_runs = parse_test_runs(ai_run_report_path)
            # If we parsed test runs but don't have iterations count, use the count
            if not test_iterations_count and test_runs:
                test_iterations_count = len(test_runs)
    except Exception as e:
        import sys
        print(f"Warning: Failed to parse test runs: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        pass  # If parsing fails, continue with empty test_runs

# Convert pass_rate to decimal if needed
passrate_decimal = None
if test_pass_rate is not None:
    passrate_decimal = test_pass_rate / 100.0 if test_pass_rate > 1 else test_pass_rate
elif test_passed is not None and test_total is not None and test_total > 0:
    passrate_decimal = test_passed / test_total

# Build LLM usage object
llm_usage = None
if llm_input_tokens is not None or llm_output_tokens is not None or llm_total_tokens is not None or llm_requests_count is not None or llm_estimated_cost is not None:
    llm_usage = {
        "input_tokens": llm_input_tokens,
        "output_tokens": llm_output_tokens,
        "total_tokens": llm_total_tokens or (llm_input_tokens + llm_output_tokens if llm_input_tokens and llm_output_tokens else None),
        "requests_count": llm_requests_count,
        "estimated_cost_usd": llm_estimated_cost,
        "cost_currency": llm_cost_currency,
        "usage_source": llm_usage_source
    }

# Calculate duration from timestamps if not provided
if not total_minutes and generation_started and all_tests_pass:
    try:
        start_dt = datetime.fromisoformat(generation_started.replace('Z', '+00:00'))
        end_dt = datetime.fromisoformat(all_tests_pass.replace('Z', '+00:00'))
        total_minutes = round((end_dt - start_dt).total_seconds() / 60, 2)
    except:
        pass

# Calculate UI duration if we have timestamps
ui_duration_calculated = None
if ui_start_timestamp and ui_end_timestamp:
    try:
        ui_start_dt = datetime.fromisoformat(ui_start_timestamp.replace('Z', '+00:00'))
        ui_end_dt = datetime.fromisoformat(ui_end_timestamp.replace('Z', '+00:00'))
        ui_duration_calculated = round((ui_end_dt - ui_start_dt).total_seconds() / 60, 2)
    except:
        pass

if not ui_duration_minutes and ui_duration_calculated:
    ui_duration_minutes = ui_duration_calculated

# Build UI LLM usage object
ui_llm_usage = None
if ui_llm_input_tokens is not None or ui_llm_output_tokens is not None or ui_llm_total_tokens is not None or ui_llm_requests_count is not None or ui_llm_estimated_cost is not None:
    ui_llm_usage = {
        "input_tokens": ui_llm_input_tokens,
        "output_tokens": ui_llm_output_tokens,
        "total_tokens": ui_llm_total_tokens or (ui_llm_input_tokens + ui_llm_output_tokens if ui_llm_input_tokens and ui_llm_output_tokens else None),
        "requests_count": ui_llm_requests_count,
        "estimated_cost_usd": ui_llm_estimated_cost,
        "cost_currency": ui_llm_cost_currency,
        "usage_source": ui_llm_usage_source
    }

# Build v2.0 schema-compliant result structure
result = {
    "schema_version": "2.0",
    "result_data": {
        "run_identity": {
            "tool_name": tool_name,
            "tool_version": tool_version,
            "run_id": run_id,
            "run_number": run_number,
            "target_model": target_model,
            "api_style": api_style,
            "spec_reference": spec_reference,
            "workspace_path": workspace_path,
            "run_environment": run_environment
        },
        "implementations": {
            "api": {
                "generation_metrics": {
                    "llm_model": llm_model,
                    "start_timestamp": generation_started,
                    "end_timestamp": all_tests_pass or app_started or "",
                    "duration_minutes": total_minutes or 0,
                    "clarifications_count": clarifications_count or 0,
                    "interventions_count": interventions_count or 0,
                    "reruns_count": reruns_count or 0,
                    "test_runs": test_runs,
                    "test_iterations_count": test_iterations_count or (len(test_runs) if test_runs else None),
                    "llm_usage": llm_usage
                },
                "acceptance": {
                    "pass_count": test_passed or 0,
                    "fail_count": test_failed or 0,
                    "not_run_count": 0,
                    "passrate": passrate_decimal if passrate_decimal is not None else 0.0
                }
            }
        },
        "submission": {
            "submitted_timestamp": submitted_timestamp,
            "submitted_by": submitted_by,
            "submission_method": submission_method
        }
    }
}

# Add UI implementation if UI exists
if ui_source_path:
    ui_impl = {
        "generation_metrics": {
            "llm_model": ui_llm_model,
            "start_timestamp": ui_start_timestamp,
            "end_timestamp": ui_end_timestamp,
            "duration_minutes": ui_duration_minutes or 0,
            "clarifications_count": ui_clarifications_count or 0,
            "interventions_count": ui_interventions_count or 0,
            "reruns_count": ui_reruns_count or 0,
            "backend_changes_required": ui_backend_changes_required,
            "llm_usage": ui_llm_usage
        },
        "build_success": ui_build_success.lower() == "true" if ui_build_success else False
    }
    result["result_data"]["implementations"]["ui"] = ui_impl

print(json.dumps(result, indent=2, ensure_ascii=False))
PYTHON_EOF

# Call Python script with arguments (v2.0 schema format)
python3 "$TEMP_SCRIPT" \
    "$tool" \
    "${tool_ver:-}" \
    "$RUN_ID" \
    "$model" \
    "$api_type" \
    "$spec_version" \
    "$RUN_ENV" \
    "${GENERATION_STARTED:-}" \
    "${CODE_COMPLETE:-}" \
    "${BUILD_CLEAN:-}" \
    "${SEED_LOADED:-}" \
    "${APP_STARTED:-}" \
    "${ALL_TESTS_PASS:-}" \
    "${TOTAL_MINUTES:-}" \
    "${TEST_TOTAL:-}" \
    "${TEST_PASSED:-}" \
    "${TEST_FAILED:-}" \
    "${TEST_PASS_RATE:-}" \
    "${TEST_ITERATIONS_COUNT:-}" \
    "${CLARIFICATIONS_COUNT:-0}" \
    "${INTERVENTIONS_COUNT:-0}" \
    "${RERUNS_COUNT:-0}" \
    "${LLM_INPUT_TOKENS:-}" \
    "${LLM_OUTPUT_TOKENS:-}" \
    "${LLM_TOTAL_TOKENS:-}" \
    "${LLM_REQUESTS_COUNT:-}" \
    "${LLM_ESTIMATED_COST:-}" \
    "${LLM_COST_CURRENCY:-USD}" \
    "${LLM_USAGE_SOURCE:-unknown}" \
    "${LLM_MODEL:-Unknown}" \
    "${AI_RUN_REPORT_ABS:-}" \
    "${CONTRACT_ARTIFACT_PATH:-}" \
    "${RUN_INSTRUCTIONS_PATH:-}" \
    "${ACCEPTANCE_CHECKLIST_PATH:-}" \
    "$RUN_NUMBER" \
    "$workspace" \
    "${UI_SOURCE_PATH:-}" \
    "${UI_RUN_SUMMARY_PATH:-}" \
    "${UI_BUILD_SUCCESS:-}" \
    "${UI_START_TIMESTAMP:-}" \
    "${UI_END_TIMESTAMP:-}" \
    "${UI_DURATION_MINUTES:-}" \
    "${UI_LLM_MODEL:-Unknown}" \
    "${UI_LLM_INPUT_TOKENS:-}" \
    "${UI_LLM_OUTPUT_TOKENS:-}" \
    "${UI_LLM_TOTAL_TOKENS:-}" \
    "${UI_LLM_REQUESTS_COUNT:-}" \
    "${UI_LLM_ESTIMATED_COST:-}" \
    "${UI_LLM_COST_CURRENCY:-USD}" \
    "${UI_LLM_USAGE_SOURCE:-unknown}" \
    "${UI_CLARIFICATIONS_COUNT:-}" \
    "${UI_INTERVENTIONS_COUNT:-}" \
    "${UI_RERUNS_COUNT:-}" \
    "${UI_BACKEND_CHANGES_REQUIRED:-false}" \
    "$SUBMITTED_TIMESTAMP" \
    "$SUBMITTED_BY" \
    "$SUBMISSION_METHOD" > "$OUTPUT_PATH"

# Clean up temp script
rm -f "$TEMP_SCRIPT"

echo "✓ Result file generated: $OUTPUT_PATH"
echo ""

# Display LLM usage tracking prompt
echo "⚠️  LLM USAGE TRACKING REQUIRED"
echo ""
echo "Before marking this run as complete, please check your LLM plan usage:"
echo ""

# Detect tool and show appropriate instructions
TOOL_LOWER=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
if [[ "$TOOL_LOWER" == *"cursor"* ]]; then
    echo "Tool: Cursor"
    echo "Check usage at: Cursor Settings → Usage/Billing, or visit the Cursor dashboard"
elif [[ "$TOOL_LOWER" == *"copilot"* ]] || [[ "$TOOL_LOWER" == *"github"* ]]; then
    echo "Tool: GitHub Copilot"
    echo "Check usage at: GitHub Settings → Copilot → Usage, or GitHub account billing page"
elif [[ "$TOOL_LOWER" == *"codeium"* ]]; then
    echo "Tool: Codeium"
    echo "Check usage at: Codeium dashboard or account settings"
else
    echo "Tool: $tool"
    echo "Check usage at: Your tool's billing/usage dashboard or account settings"
fi

echo ""
echo "1. Check your current LLM plan usage/billing status NOW"
echo "2. Note the current token/request counts or cost"
echo "3. After completion, check again to calculate the difference"
echo "4. Record usage metrics in the AI run report if available"
echo ""

if [[ -z "${LLM_INPUT_TOKENS:-}" && -z "${LLM_TOTAL_TOKENS:-}" ]]; then
    echo "ℹ️  No LLM usage metrics found in AI run report."
    echo "   Please add them manually to the result file or AI run report."
    echo ""
fi

echo "Generated result file with:"
if [[ -n "$GENERATION_STARTED" ]]; then
    echo "  - All timestamps extracted from AI run report"
fi
if [[ -n "$TEST_TOTAL" ]]; then
    echo "  - Test results: ${TEST_PASSED:-0}/${TEST_TOTAL} passed (${TEST_PASS_RATE:-0}%)"
fi
if [[ -n "$TOTAL_MINUTES" ]]; then
    echo "  - Total time: ${TOTAL_MINUTES} minutes"
fi
echo ""
echo "Next steps:"
echo "  1. Review the generated file: $OUTPUT_PATH"
echo "  2. Submit via email: ./scripts/submit_result.sh $OUTPUT_PATH"
echo "  3. Or validate and submit manually"

