---
name: clawbox
description: Back up OpenClaw workspace files to Box.com using JWT authentication. Use when users need to back up their workspace files, create automated backups, or sync their OpenClaw workspace to cloud storage.
---

# ClawBox - OpenClaw Workspace Backup to Box.com

Automatically back up your OpenClaw workspace files to Box.com with JWT authentication.

## Quick Start

1. **Install Box CLI**: `brew install box/box-cli/box` (macOS) or [download](https://github.com/box/boxcli)
2. **Configure Box JWT app** (see setup instructions below)
3. **Configure clawbox**: Create `~/.clawbox/config.json` with your settings
4. **Run backup**: `scripts/box-backup.sh`

## Setup Instructions

### 1. Create Box Custom App

1. Go to [Box Developer Console](https://app.box.com/developers/console)
2. Create New App → Custom App → Server Authentication (with JWT)
3. App name: "OpenClaw Backup" or similar
4. **In Configuration tab:**
   - Enable "Write all files and folders" scope
   - Generate a public/private keypair (download the JSON config)
5. **In Authorization tab:**
   - Submit app for approval (or auto-approve if admin)

### 2. Setup Box CLI with JWT

```bash
# Install Box CLI
brew install box/box-cli/box

# Authorize with your JWT config file
box configure:environments:add --config-file-path /path/to/your/box_config.json --name default
```

### 3. Configure ClawBox

Create config file at `~/.clawbox/config.json`:

```json
{
  "box_folder_id": "YOUR_BOX_FOLDER_ID",
  "workspace_path": "/Users/yourusername/.openclaw/workspace",
  "backup_files": [
    "AGENTS.md",
    "SOUL.md", 
    "USER.md",
    "IDENTITY.md",
    "TOOLS.md",
    "HEARTBEAT.md",
    "MEMORY.md"
  ],
  "backup_directories": [
    "memory",
    "scripts"
  ]
}
```

**To get your Box folder ID:**
1. Create a folder on Box.com for backups
2. Open folder in browser, copy ID from URL: `box.com/folder/FOLDER_ID_HERE`

## Usage

### Manual Backup
```bash
cd skills/clawbox
./scripts/box-backup.sh
```

### Quiet Mode
```bash
./scripts/box-backup.sh --quiet
```

### Automated Backups (Cron)

Add to crontab (`crontab -e`):
```bash
# Daily backup at 2 AM
0 2 * * * /path/to/clawbox/scripts/box-backup.sh --quiet

# Every 6 hours
0 */6 * * * /path/to/clawbox/scripts/box-backup.sh --quiet
```

## What Gets Backed Up

- **Core files**: AGENTS.md, SOUL.md, USER.md, TOOLS.md, MEMORY.md, etc.
- **Memory directory**: Daily memory files and long-term memory
- **Scripts directory**: All custom scripts and automation
- **Timestamped folders**: Each backup creates a dated folder for easy versioning

## Configuration

Environment variables (override config file):

- `CLAWBOX_BOX_FOLDER_ID`: Target Box folder ID
- `CLAWBOX_WORKSPACE_PATH`: OpenClaw workspace path
- `CLAWBOX_CONFIG_PATH`: Config file location (default: `~/.clawbox/config.json`)

## Troubleshooting

**"Failed to create subfolder"**: Check Box folder ID and permissions
**"box: command not found"**: Install Box CLI with `brew install box/box-cli/box`
**"Unauthorized"**: Re-run `box configure:environments:add` with your JWT config
**"Permission denied"**: Ensure your Box app has "Write all files and folders" scope

## Security Notes

- JWT credentials are stored securely by Box CLI
- No credentials are included in this skill
- Config file should contain only non-sensitive settings
- Use environment variables in production/CI environments