# Project Archetype

A Copier template for scaffolding new projects with AI-assisted development workflows.

## Quick Start

### Step 1: Generate Your Project

```bash
copier copy gh:who/copier-project-archetype ./my-project
cd my-project
```

The generator will:
- Ask you about your project (name, language, framework, etc.)
- Scaffold the project structure
- Initialize git and beads automatically

You now have a blank slate ready for development.

### Step 2: Generate Your PRD

Define what you're building by creating a PRD (Product Requirements Document). Use the included prompt template with your seed idea:

```bash
# Open a Claude session and paste the PRD prompt with your idea
claude

# In Claude, use the PRD-PROMPT template:
# "I want to build [YOUR IDEA HERE]..."
```

Or use the helper script:

```bash
./generate-prd.sh "A CLI tool that converts markdown to PDF with custom themes"
```

This starts an interactive session where Claude will:
1. Interview you about your idea (3-5 questions at a time)
2. Generate a structured PRD document
3. Iterate up to 5 times to refine it
4. Save the result to `prd/PRD-[project-name].md`

See [prd/PRD-PROMPT.md](prd/PRD-PROMPT.md) for the full prompt template.

### Step 3: Import PRD into Beads

Convert your PRD into executable work items:

```bash
# In a Claude session, run the Phase 4 beads conversion prompt
claude

# Reference your PRD and ask Claude to generate beads
# This creates prd/beads-setup-[project-name].sh
```

Then run the generated script:

```bash
chmod +x prd/beads-setup-*.sh
./prd/beads-setup-*.sh
```

Verify your work queue:

```bash
bd list                    # See all issues
bd ready                   # See what's ready to work on
bd dep tree <epic-id>      # Visualize dependencies
```

### Step 4: Run Ralph

Execute work through the Ralph automation loop:

```bash
# Single task execution
./ralph.sh

# Continuous execution until queue is empty
./mega-ralph.sh
```

Ralph will:
1. Find the next ready task (`bd ready`)
2. Claim and implement it
3. Run verification (tests, linting)
4. Commit and push changes
5. Mark the task complete

## What You Get

```
my-project/
├── .beads/                 # Issue tracking database
├── .claude/                # Claude Code permissions
├── .github/workflows/      # CI pipeline
├── prd/
│   └── PRD-PROMPT.md       # PRD generation template
├── src/                    # Your code goes here
├── CLAUDE.md               # AI guidance
├── PROMPT.md               # Ralph loop instructions
├── activity.md             # Work log
├── generate-prd.sh         # PRD generation helper
├── ralph.sh                # Single task runner
└── mega-ralph.sh           # Continuous task runner
```

## Work Execution Policy

> **All implementation work MUST go through Ralph loops.**

- Direct coding is not allowed in interactive Claude sessions
- Create beads issues instead of implementing directly
- Ralph loops execute the actual work
- Research and planning are allowed without Ralph

## Requirements

Install these tools before using generated projects:

| Tool | Purpose | Install |
|------|---------|---------|
| **copier** | Project generator | `uv tool install copier` |
| **beads** | Issue tracking | `cargo install beads` |
| **bv** | Beads TUI viewer | `cargo install beads_viewer` |
| **claude** | Claude CLI | `npm install -g @anthropic-ai/claude-cli` |
| **jq** | JSON processing | `apt install jq` / `brew install jq` |

### Language-Specific Tools

**Python:** `uv`, `ruff`
**TypeScript:** Node.js 20+, npm/pnpm/yarn/bun
**Go:** Go 1.22+, golangci-lint
**Rust:** rustup, clippy, rustfmt

## License

MIT
