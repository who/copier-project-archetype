#!/bin/bash
# Generate a PRD from a seed idea using Claude
#
# Usage: ./generate-prd.sh "Your project idea here"
#
# This script opens an interactive Claude session with the PRD-PROMPT template
# pre-loaded with your seed idea. Claude will interview you, then generate
# a structured PRD document.

set -e

if [ -z "$1" ]; then
    echo "Usage: ./generate-prd.sh \"Your project idea\""
    echo ""
    echo "Example:"
    echo "  ./generate-prd.sh \"A CLI tool that converts markdown to PDF with custom themes\""
    exit 1
fi

SEED_IDEA="$1"

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "Error: claude CLI not found. Install with: npm install -g @anthropic-ai/claude-cli"
    exit 1
fi

# Check if PRD-PROMPT.md exists
if [ ! -f "prd/PRD-PROMPT.md" ]; then
    echo "Error: prd/PRD-PROMPT.md not found. Are you in the project root?"
    exit 1
fi

echo "Starting PRD generation for: $SEED_IDEA"
echo ""
echo "Claude will interview you about your idea, then generate a PRD."
echo "The final document will be saved to prd/PRD-[project-name].md"
echo ""

# Start Claude with the PRD prompt and seed idea
# Use --resume to start interactive session, piping in the initial prompt
echo "I want to create a Product Requirements Document (PRD) for the following topic:

**Topic**: $SEED_IDEA

Please follow the PRD generation process outlined in @prd/PRD-PROMPT.md - start with the discovery interview (Phase 1), asking me 3-5 questions at a time. Use the AskUserQuestion tool to ask your interview questions." | claude
