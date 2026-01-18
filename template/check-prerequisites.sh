#!/bin/bash
# check-prerequisites.sh - Verify required tools are installed
#
# This script checks for tools needed by the project automation.
# It warns about missing tools but does not fail - you can install them later.

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Checking prerequisites..."
echo ""

missing_count=0

check_tool() {
    local tool="$1"
    local description="$2"
    local install_hint="$3"

    if command -v "$tool" &> /dev/null; then
        printf "${GREEN}✓${NC} %-10s %s\n" "$tool" "$description"
    else
        printf "${RED}✗${NC} %-10s %s\n" "$tool" "$description"
        printf "  ${YELLOW}Install:${NC} %s\n" "$install_hint"
        missing_count=$((missing_count + 1))
    fi
}

# Core tools
check_tool "git" "Version control" "https://git-scm.com/downloads"
check_tool "jq" "JSON processing" "brew install jq / apt install jq"

# Beads ecosystem
check_tool "bd" "Beads issue tracking" "curl -sSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash"

# Claude Code
check_tool "claude" "Claude CLI for automation" "npm install -g @anthropic-ai/claude-code"

# Search tools (used by Claude Code)
check_tool "rg" "Fast search (ripgrep)" "brew install ripgrep / apt install ripgrep"
check_tool "fd" "Fast file finder" "brew install fd / apt install fd-find"

echo ""

if [ "$missing_count" -eq 0 ]; then
    echo -e "${GREEN}All prerequisites installed!${NC}"
else
    echo -e "${YELLOW}Missing $missing_count tool(s).${NC}"
    echo "The project will work, but some automation features may not function until these are installed."
fi
