#!/bin/bash
set -e

# Submit Result Script
# Validates and submits a benchmark result file via email

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/.submission.config"
CONFIG_TEMPLATE="$REPO_ROOT/.submission.config.template"
DEFAULT_EMAIL="pawmate.ai.challenge@gmail.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Function to load submission email from config
load_submission_email() {
    local email="$DEFAULT_EMAIL"
    
    # Try to load from .submission.config
    if [[ -f "$CONFIG_FILE" ]]; then
        if grep -q "^SUBMISSION_EMAIL=" "$CONFIG_FILE"; then
            email=$(grep "^SUBMISSION_EMAIL=" "$CONFIG_FILE" | cut -d'=' -f2)
            print_info "Using submission email from .submission.config: $email" >&2
        fi
    else
        # Create config from template if it doesn't exist
        if [[ -f "$CONFIG_TEMPLATE" ]]; then
            cp "$CONFIG_TEMPLATE" "$CONFIG_FILE"
            print_info "Created .submission.config from template" >&2
        fi
        print_info "Using default submission email: $email" >&2
    fi
    
    echo "$email"
}

# Function to validate JSON format
validate_json() {
    local file="$1"
    
    if ! python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
        return 1
    fi
    return 0
}

# Function to extract field from JSON
extract_json_field() {
    local file="$1"
    local field="$2"
    
    python3 -c "import json; data=json.load(open('$file')); print(data$field)" 2>/dev/null || echo ""
}

# Function to validate filename convention
validate_filename() {
    local filename="$1"
    
    # Expected pattern: {tool-slug}_{model}_{api-type}_{run-number}_{timestamp}.json
    if [[ "$filename" =~ ^[a-z0-9-]+_model[AB]_(REST|GraphQL)_run[12]_[0-9]{8}T[0-9]{4}\.json$ ]]; then
        return 0
    fi
    return 1
}

# Function to validate result file
validate_result_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    print_info "Validating result file..."
    
    # Check if file exists
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    # Validate JSON format
    print_info "Checking JSON format..."
    if ! validate_json "$file"; then
        print_error "Invalid JSON format"
        return 1
    fi
    print_success "Valid JSON format"
    
    # Validate filename convention
    print_info "Checking filename convention..."
    if ! validate_filename "$filename"; then
        print_warning "Filename does not match expected pattern"
        print_warning "Expected: {tool-slug}_{model}_{api-type}_{run-number}_{timestamp}.json"
        print_warning "Example: cursor-v0-43_modelA_REST_run1_20241218T1430.json"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    else
        print_success "Filename follows convention"
    fi
    
    # Check for required fields
    print_info "Checking required fields..."
    local schema_version=$(extract_json_field "$file" "['schema_version']")
    local tool_name=$(extract_json_field "$file" "['result_data']['run_identity']['tool_name']")
    local target_model=$(extract_json_field "$file" "['result_data']['run_identity']['target_model']")
    
    if [[ -z "$schema_version" ]] || [[ -z "$tool_name" ]] || [[ -z "$target_model" ]]; then
        print_error "Missing required fields in result file"
        return 1
    fi
    print_success "Required fields present"
    
    print_success "Validation complete"
    return 0
}

# Function to prompt for attribution
prompt_attribution() {
    echo "" >&2
    print_info "Attribution (optional)" >&2
    echo "You can provide your name or GitHub username to be credited for this submission." >&2
    echo "Press Enter to submit anonymously." >&2
    echo "" >&2
    read -p "Your name or GitHub username: " attribution >&2
    echo "$attribution"
}

# Function to generate email subject
generate_email_subject() {
    local filename="$1"
    # Extract components from filename for subject
    local basename=$(basename "$filename" .json)
    echo "[PawMate Result] $basename"
}

# Function to generate email body
generate_email_body() {
    local file="$1"
    local attribution="$2"
    local filename=$(basename "$file")
    
    # Read the JSON file content
    local json_content=$(cat "$file")
    
    local body="PawMate AI Challenge - Benchmark Result Submission

Submitted by: ${attribution:-Anonymous}
Tool: $(extract_json_field "$file" "['result_data']['run_identity']['tool_name']") $(extract_json_field "$file" "['result_data']['run_identity']['tool_version']")
Model: $(extract_json_field "$file" "['result_data']['run_identity']['target_model']")
API Style: $(extract_json_field "$file" "['result_data']['run_identity']['api_style']")
Run Number: $(extract_json_field "$file" "['result_data']['run_identity']['run_number']")
Timestamp: $(echo "$filename" | sed 's/.*_\([0-9]\{8\}T[0-9]\{4\}\)\.json$/\1/')
Spec Version: $(extract_json_field "$file" "['result_data']['run_identity']['spec_reference']")

Result Data (JSON):
---

$json_content

---

Generated using: https://github.com/rsdickerson/pawmate-ai-challenge
"
    
    echo "$body"
}

# Function to open email client
open_email_client() {
    local email="$1"
    local subject="$2"
    local body="$3"
    
    # URL-encode the subject and body
    local encoded_subject=$(echo "$subject" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))")
    local encoded_body=$(echo "$body" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")
    
    local mailto_url="mailto:${email}?subject=${encoded_subject}&body=${encoded_body}"
    
    print_info "Opening email client..."
    
    # Try to open email client (cross-platform)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        open "$mailto_url" 2>/dev/null
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        xdg-open "$mailto_url" 2>/dev/null || sensible-browser "$mailto_url" 2>/dev/null
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        # Windows (Git Bash or Cygwin)
        start "$mailto_url" 2>/dev/null
    else
        return 1
    fi
    
    return 0
}

# Function to display manual instructions
display_manual_instructions() {
    local email="$1"
    local subject="$2"
    local file="$3"
    local body="$4"
    
    echo ""
    echo "============================================================"
    print_info "MANUAL SUBMISSION INSTRUCTIONS"
    echo "============================================================"
    echo ""
    echo "1. Create a new email to: ${BLUE}$email${NC}"
    echo ""
    echo "2. Use this subject line:"
    echo "   ${BLUE}$subject${NC}"
    echo ""
    echo "3. Copy and paste this email body:"
    echo ""
    echo "---"
    echo "$body"
    echo "---"
    echo ""
    echo "4. Send the email (no attachment needed - JSON is in the body)"
    echo ""
    echo "============================================================"
}

# Main script
main() {
    echo "============================================================"
    echo "  PawMate AI Challenge - Result Submission"
    echo "============================================================"
    echo ""
    
    # Check for result file argument
    if [[ $# -eq 0 ]]; then
        print_error "No result file specified"
        echo ""
        echo "Usage: $0 <result-file.json>"
        echo ""
        echo "Example:"
        echo "  $0 cursor_modelA_REST_run1_20241218T1430.json"
        echo ""
        exit 1
    fi
    
    local result_file="$1"
    
    # Convert to absolute path if relative
    if [[ ! "$result_file" = /* ]]; then
        result_file="$(pwd)/$result_file"
    fi
    
    # Validate the result file
    if ! validate_result_file "$result_file"; then
        print_error "Validation failed. Please fix the issues and try again."
        exit 1
    fi
    
    echo ""
    
    # Prompt for attribution
    local attribution=$(prompt_attribution)
    
    # Load submission email
    local submission_email=$(load_submission_email)
    
    # Generate email content
    local subject=$(generate_email_subject "$result_file")
    local body=$(generate_email_body "$result_file" "$attribution")
    
    echo ""
    print_success "Result file is ready to submit!"
    echo ""
    
    # Try to open email client
    if open_email_client "$submission_email" "$subject" "$body"; then
        print_success "Email client opened"
        echo ""
        print_info "The result JSON has been included in the email body."
        echo ""
        print_info "Review the email and send when ready."
        echo ""
    else
        print_warning "Could not automatically open email client"
        display_manual_instructions "$submission_email" "$subject" "$result_file" "$body"
    fi
    
    echo ""
    print_success "Thank you for submitting your benchmark results!"
    echo ""
}

# Run main function
main "$@"

