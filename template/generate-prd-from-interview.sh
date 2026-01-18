#!/bin/bash
# generate-prd-from-interview.sh - Generate PRD and implementation tasks from interview answers
#
# Usage: ./generate-prd-from-interview.sh <idea-id>
#
# This script:
# 1. Reads the collected interview answers for an idea
# 2. Generates a comprehensive PRD document
# 3. Explodes the PRD into implementation tasks assigned to ralph
# 4. Closes the original idea
#
# Prerequisites:
# - Interview answers collected via collect-interview.sh (prd/.interview-answers-<id>.md exists)
#
# Exit codes:
#   0 - Success, PRD generated and tasks created
#   1 - Error occurred
#   2 - Interview answers not found (run collect-interview.sh first)

set -e

IDEA_ID="$1"

if [ -z "$IDEA_ID" ]; then
    echo "Usage: ./generate-prd-from-interview.sh <idea-id>"
    echo ""
    echo "Example:"
    echo "  ./generate-prd-from-interview.sh myproject-abc123"
    exit 1
fi

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "Error: claude CLI not found. Install with: npm install -g @anthropic-ai/claude-cli"
    exit 1
fi

# Check for interview answers file
interview_file="prd/.interview-answers-$(echo "$IDEA_ID" | tr '[:upper:]' '[:lower:]').md"
if [ ! -f "$interview_file" ]; then
    echo "Error: Interview answers not found at $interview_file"
    echo "Run ./collect-interview.sh $IDEA_ID first to collect answers."
    exit 2
fi

# Get idea details
idea_json=$(bd show "$IDEA_ID" --json 2>/dev/null) || {
    echo "Error: Could not read idea '$IDEA_ID'. Does it exist?"
    exit 1
}

idea_title=$(echo "$idea_json" | jq -r '.[0].title // "Untitled"')
idea_description=$(echo "$idea_json" | jq -r '.[0].description // "No description"')

# Create slugified name for PRD file
prd_slug=$(echo "$idea_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
prd_file="prd/PRD-${prd_slug}.md"

echo "Generating PRD for: $idea_title"
echo "Output: $prd_file"
echo ""

# Read interview content
interview_content=$(cat "$interview_file")

# Build the prompt
prompt="Generate a comprehensive PRD document and implementation tasks.

## Source Material

### Original Idea
**ID**: $IDEA_ID
**Title**: $idea_title
**Description**:
$idea_description

### Collected Interview
$interview_content

---

## Your Role

You are a senior product manager and technical architect. Generate a complete PRD and break it down into implementable tasks.

## Process

### Step 1: Generate PRD Document

Create a PRD with this structure and save it to \`$prd_file\`:

\`\`\`markdown
# PRD: $idea_title

## Metadata
- **Source Idea**: $IDEA_ID
- **Generated**: $(date '+%Y-%m-%d')
- **Status**: Draft

## Overview
- **Problem Statement**: One paragraph describing the problem
- **Proposed Solution**: One paragraph describing the solution
- **Success Metrics**: Bulleted list of measurable outcomes

## Background & Context
- Why now? What's the motivation?
- Prior art and alternatives considered

## Users & Personas
- Primary user persona(s)
- User goals and jobs-to-be-done

## Requirements

### Functional Requirements
Numbered list of what the system must do. Each requirement should be:
- Atomic (one thing per requirement)
- Testable (can verify it works)
- Prioritized (P0 = must have, P1 = should have, P2 = nice to have)

Format: \`[P0] FR-001: The system shall...\`

### Non-Functional Requirements
Performance, security, scalability, accessibility, etc.

Format: \`[P1] NFR-001: The system shall...\`

## System Architecture
- High-level components and their responsibilities
- Key technical decisions and rationale
- Data flow overview

## Milestones & Phases
Break the work into logical phases, each with:
- **Milestone Name**
- **Goal**: What this milestone achieves
- **Key Deliverables**: Concrete outputs
- **Dependencies**: What must come before

## Epic Breakdown
For each milestone, list epics with tasks.

## Open Questions
Unresolved decisions that need stakeholder input.

## Out of Scope
Explicitly list what this PRD does NOT cover.
\`\`\`

### Step 2: Create Implementation Tasks

After saving the PRD, create beads for implementation:

1. **Create Epics** for each major phase/milestone:
\`\`\`bash
bd create --title=\"Epic: [Phase Name]\" --type=epic --priority=1 --assignee=ralph --description=\"[Description referencing PRD]\"
\`\`\`

2. **Create Tasks** for each implementable work item:
\`\`\`bash
bd create --title=\"[Task Name]\" --type=task --priority=2 --assignee=ralph --description=\"[Detailed description with acceptance criteria]

Reference: $prd_file\"
\`\`\`

3. **Set up dependencies** between tasks:
\`\`\`bash
bd dep add <child-task> <parent-epic>
bd dep add <later-task> <earlier-task>  # For sequential work
\`\`\`

### Step 3: Close the Idea

After creating all tasks:
\`\`\`bash
bd close $IDEA_ID --reason=\"PRD generated: $prd_file. Created [X] epics and [Y] tasks for implementation.\"
\`\`\`

---

## Output Format

When done, output:
\`\`\`
<prd-complete>
PRD saved to: $prd_file
Epics created: [count]
Tasks created: [count]
Idea closed: $IDEA_ID
</prd-complete>
\`\`\`"

# Run Claude with the prompt
echo "$prompt" | claude --dangerously-skip-permissions --output-format stream-json --verbose

echo ""
echo "PRD generation complete."
echo "Check $prd_file for the PRD document."
echo "Run 'bd list --assignee ralph' to see created tasks."
