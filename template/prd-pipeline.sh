#!/bin/bash
# prd-pipeline.sh - Automated PRD generation pipeline
#
# This script orchestrates the async PRD workflow:
# 1. Picks up ideas assigned to 'prd-pipeline'
# 2. Generates interview subtasks for discovery
# 3. Waits for human to answer questions
# 4. Generates PRD and implementation tasks when interview complete
#
# Usage: ./prd-pipeline.sh [poll_interval]
#   poll_interval: Seconds between checks (default: 60)
#
# The pipeline uses labels to track state:
#   prd:interview-pending   - Interview subtasks created, waiting for answers
#   prd:interview-complete  - All interview answered, ready for PRD generation
#   prd:generating          - PRD generation in progress
#
# Logs are written to logs/prd-pipeline-<timestamp>.log

set -e

POLL_INTERVAL=${1:-60}

# Setup logging
mkdir -p logs
LOG_FILE="logs/prd-pipeline-$(date '+%Y%m%d-%H%M%S').log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=== PRD Pipeline Started ==="
log "Poll interval: ${POLL_INTERVAL}s"
log "Log file: $LOG_FILE"
log ""

# Process a single idea through the pipeline
process_idea() {
    local idea_id="$1"
    local idea_title="$2"

    log "Processing idea: $idea_id - $idea_title"

    # Get current labels to determine state
    local idea_json=$(bd show "$idea_id" --json 2>/dev/null)
    local labels=$(echo "$idea_json" | jq -r '.[0].labels // [] | join(",")' 2>/dev/null || echo "")

    # Check pipeline state based on labels
    if [[ "$labels" == *"prd:generating"* ]]; then
        log "  Skipping: PRD generation already in progress"
        return 0
    fi

    if [[ "$labels" == *"prd:interview-complete"* ]]; then
        # Interview complete - generate PRD
        log "  Interview complete, generating PRD..."
        bd update "$idea_id" --label "prd:generating" 2>/dev/null || true

        if ./generate-prd-from-interview.sh "$idea_id" >> "$LOG_FILE" 2>&1; then
            log "  PRD generated successfully"
            # Idea should be closed by generate-prd-from-interview.sh
        else
            log "  ERROR: PRD generation failed"
            bd update "$idea_id" --remove-label "prd:generating" 2>/dev/null || true
        fi
        return 0
    fi

    if [[ "$labels" == *"prd:interview-pending"* ]]; then
        # Check if interview is now complete
        log "  Checking interview status..."
        if ./collect-interview.sh "$idea_id" >> "$LOG_FILE" 2>&1; then
            # Interview complete!
            log "  Interview complete, marking for PRD generation"
            bd update "$idea_id" --remove-label "prd:interview-pending" 2>/dev/null || true
            bd update "$idea_id" --label "prd:interview-complete" 2>/dev/null || true
        else
            local exit_code=$?
            if [ $exit_code -eq 2 ]; then
                log "  Interview still pending (waiting for human)"
            else
                log "  ERROR: collect-interview.sh failed with code $exit_code"
            fi
        fi
        return 0
    fi

    # New idea - generate interview subtasks
    log "  New idea, generating interview subtasks..."
    bd update "$idea_id" --status in_progress 2>/dev/null || true

    if ./generate-interview.sh "$idea_id" >> "$LOG_FILE" 2>&1; then
        log "  Interview subtasks created, waiting for human answers"
        bd update "$idea_id" --label "prd:interview-pending" 2>/dev/null || true
    else
        log "  ERROR: Interview generation failed"
    fi
}

# Main loop
while true; do
    log ""
    log "--- Checking for ideas ---"

    # Get ideas assigned to prd-pipeline
    ideas_json=$(bd ready --assignee prd-pipeline --json 2>/dev/null || echo "[]")
    idea_count=$(echo "$ideas_json" | jq -r 'length' 2>/dev/null || echo "0")

    if [ "$idea_count" = "0" ] || [ -z "$idea_count" ]; then
        log "No ideas ready for processing"
    else
        log "Found $idea_count idea(s) to process"

        # Process each idea
        for i in $(seq 0 $((idea_count - 1))); do
            idea_id=$(echo "$ideas_json" | jq -r ".[$i].id")
            idea_title=$(echo "$ideas_json" | jq -r ".[$i].title")
            idea_type=$(echo "$ideas_json" | jq -r ".[$i].issue_type // \"task\"")

            # Only process ideas (not tasks/bugs/etc created by the pipeline)
            # Convention: ideas have type "feature" or "task" and are assigned to prd-pipeline
            # Skip epics as they're containers
            if [ "$idea_type" = "epic" ]; then
                log "Skipping epic: $idea_id"
                continue
            fi

            process_idea "$idea_id" "$idea_title" || {
                log "ERROR processing $idea_id: $?"
            }
        done
    fi

    log "Sleeping ${POLL_INTERVAL}s..."
    sleep "$POLL_INTERVAL"
done
