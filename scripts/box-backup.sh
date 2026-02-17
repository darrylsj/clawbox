#!/bin/bash
# ClawBox - OpenClaw Workspace Backup to Box.com
# Backs up OpenClaw workspace files to Box.com using JWT authentication
# Usage: ./box-backup.sh [--quiet]

set -euo pipefail

# Default config file location
DEFAULT_CONFIG="$HOME/.clawbox/config.json"
CONFIG_FILE="${CLAWBOX_CONFIG_PATH:-$DEFAULT_CONFIG}"

# Check if jq is available for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is required for JSON parsing. Install with: brew install jq"
    exit 1
fi

# Check if Box CLI is installed
if ! command -v box &> /dev/null; then
    echo "❌ Error: Box CLI not found. Install with: brew install box/box-cli/box"
    exit 1
fi

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Error: Config file not found at $CONFIG_FILE"
    echo "Create config file with:"
    echo "mkdir -p ~/.clawbox"
    echo "cat > ~/.clawbox/config.json << 'EOF'"
    echo '{'
    echo '  "box_folder_id": "YOUR_BOX_FOLDER_ID",'
    echo '  "workspace_path": "/path/to/.openclaw/workspace",'
    echo '  "backup_files": ["AGENTS.md", "SOUL.md", "USER.md", "TOOLS.md", "MEMORY.md"],'
    echo '  "backup_directories": ["memory", "scripts"]'
    echo '}'
    echo 'EOF'
    exit 1
fi

# Parse config file
BOX_FOLDER_ID="${CLAWBOX_BOX_FOLDER_ID:-$(jq -r '.box_folder_id' "$CONFIG_FILE")}"
WORKSPACE="${CLAWBOX_WORKSPACE_PATH:-$(jq -r '.workspace_path' "$CONFIG_FILE")}"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M")
QUIET="${1:-}"

# Validate required config
if [[ "$BOX_FOLDER_ID" == "null" || -z "$BOX_FOLDER_ID" ]]; then
    echo "❌ Error: box_folder_id not set in config file"
    exit 1
fi

if [[ "$WORKSPACE" == "null" || -z "$WORKSPACE" ]]; then
    echo "❌ Error: workspace_path not set in config file"
    exit 1
fi

if [[ ! -d "$WORKSPACE" ]]; then
    echo "❌ Error: Workspace directory not found: $WORKSPACE"
    exit 1
fi

log() {
    [[ "$QUIET" != "--quiet" ]] && echo "$1"
}

log "📦 Starting ClawBox backup to Box.com — $TIMESTAMP"
log "📁 Workspace: $WORKSPACE"

# Create a dated subfolder
SUBFOLDER_ID=$(box folders:create "$BOX_FOLDER_ID" "$TIMESTAMP" --json 2>&1 | grep '"id"' | head -1 | sed 's/.*"id": "\([^"]*\)".*/\1/')

if [[ -z "$SUBFOLDER_ID" ]]; then
    echo "❌ Failed to create subfolder on Box"
    echo "Check your Box folder ID and permissions"
    exit 1
fi

log "📁 Created backup folder: $TIMESTAMP (ID: $SUBFOLDER_ID)"

# Get backup files list from config
BACKUP_FILES=$(jq -r '.backup_files[]' "$CONFIG_FILE" 2>/dev/null || echo "")
if [[ -z "$BACKUP_FILES" ]]; then
    # Default backup files if not specified
    BACKUP_FILES="AGENTS.md
SOUL.md
USER.md
IDENTITY.md
TOOLS.md
HEARTBEAT.md
MEMORY.md"
fi

uploaded=0
failed=0

# Upload core files
while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if [[ -f "$WORKSPACE/$f" ]]; then
        if box files:upload "$WORKSPACE/$f" --parent-id "$SUBFOLDER_ID" --json >/dev/null 2>&1; then
            log "  ✅ $f"
            ((uploaded++))
        else
            log "  ❌ $f (upload failed)"
            ((failed++))
        fi
    else
        log "  ⚠️  $f (not found)"
    fi
done <<< "$BACKUP_FILES"

# Get backup directories list from config
BACKUP_DIRS=$(jq -r '.backup_directories[]?' "$CONFIG_FILE" 2>/dev/null || echo "")
if [[ -z "$BACKUP_DIRS" ]]; then
    # Default backup directories
    BACKUP_DIRS="memory
scripts"
fi

# Upload directories
while IFS= read -r dir; do
    [[ -z "$dir" ]] && continue
    if [[ -d "$WORKSPACE/$dir" ]]; then
        DIR_FOLDER_ID=$(box folders:create "$SUBFOLDER_ID" "$dir" --json 2>&1 | grep '"id"' | head -1 | sed 's/.*"id": "\([^"]*\)".*/\1/')
        if [[ -n "$DIR_FOLDER_ID" ]]; then
            for f in "$WORKSPACE/$dir/"*; do
                [[ ! -f "$f" ]] && continue
                fname=$(basename "$f")
                if box files:upload "$f" --parent-id "$DIR_FOLDER_ID" --json >/dev/null 2>&1; then
                    log "  ✅ $dir/$fname"
                    ((uploaded++))
                else
                    log "  ❌ $dir/$fname"
                    ((failed++))
                fi
            done
        fi
    else
        log "  ⚠️  Directory not found: $dir"
    fi
done <<< "$BACKUP_DIRS"

log ""
log "📊 Backup complete: $uploaded uploaded, $failed failed"
log "📍 Box.com backup folder: $TIMESTAMP"

if [[ $failed -gt 0 ]]; then
    log "⚠️  Some files failed to upload. Check Box CLI configuration and permissions."
    exit 1
fi