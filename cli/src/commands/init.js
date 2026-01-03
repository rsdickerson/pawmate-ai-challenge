import fs from 'fs-extra';
import path from 'path';
import chalk from 'chalk';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Initialize a new PawMate benchmark run
 * @param {Object} options - Command options
 * @param {string} options.profile - Profile name (e.g., model-a-rest)
 * @param {string} options.tool - Tool name
 * @param {string} [options.toolVer] - Tool version
 * @param {string} [options.specVer] - Spec version
 * @param {string} [options.runDir] - Run directory path
 */
export default async function init(options) {
  const { profile, tool, toolVer = '', specVer = '', runDir = '' } = options;
  
  // Validate profile
  const validProfiles = ['model-a-rest', 'model-a-graphql', 'model-b-rest', 'model-b-graphql'];
  if (!validProfiles.includes(profile)) {
    throw new Error(`Invalid profile: ${profile}. Valid profiles: ${validProfiles.join(', ')}`);
  }
  
  // Load profile configuration
  const profilePath = path.join(__dirname, '..', 'profiles', `${profile}.profile`);
  if (!await fs.pathExists(profilePath)) {
    throw new Error(`Profile file not found: ${profile}.profile`);
  }
  
  const profileContent = await fs.readFile(profilePath, 'utf8');
  const profileConfig = parseProfile(profileContent);
  
  // Read spec version
  let finalSpecVer = specVer;
  if (!finalSpecVer) {
    const specVersionPath = path.join(__dirname, '..', 'SPEC_VERSION');
    if (await fs.pathExists(specVersionPath)) {
      finalSpecVer = (await fs.readFile(specVersionPath, 'utf8')).trim();
    } else {
      finalSpecVer = '1.0.0'; // fallback
    }
  }
  
  // Generate run folder path
  const timestamp = new Date().toISOString().replace(/[-:]/g, '').replace(/\.\d{3}Z$/, '').replace('T', 'T').slice(0, 15);
  const cwd = process.cwd();
  
  // Default: visible directory. --hidden flag creates hidden directory
  const dirPrefix = options.hidden ? '.pawmate-run' : 'pawmate-run';
  const finalRunDir = runDir || path.join(cwd, `${dirPrefix}-${timestamp}`);
  
  // Create run folder structure
  await fs.ensureDir(path.join(finalRunDir, 'PawMate'));
  await fs.ensureDir(path.join(finalRunDir, 'benchmark'));
  
  const workspacePath = path.join(finalRunDir, 'PawMate');
  
  // Generate run ID
  const toolSlug = tool.replace(/\s+/g, '-');
  const runId = `${toolSlug}-Model${profileConfig.model}-${timestamp}`;
  
  // Determine run number (default to 1)
  const runNumber = 1;
  
  // Build tool display string
  const toolDisplay = toolVer ? `${tool} ${toolVer}` : tool;
  
  // Render API start prompt
  const apiTemplatePath = path.join(__dirname, '..', 'templates', 'api_start_prompt_template.md');
  if (!await fs.pathExists(apiTemplatePath)) {
    throw new Error('API start prompt template not found');
  }
  
  let apiRendered = await fs.readFile(apiTemplatePath, 'utf8');
  
  // Fill header fields
  apiRendered = apiRendered.replace('[Tool name + version/build id]', toolDisplay);
  apiRendered = apiRendered.replace('[e.g., ToolX-ModelA-Run1]', runId);
  apiRendered = apiRendered.replace('[commit/tag/hash or immutable archive id]', finalSpecVer);
  apiRendered = apiRendered.replace(/\[repo-root-path\]/g, '(bundled with CLI)');
  apiRendered = apiRendered.replace(/\[workspace-path\]/g, workspacePath);
  
  // Replace {Spec Root} placeholders - point to bundled templates
  const bundledDocsNote = '(docs bundled with CLI - see GitHub repo for reference)';
  apiRendered = apiRendered.replace(/\{Spec Root\}/g, bundledDocsNote);
  
  // Replace {Workspace Path} placeholders
  apiRendered = apiRendered.replace(/\{Workspace Path\}/g, workspacePath);
  
  // Check model checkbox
  if (profileConfig.model === 'A') {
    apiRendered = apiRendered.replace(
      '  - [ ] **Model A (Minimum)**',
      '  - [x] **Model A (Minimum)**'
    );
  } else if (profileConfig.model === 'B') {
    apiRendered = apiRendered.replace(
      '  - [ ] **Model B (Full)**',
      '  - [x] **Model B (Full)**'
    );
  }
  
  // Check API style checkbox
  if (profileConfig.api_type === 'REST') {
    apiRendered = apiRendered.replace(
      '  - [ ] **REST** (produce an OpenAPI contract artifact)',
      '  - [x] **REST** (produce an OpenAPI contract artifact)'
    );
  } else if (profileConfig.api_type === 'GraphQL') {
    apiRendered = apiRendered.replace(
      '  - [ ] **GraphQL** (produce a GraphQL schema contract artifact)',
      '  - [x] **GraphQL** (produce a GraphQL schema contract artifact)'
    );
  }
  
  // Save API start prompt
  const apiPromptFile = path.join(finalRunDir, 'start_build_api_prompt.txt');
  await fs.writeFile(apiPromptFile, apiRendered, 'utf8');
  
  // Render UI start prompt
  const uiTemplatePath = path.join(__dirname, '..', 'templates', 'ui_start_prompt_template.md');
  let uiPromptFile = '';
  
  if (await fs.pathExists(uiTemplatePath)) {
    let uiRendered = await fs.readFile(uiTemplatePath, 'utf8');
    
    // Fill header fields
    uiRendered = uiRendered.replace('[Tool name + version/build id]', toolDisplay);
    uiRendered = uiRendered.replace('[e.g., ToolX-ModelA-Run1-UI]', `${runId}-UI`);
    uiRendered = uiRendered.replace('[commit/tag/hash or immutable archive id]', finalSpecVer);
    uiRendered = uiRendered.replace(/\[repo-root-path\]/g, bundledDocsNote);
    uiRendered = uiRendered.replace(/\[workspace-path\]/g, workspacePath);
    
    // Replace {Spec Root} placeholders
    uiRendered = uiRendered.replace(/\{Spec Root\}/g, bundledDocsNote);
    
    // Replace {Workspace Path} placeholders
    uiRendered = uiRendered.replace(/\{Workspace Path\}/g, workspacePath);
    
    // Check model checkbox
    if (profileConfig.model === 'A') {
      uiRendered = uiRendered.replace(
        '  - [ ] **Model A (Minimum)**',
        '  - [x] **Model A (Minimum)**'
      );
    } else if (profileConfig.model === 'B') {
      uiRendered = uiRendered.replace(
        '  - [ ] **Model B (Full)**',
        '  - [x] **Model B (Full)**'
      );
    }
    
    // Check API style checkbox
    if (profileConfig.api_type === 'REST') {
      uiRendered = uiRendered.replace(
        '  - [ ] **REST**',
        '  - [x] **REST**'
      );
    } else if (profileConfig.api_type === 'GraphQL') {
      uiRendered = uiRendered.replace(
        '  - [ ] **GraphQL**',
        '  - [x] **GraphQL**'
      );
    }
    
    // Save UI start prompt
    uiPromptFile = path.join(finalRunDir, 'start_build_ui_prompt.txt');
    await fs.writeFile(uiPromptFile, uiRendered, 'utf8');
  }
  
  // Write run.config
  const runConfig = `# run.config — Benchmark Run Configuration
# Generated: ${new Date().toISOString()}

spec_version=${finalSpecVer}
spec_root=(bundled with CLI)
tool=${tool}
tool_ver=${toolVer}
model=${profileConfig.model}
api_type=${profileConfig.api_type}
workspace=${workspacePath}
`;
  
  await fs.writeFile(path.join(finalRunDir, 'run.config'), runConfig, 'utf8');
  
  // Generate result submission instructions
  const toolSlugForFilename = tool.toLowerCase().replace(/[^a-z0-9-]/g, '-').replace(/--+/g, '-').replace(/^-|-$/g, '');
  const resultFilename = `${toolSlugForFilename}_model${profileConfig.model}_${profileConfig.api_type}_run${runNumber}_${timestamp}.json`;
  
  const submissionInstructions = generateSubmissionInstructions(
    finalRunDir,
    workspacePath,
    tool,
    toolVer,
    profileConfig.model,
    profileConfig.api_type,
    finalSpecVer,
    resultFilename
  );
  
  await fs.writeFile(
    path.join(finalRunDir, 'benchmark', 'result_submission_instructions.md'),
    submissionInstructions,
    'utf8'
  );
  
  // Output summary
  console.log('');
  console.log(chalk.cyan('━'.repeat(60)));
  console.log(chalk.green('✓ Run initialized!'));
  console.log(chalk.cyan('━'.repeat(60)));
  console.log('');
  console.log(`  Run folder:  ${chalk.bold(finalRunDir)}`);
  console.log(`  Workspace:   ${chalk.bold(workspacePath)}`);
  console.log('');
  console.log('  Generated prompts:');
  console.log(`    API: ${chalk.yellow(apiPromptFile)}`);
  if (uiPromptFile) {
    console.log(`    UI:  ${chalk.yellow(uiPromptFile)}`);
  }
  console.log('');
  console.log(chalk.cyan('━'.repeat(60)));
  console.log(chalk.bold('NEXT STEPS:'));
  console.log('');
  console.log('  1. Open a new AI agent/chat session');
  console.log('  2. Copy the contents of the API start prompt:');
  console.log(chalk.yellow(`     ${apiPromptFile}`));
  console.log('  3. Paste it as the first message to build the API/backend');
  console.log('');
  if (uiPromptFile) {
    console.log('  4. After API is complete, start a new session (or continue)');
    console.log('  5. Copy the contents of the UI start prompt:');
    console.log(chalk.yellow(`     ${uiPromptFile}`));
    console.log('  6. Paste it to build the UI (assumes API already exists)');
    console.log('');
  }
  console.log(chalk.cyan('━'.repeat(60)));
  console.log('');
}

/**
 * Parse profile file content
 * @param {string} content - Profile file content
 * @returns {Object} Parsed profile config
 */
function parseProfile(content) {
  const config = {};
  const lines = content.split('\n');
  
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#')) {
      const [key, value] = trimmed.split('=').map(s => s.trim());
      if (key && value) {
        config[key] = value;
      }
    }
  }
  
  return config;
}

/**
 * Generate result submission instructions
 */
function generateSubmissionInstructions(runDir, workspacePath, tool, toolVer, model, apiType, specVer, resultFilename) {
  return `# Result Submission Instructions

## Overview
After completing your benchmark run (API and optionally UI), you need to submit your results using the PawMate CLI.

## Submission via Email (Default)

### Step 1: Complete the Run
Ensure the AI agent has:
- Generated all code files
- Built the application successfully
- Loaded seed data
- Started the application
- Run all tests (ideally all passing)
- Generated benchmark artifacts (AI run report, acceptance checklist, etc.)

### Step 2: Generate Result File (if needed)
If the AI agent didn't generate a result file automatically, you can create one manually following the result file specification in the PawMate AI Challenge documentation.

Expected filename: \`${resultFilename}\`

Place it in: \`${runDir}/benchmark/\`

### Step 3: Submit via PawMate CLI

\`\`\`bash
pawmate submit ${runDir}/benchmark/${resultFilename}
\`\`\`

This will:
- Validate your result file
- Prompt for optional attribution (name/GitHub username)
- Open your email client with pre-filled content
- Include JSON result data in email body (no attachment needed)

**IMPORTANT**: The CLI opens your email client but does NOT send the email automatically. You must:
1. Review the pre-filled email in your email client
2. Click "Send" to submit the result

**Email will be sent to**: \`pawmate.ai.challenge@gmail.com\`

## Alternative: GitHub Issue Submission (Optional)

If you have a GitHub personal access token:

\`\`\`bash
export GITHUB_TOKEN=your-token-here
pawmate submit ${runDir}/benchmark/${resultFilename}
\`\`\`

This will create a GitHub issue in addition to opening the email client.

**How to create a GitHub token:**
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a name (e.g., "PawMate Result Submission")
4. Select the "repo" scope
5. Click "Generate token" and copy it

## Run Information

- **Run Directory**: \`${runDir}\`
- **Workspace**: \`${workspacePath}\`
- **Tool**: ${tool}${toolVer ? ' ' + toolVer : ''}
- **Model**: ${model}
- **API Style**: ${apiType}
- **Spec Version**: ${specVer}

## Resources

- **PawMate CLI Documentation**: https://github.com/rsdickerson/pawmate-ai-challenge/tree/main/cli
- **Challenge Documentation**: https://github.com/rsdickerson/pawmate-ai-challenge
- **Result File Specification**: See challenge documentation

## Key Metrics to Include

Your result file should contain:
- **Timing Metrics**: All timestamps in ISO-8601 UTC format
  - \`generation_started\`
  - \`code_complete\`
  - \`build_clean\`
  - \`seed_loaded\`
  - \`app_started\`
  - \`all_tests_pass\`
- **Build Status**: Boolean flags for success/failure
- **LLM Usage**: Model used, tokens consumed, request count
- **Intervention Metrics**: Clarifications, interventions, reruns

See the AI run report generated in \`${runDir}/benchmark/ai_run_report.md\` for these metrics.
`;
}

