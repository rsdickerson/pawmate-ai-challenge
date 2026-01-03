#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import init from '../src/commands/init.js';
import submit from '../src/commands/submit.js';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Read package.json for version
const packageJson = JSON.parse(
  readFileSync(path.join(__dirname, '..', 'package.json'), 'utf8')
);

const program = new Command();

program
  .name('pawmate')
  .description('PawMate AI Benchmark CLI - Initialize and submit benchmark runs')
  .version(packageJson.version);

program
  .command('init')
  .description('Initialize a new PawMate benchmark run')
  .requiredOption('--profile <name>', 'Profile to use (model-a-rest, model-a-graphql, model-b-rest, model-b-graphql)')
  .requiredOption('--tool <name>', 'Tool under test (name)')
  .option('--tool-ver <version>', 'Tool version/build id')
  .option('--spec-ver <version>', 'Frozen spec version (defaults to SPEC_VERSION file)')
  .option('--run-dir <path>', 'Override auto-generated run folder path')
  .option('--hidden', 'Create hidden directory (starts with dot)')
  .action(async (options) => {
    try {
      await init(options);
    } catch (error) {
      console.error(chalk.red('Error:'), error.message);
      process.exit(1);
    }
  });

program
  .command('submit')
  .description('Submit benchmark results')
  .argument('<result-file>', 'Path to result JSON file')
  .option('--github-token <token>', 'GitHub personal access token for issue creation')
  .option('--email-only', 'Skip GitHub issue creation (email only)')
  .action(async (resultFile, options) => {
    try {
      await submit(resultFile, options);
    } catch (error) {
      console.error(chalk.red('Error:'), error.message);
      process.exit(1);
    }
  });

// Show help if no command provided
if (process.argv.length === 2) {
  program.help();
}

program.parse();

