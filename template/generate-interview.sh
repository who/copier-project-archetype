#!/bin/bash
# generate-interview.sh - Generate interview subtasks from an idea bead
#
# Usage: ./generate-interview.sh <idea-id>
#
# This script reads an idea bead and uses Claude to generate discovery
# question subtasks. Each question becomes a task assigned to 'human'
# that blocks the original idea until answered.
#
# Exit codes:
#   0 - Success, interview subtasks created
#   1 - Error occurred
#   2 - Idea not found or invalid

set -e

IDEA_ID="$1"

if [ -z "$IDEA_ID" ]; then
    echo "Usage: ./generate-interview.sh <idea-id>"
    echo ""
    echo "Example:"
    echo "  ./generate-interview.sh myproject-abc123"
    exit 1
fi

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "Error: claude CLI not found. Install with: npm install -g @anthropic-ai/claude-cli"
    exit 1
fi

# Check if PRD-INTERVIEW-PROMPT.md exists
if [ ! -f "prd/PRD-INTERVIEW-PROMPT.md" ]; then
    echo "Error: prd/PRD-INTERVIEW-PROMPT.md not found. Are you in the project root?"
    exit 1
fi

# Get idea details
echo "Reading idea: $IDEA_ID"
idea_json=$(bd show "$IDEA_ID" --json 2>/dev/null) || {
    echo "Error: Could not read idea '$IDEA_ID'. Does it exist?"
    exit 2
}

# Extract fields from JSON
idea_title=$(echo "$idea_json" | jq -r '.title // "Untitled"')
idea_description=$(echo "$idea_json" | jq -r '.description // "No description provided"')

if [ "$idea_title" = "Untitled" ] && [ "$idea_description" = "No description provided" ]; then
    echo "Error: Idea has no title or description"
    exit 2
fi

echo "Title: $idea_title"
echo ""
echo "Generating discovery questions..."
echo ""

# Build the prompt with substituted values
prompt="Read the idea bead details below and generate discovery questions.

## Idea Details
**ID**: $IDEA_ID
**Title**: $idea_title
**Description**:
$idea_description

---

## Your Role

You are a senior product manager preparing to write a PRD. Before writing, you need to gather more information through discovery questions.

## Process

### Step 1: Analyze the Idea

Review the idea description and identify:
1. **Gaps** - What information is missing?
2. **Ambiguities** - What needs clarification?
3. **Assumptions** - What assumptions need validation?
4. **Risks** - What risks need to be understood?

### Step 2: Generate Discovery Questions

Create 3-7 focused questions that will help write a complete PRD. Questions should cover:

1. **Problem Space** - What problem are we solving? Who has this problem? How painful is it?
2. **Users** - Who are the target users? What are their goals and constraints?
3. **Scope** - What's in scope for v1? What's explicitly out of scope?
4. **Success Criteria** - How will we know this succeeded? What metrics matter?
5. **Constraints** - Technical limitations, timeline, budget, team size?
6. **Existing Solutions** - What exists today? Why is it insufficient?

Not all categories need questions - focus on what's genuinely unclear.

### Step 3: Create Subtasks

For each question, run this command:

\`\`\`bash
bd create --title=\"Q: [Short version of question]\" \\
  --type=task \\
  --priority=3 \\
  --assignee=human \\
  --description=\"## Question

[Full question text]

## Context

This question relates to the idea: $idea_title

## How to Answer

1. Edit this description to add your answer below
2. Or add a comment with your answer
3. Close this task when answered

## Your Answer

[Write your answer here]\"
\`\`\`

After creating each subtask, add a blocking dependency:
\`\`\`bash
bd dep add $IDEA_ID <subtask-id>
\`\`\`

This ensures the idea cannot proceed until all questions are answered.

### Step 4: Summary

After creating all subtasks, output:
1. List of questions created
2. The dependency setup
3. Instructions for the human to answer questions

---

## Output Format

When done, output exactly this (with real values):
\`\`\`
<interview-complete>
Questions created: [count]
Subtask IDs: [comma-separated list of IDs]
</interview-complete>
\`\`\`"

# Run Claude with the prompt
echo "$prompt" | claude --dangerously-skip-permissions --output-format stream-json --verbose

echo ""
echo "Interview generation complete. Human can now answer questions and close subtasks."
echo "Once all interview subtasks are closed, the idea will be unblocked for PRD generation."
