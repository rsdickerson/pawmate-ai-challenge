# PawMate AI Challenge CLI

> **Benchmark AI coding assistants without cloning repos**

A command-line tool for initializing and submitting PawMate AI benchmark runs. Install globally and run benchmarks from any directory.

## Quick Start

```bash
# Install globally
npm install -g pawmate-ai-challenge

# Create a project directory
mkdir my-pawmate-benchmark
cd my-pawmate-benchmark

# Initialize a benchmark run
pawmate init --profile model-a-rest --tool "Cursor" --tool-ver "v0.43"

# Copy the generated prompts to your AI agent
cat pawmate-run-*/start_build_api_prompt.txt
cat pawmate-run-*/start_build_ui_prompt.txt

# After completing the benchmark, submit results
pawmate submit pawmate-run-*/benchmark/result.json
```

## Installation

### Global Installation (Recommended)

```bash
npm install -g pawmate-ai-challenge
```

This makes the `pawmate` command available system-wide.

### Local Installation (npx)

If you don't want to install globally, you can use `npx`:

```bash
npx pawmate-ai-challenge init --profile model-a-rest --tool "YourTool"
```

## Commands

### `pawmate init`

Initialize a new benchmark run with pre-filled prompt templates.

**Usage:**

```bash
pawmate init --profile <profile> --tool <tool-name> [options]
```

**Required Options:**

- `--profile <name>` - Benchmark profile (see profiles below)
- `--tool <name>` - Tool under test (e.g., "Cursor", "GitHub Copilot")

**Optional:**

- `--tool-ver <version>` - Tool version or build ID
- `--spec-ver <version>` - Frozen spec version (defaults to bundled version)
- `--run-dir <path>` - Custom run directory path
- `--hidden` - Create hidden directory (starts with dot, for power users)

**Profiles:**

- `model-a-rest` - Model A (Minimum) + REST API
- `model-a-graphql` - Model A (Minimum) + GraphQL API
- `model-b-rest` - Model B (Full) + REST API
- `model-b-graphql` - Model B (Full) + GraphQL API

**Example:**

```bash
pawmate init --profile model-a-rest --tool "Cursor" --tool-ver "v0.43.1"
```

**What it creates:**

- `pawmate-run-<timestamp>/` - Run directory (visible by default)
  - `start_build_api_prompt.txt` - API/backend prompt
  - `start_build_ui_prompt.txt` - UI/frontend prompt
  - `run.config` - Run configuration
  - `PawMate/` - Workspace for generated code
  - `benchmark/` - Benchmark artifacts folder

**Note:** Use `--hidden` flag to create `.pawmate-run-<timestamp>/` (hidden directory) instead.

**Directory Naming Philosophy:**
- **Default (visible):** Most users prefer seeing their run folders - no surprises, easy to find
- **Hidden option:** Power users who want minimal clutter can opt-in with `--hidden`
- **Benefit:** Fewer "where did my files go?" support questions

### `pawmate submit`

Submit benchmark results via email (and optionally GitHub issue).

**Usage:**

```bash
pawmate submit <result-file.json> [options]
```

**Arguments:**

- `<result-file>` - Path to result JSON file

**Options:**

- `--github-token <token>` - GitHub personal access token for issue creation
- `--email-only` - Skip GitHub submission (email only)

**Examples:**

```bash
# Email submission only (default)
pawmate submit .pawmate-run-*/benchmark/result.json

# Email + GitHub issue (requires token)
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx
pawmate submit .pawmate-run-*/benchmark/result.json

# Or provide token as flag
pawmate submit result.json --github-token ghp_xxxxxxxxxxxx
```

**What it does:**

1. Validates result file format and required fields
2. Prompts for optional attribution (name/GitHub username)
3. **Email submission:**
   - Opens your email client with pre-filled content
   - To: `pawmate.ai.challenge@gmail.com`
   - Includes JSON result in email body
   - **You must click "Send" to complete submission**
4. **GitHub submission (optional):**
   - Creates issue in `rsdickerson/pawmate-ai-results`
   - Requires GitHub personal access token
   - Labels: `submission`, `results`

### GitHub Token Setup

To enable GitHub issue creation:

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a name (e.g., "PawMate Result Submission")
4. Select the **"repo"** scope (required for creating issues)
5. Click "Generate token" and copy it

**Set the token:**

```bash
# Method 1: Environment variable
export GITHUB_TOKEN=your-token-here

# Method 2: Command flag
pawmate submit result.json --github-token your-token-here
```

## Workflow

### 1. Initialize a Run

```bash
mkdir pawmate-benchmark && cd pawmate-benchmark
pawmate init --profile model-a-rest --tool "Cursor" --tool-ver "v0.43"
# Creates pawmate-run-<timestamp>/ (visible directory)

# Power users can use --hidden for a cleaner directory listing:
# pawmate init --profile model-a-rest --tool "Cursor" --hidden
# Creates .pawmate-run-<timestamp>/ (hidden directory)
```

### 2. Copy Prompts to AI Agent

Open the generated prompt files and copy their contents:

- **API Prompt:** `pawmate-run-<timestamp>/start_build_api_prompt.txt`
- **UI Prompt:** `pawmate-run-<timestamp>/start_build_ui_prompt.txt`

Paste each prompt as the first message in a new AI agent session.

### 3. Complete the Benchmark

The AI agent will:
- Generate all code files
- Build and start the application
- Load seed data
- Run automated tests
- Generate benchmark artifacts

### 4. Submit Results

```bash
pawmate submit pawmate-run-*/benchmark/result.json
```

Review and send the pre-filled email. Results will be published at:
https://github.com/rsdickerson/pawmate-ai-results

## Key Features

- ✅ **No repo cloning required** - Install via npm, run anywhere
- ✅ **Pre-filled prompts** - Automatic template rendering
- ✅ **Dual submission** - Email (required) + GitHub issue (optional)
- ✅ **Cross-platform** - Works on macOS, Windows, Linux
- ✅ **Validation** - Automatic result file validation
- ✅ **Bundled specs** - Templates and profiles included in package

## Comparison to Clone-Based Workflow

| Aspect | Clone Repo | npm CLI |
|--------|------------|---------|
| Setup | `git clone` + repo navigation | `npm install -g` |
| Initialize | `./scripts/initialize_run.sh` | `pawmate init` |
| Prompts | Absolute paths to repo | Bundled, portable |
| Submit | Manual email/GitHub | Automatic email + optional GitHub |
| Updates | `git pull` | `npm update -g pawmate-ai-challenge` |

## Troubleshooting

### "Cannot find package" errors

Make sure dependencies are installed:

```bash
cd /path/to/pawmate-ai-challenge/cli
npm install
```

### Email client doesn't open

If the email client fails to open, the CLI will print the email content to the console. Copy and paste it manually into your email client.

### GitHub issue creation fails

Common causes:
- **401/403 errors:** Invalid or missing GitHub token
- **404 errors:** Repository not accessible
- **422 errors:** Invalid result data format

Solution: Check your token has the `repo` scope and is valid.

## Requirements

- **Node.js:** >= 18.0.0
- **npm:** Comes with Node.js
- **Email client:** For email submissions (or manual email)
- **GitHub token:** Optional, only for GitHub issue creation

## Resources

- **Challenge Repository:** https://github.com/rsdickerson/pawmate-ai-challenge
- **Results Repository:** https://github.com/rsdickerson/pawmate-ai-results
- **Challenge Documentation:** See `docs/` in challenge repository
- **npm Package:** https://www.npmjs.com/package/pawmate-ai-challenge

## Support

For issues, questions, or contributions:

- **Issues:** https://github.com/rsdickerson/pawmate-ai-challenge/issues
- **Discussions:** https://github.com/rsdickerson/pawmate-ai-challenge/discussions

## License

MIT - See LICENSE file in challenge repository

---

**Happy Benchmarking! 🐾**

