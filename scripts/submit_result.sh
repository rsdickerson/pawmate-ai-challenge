#!/bin/bash
set -e

# Submit Result Script
# Validates and submits a benchmark result file via GitHub Issue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/.submission.config"
CONFIG_TEMPLATE="$REPO_ROOT/.submission.config.template"
GITHUB_REPO_OWNER="rsdickerson"
GITHUB_REPO_NAME="pawmate-ai-results"
GITHUB_API_URL="https://api.github.com/repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/issues"

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

# Function to load GitHub token from config or environment
load_github_token() {
    local token=""
    
    # Try to load from .submission.config first (priority)
    if [[ -f "$CONFIG_FILE" ]]; then
        if grep -q "^GITHUB_TOKEN=" "$CONFIG_FILE"; then
            token=$(grep "^GITHUB_TOKEN=" "$CONFIG_FILE" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        fi
    fi
    
    # Fall back to environment variable if config file didn't provide a token
    if [[ -z "$token" ]] && [[ -n "${GITHUB_TOKEN:-}" ]]; then
        token=$(echo "${GITHUB_TOKEN}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi
    
    # Return token (may be empty)
    echo "$token"
}

# Function to validate GitHub token format (basic checks)
validate_github_token() {
    local token="$1"
    
    # Check if token is empty
    if [[ -z "$token" ]]; then
        return 1
    fi
    
    # Basic format check: GitHub personal access tokens are typically 40+ characters
    # Classic tokens: 40 chars, fine-grained tokens: variable length
    # At minimum, check it's not obviously invalid (too short)
    if [[ ${#token} -lt 20 ]]; then
        return 1
    fi
    
    return 0
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

# Function to generate GitHub Issue title
generate_issue_title() {
    local file="$1"
    local tool_name=$(extract_json_field "$file" "['result_data']['run_identity']['tool_name']")
    local target_model=$(extract_json_field "$file" "['result_data']['run_identity']['target_model']")
    local api_style=$(extract_json_field "$file" "['result_data']['run_identity']['api_style']")
    local run_number=$(extract_json_field "$file" "['result_data']['run_identity']['run_number']")
    
    # Format: [Submission] Tool: {tool_name}, Model: {target_model}, API: {api_style}, Run: {run_number}
    echo "[Submission] Tool: ${tool_name}, Model: ${target_model}, API: ${api_style}, Run: ${run_number}"
}

# Function to generate GitHub Issue body
generate_issue_body() {
    local file="$1"
    local attribution="$2"
    
    # Read the JSON file content
    local json_content=$(cat "$file")
    
    # Format the body to include JSON in a way compatible with the template's textarea field
    # The template expects the JSON in the result_json textarea field
    local body="## PawMate AI Challenge Result Submission

Submitted by: ${attribution:-Anonymous}

### Result JSON

\`\`\`json
${json_content}
\`\`\`

---

Generated using: https://github.com/rsdickerson/pawmate-ai-challenge
"
    
    echo "$body"
}

# Function to create GitHub Issue via API
create_github_issue() {
    local file="$1"
    local attribution="$2"
    local token="$3"
    
    # Generate issue title
    local title=$(generate_issue_title "$file")
    
    # Read JSON content from file
    local json_content=$(cat "$file")
    
    # Create temporary file for payload to avoid shell escaping issues
    local payload_file=$(mktemp)
    
    # Generate payload using Python to properly escape JSON
    # Use environment variables to pass data to Python
    export PYTHON_TITLE="$title"
    export PYTHON_ATTRIBUTION="${attribution:-Anonymous}"
    export PYTHON_JSON_CONTENT="$json_content"
    
    python3 <<'PYTHON_EOF' > "$payload_file"
import json
import os

title = os.environ.get('PYTHON_TITLE', '')
attribution = os.environ.get('PYTHON_ATTRIBUTION', 'Anonymous')
json_content = os.environ.get('PYTHON_JSON_CONTENT', '')

# Format body with JSON code block
formatted_body = f"""## PawMate AI Challenge Result Submission

Submitted by: {attribution}

### Result JSON

```json
{json_content}
```

---

Generated using: https://github.com/rsdickerson/pawmate-ai-challenge
"""

payload = {
    "title": title,
    "body": formatted_body,
    "labels": ["submission", "results"]
}

print(json.dumps(payload))
PYTHON_EOF
    
    # Clean up environment variables
    unset PYTHON_TITLE
    unset PYTHON_ATTRIBUTION
    unset PYTHON_JSON_CONTENT
    
    # Prepare curl command
    local curl_cmd="curl -s -w '\n%{http_code}' -X POST"
    curl_cmd="$curl_cmd -H 'Accept: application/vnd.github.v3+json'"
    curl_cmd="$curl_cmd -H 'Content-Type: application/json'"
    
    # Add authentication header (token should always be present due to validation, but check anyway)
    if [[ -z "$token" ]]; then
        print_error "Internal error: Token is empty in create_github_issue()"
        return 1
    fi
    curl_cmd="$curl_cmd -H 'Authorization: token $token'"
    
    curl_cmd="$curl_cmd -d @$payload_file"
    curl_cmd="$curl_cmd '$GITHUB_API_URL'"
    
    # Execute curl and capture response
    local response=$(eval "$curl_cmd" 2>&1)
    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | sed '$d')
    
    # Clean up temporary file
    rm -f "$payload_file"
    
    # Check HTTP status code
    if [[ "$http_code" == "201" ]]; then
        # Success - parse issue URL and number from response
        local issue_url=$(echo "$response_body" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('html_url', ''))" 2>/dev/null)
        local issue_number=$(echo "$response_body" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('number', ''))" 2>/dev/null)
        
        if [[ -n "$issue_url" ]]; then
            echo "$issue_url|$issue_number"
            return 0
        else
            print_error "Issue created but could not parse response"
            return 1
        fi
    else
        # Error - parse and display error message
        local error_message=$(echo "$response_body" | python3 -c "import json, sys; data=json.load(sys.stdin); print(data.get('message', 'Unknown error'))" 2>/dev/null || echo "Unknown error")
        local error_details=$(echo "$response_body" | python3 -c "import json, sys; data=json.load(sys.stdin); errors=data.get('errors', []); print('; '.join([e.get('message', '') for e in errors]))" 2>/dev/null || echo "")
        
        print_error "GitHub API request failed (HTTP $http_code)"
        print_error "Error: $error_message"
        if [[ -n "$error_details" ]]; then
            print_error "Details: $error_details"
        fi
        
        # Provide specific guidance based on error
        if [[ "$http_code" == "401" ]] || [[ "$http_code" == "403" ]]; then
            echo "" >&2
            print_warning "Authentication failed. Please check your GitHub token."
            print_info "Set GITHUB_TOKEN environment variable or add GITHUB_TOKEN=your-token to .submission.config"
        elif [[ "$http_code" == "404" ]]; then
            echo "" >&2
            print_warning "Repository not found: ${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}"
            print_info "Please verify the repository exists and is accessible"
        elif [[ "$http_code" == "422" ]]; then
            echo "" >&2
            print_warning "Validation error. The issue data may be invalid."
            print_info "Check that all required fields are present in the result file"
        elif [[ "$http_code" == "000" ]] || [[ -z "$http_code" ]]; then
            echo "" >&2
            print_warning "Network error. Could not connect to GitHub API."
            print_info "Please check your internet connection and try again"
        fi
        
        return 1
    fi
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
        echo "This script will:"
        echo "  - Validate your result file"
        echo "  - Prompt for optional attribution (name/GitHub username)"
        echo "  - Create a GitHub Issue in ${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}"
        echo "  - Include the JSON result data in the issue body"
        echo ""
        echo "GitHub Token:"
        echo "  Set GITHUB_TOKEN environment variable or add GITHUB_TOKEN=your-token to .submission.config"
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
    
    # Load and validate GitHub token before attempting API calls
    local github_token=$(load_github_token)
    
    if ! validate_github_token "$github_token"; then
        print_error "GitHub authentication token is required"
        echo ""
        print_info "This script uses the GitHub API to create issues programmatically."
        print_info "A GitHub personal access token is required for authentication."
        echo ""
        print_info "How to create a GitHub personal access token:"
        echo ""
        echo "  1. Go to: https://github.com/settings/tokens"
        echo "  2. Click 'Generate new token' → 'Generate new token (classic)'"
        echo "  3. Give it a descriptive name (e.g., 'PawMate Result Submission')"
        echo "  4. Select the 'repo' scope (required for creating issues)"
        echo "  5. Click 'Generate token' and copy the token immediately"
        echo ""
        print_info "Where to set your token (choose one method):"
        echo ""
        echo "  Method 1: Environment variable (recommended for temporary use)"
        echo "    export GITHUB_TOKEN=your-token-here"
        echo ""
        echo "  Method 2: Configuration file (recommended for persistent use)"
        echo "    Add this line to: $CONFIG_FILE"
        echo "    GITHUB_TOKEN=your-token-here"
        echo ""
        print_info "Priority: Config file is checked first, then environment variable."
        echo ""
        print_info "Token permissions required:"
        echo "  - 'repo' scope (for creating issues in the repository)"
        echo ""
        print_info "Repository: https://github.com/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}"
        echo ""
        exit 1
    fi
    
    echo ""
    print_info "Creating GitHub Issue..."
    
    # Create GitHub Issue
    local issue_result
    if issue_result=$(create_github_issue "$result_file" "$attribution" "$github_token") && [[ -n "$issue_result" ]]; then
        local issue_url=$(echo "$issue_result" | cut -d'|' -f1)
        local issue_number=$(echo "$issue_result" | cut -d'|' -f2)
        
        echo ""
        print_success "GitHub Issue created successfully!"
        echo ""
        print_info "Issue #${issue_number}: ${issue_url}"
        echo ""
        print_success "Thank you for submitting your benchmark results!"
        echo ""
    else
        print_error "Failed to create GitHub Issue"
        echo ""
        exit 1
    fi
}

# Run main function
main "$@"

