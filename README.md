# ClawBox 📦

**Back up your OpenClaw workspace to Box.com with JWT authentication.**

ClawBox is a [ClawHub](https://clawhub.ai) skill that automatically backs up your OpenClaw workspace files to Box.com using secure JWT authentication. Never lose your AI agent's memory, configurations, or custom scripts again.

## ✨ Features

- **🔒 Secure JWT authentication** - No passwords or API keys to manage
- **📅 Timestamped backups** - Each backup creates a dated folder for easy versioning
- **⚙️ Configurable** - Choose which files and directories to back up
- **🤖 Automation-ready** - Perfect for cron jobs and scheduled backups
- **📊 Progress reporting** - See exactly what was backed up and any failures
- **🛡️ Safe defaults** - Backs up essential OpenClaw files out of the box

## 🚀 Quick Start

### 1. Install via ClawHub

```bash
clawhub install clawbox
```

### 2. Prerequisites

- [Box.com account](https://box.com) (free tier works)
- [Box CLI](https://github.com/box/boxcli) installed
- OpenClaw workspace you want to back up

### 3. Set up Box.com Integration

#### Create a Box Custom App

1. Go to [Box Developer Console](https://app.box.com/developers/console)
2. **Create New App** → **Custom App** → **Server Authentication (with JWT)**
3. App name: "OpenClaw Backup" (or whatever you prefer)
4. **Configuration tab:**
   - ✅ Enable "Write all files and folders" scope
   - Click "Generate a public/private keypair" and download the JSON config file
5. **Authorization tab:**
   - Submit for approval or auto-approve if you're an admin

#### Install and Configure Box CLI

```bash
# Install Box CLI (macOS)
brew install box/box-cli/box

# Authorize with your JWT config file
box configure:environments:add --config-file-path /path/to/your/box_config.json --name default
```

### 4. Configure ClawBox

Create your config file:

```bash
mkdir -p ~/.clawbox
cat > ~/.clawbox/config.json << 'EOF'
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
EOF
```

**To get your Box folder ID:**
1. Create a folder on Box.com for your backups (e.g., "OpenClaw Backups")
2. Open the folder in your browser
3. Copy the folder ID from the URL: `box.com/folder/FOLDER_ID_HERE`
4. Replace `YOUR_BOX_FOLDER_ID` in the config above

### 5. Run Your First Backup

```bash
cd ~/.openclaw/skills/clawbox
./scripts/box-backup.sh
```

You should see output like:
```
📦 Starting ClawBox backup to Box.com — 2024-12-17_1430
📁 Workspace: /Users/yourusername/.openclaw/workspace
📁 Created backup folder: 2024-12-17_1430 (ID: 123456789)
  ✅ AGENTS.md
  ✅ SOUL.md
  ✅ USER.md
  ✅ memory/2024-12-16.md
  ✅ memory/2024-12-17.md
  ✅ scripts/my-script.sh

📊 Backup complete: 6 uploaded, 0 failed
📍 Box.com backup folder: 2024-12-17_1430
```

## 📋 Usage

### Manual Backup
```bash
./scripts/box-backup.sh
```

### Silent Mode
```bash
./scripts/box-backup.sh --quiet
```

### Automated Backups

Set up automated backups with cron:

```bash
# Edit your crontab
crontab -e

# Add one of these lines:
# Daily backup at 2 AM
0 2 * * * /Users/yourusername/.openclaw/skills/clawbox/scripts/box-backup.sh --quiet

# Every 6 hours
0 */6 * * * /Users/yourusername/.openclaw/skills/clawbox/scripts/box-backup.sh --quiet

# Weekly backup on Sundays at 3 AM
0 3 * * 0 /Users/yourusername/.openclaw/skills/clawbox/scripts/box-backup.sh --quiet
```

## ⚙️ Configuration

### Config File (`~/.clawbox/config.json`)

```json
{
  "box_folder_id": "123456789",
  "workspace_path": "/Users/username/.openclaw/workspace",
  "backup_files": [
    "AGENTS.md",
    "SOUL.md",
    "USER.md", 
    "IDENTITY.md",
    "TOOLS.md",
    "HEARTBEAT.md",
    "MEMORY.md",
    "custom-file.md"
  ],
  "backup_directories": [
    "memory",
    "scripts",
    "skills"
  ]
}
```

### Environment Variables

You can override config settings with environment variables:

- `CLAWBOX_BOX_FOLDER_ID` - Target Box folder ID
- `CLAWBOX_WORKSPACE_PATH` - OpenClaw workspace path  
- `CLAWBOX_CONFIG_PATH` - Config file location (default: `~/.clawbox/config.json`)

Example:
```bash
CLAWBOX_BOX_FOLDER_ID=987654321 ./scripts/box-backup.sh
```

## 🛠️ What Gets Backed Up

By default, ClawBox backs up:

**Core Files:**
- `AGENTS.md` - Your agent's configuration and behavior
- `SOUL.md` - Your agent's personality and identity  
- `USER.md` - Information about you for personalization
- `TOOLS.md` - Local tool configurations and notes
- `MEMORY.md` - Your agent's long-term memory
- `HEARTBEAT.md` - Proactive task configuration
- `IDENTITY.md` - Additional identity configuration

**Directories:**
- `memory/` - Daily memory files and context
- `scripts/` - Custom automation scripts

Each backup creates a timestamped folder on Box.com, so you can easily browse backup history and restore specific versions.

## 🔧 Troubleshooting

### Common Issues

**❌ "Failed to create subfolder on Box"**
- Check that your `box_folder_id` is correct
- Verify your Box app has "Write all files and folders" permission
- Test Box CLI: `box folders:get YOUR_FOLDER_ID`

**❌ "box: command not found"** 
- Install Box CLI: `brew install box/box-cli/box`
- Or download from [GitHub releases](https://github.com/box/boxcli/releases)

**❌ "Unauthorized" or "Invalid JWT"**
- Re-run Box CLI setup: `box configure:environments:add --config-file-path /path/to/config.json`
- Check that your Box app is approved in Developer Console
- Verify the JWT config file is downloaded correctly

**❌ "jq: command not found"**
- Install jq for JSON parsing: `brew install jq`

**❌ "Config file not found"**
- Create config file at `~/.clawbox/config.json` (see setup instructions)
- Or set `CLAWBOX_CONFIG_PATH` environment variable

**❌ "Workspace directory not found"** 
- Update `workspace_path` in your config file
- Check that OpenClaw is installed and the workspace exists

### Testing Your Setup

1. **Test Box CLI connection:**
   ```bash
   box folders:get YOUR_FOLDER_ID
   ```

2. **Test ClawBox with dry run:**
   ```bash
   # Check what would be backed up (won't actually upload)
   ./scripts/box-backup.sh --quiet 2>&1 | grep "✅\|❌\|⚠️"
   ```

3. **Verify backup on Box.com:**
   - Log into Box.com
   - Navigate to your backup folder
   - Look for timestamped folders with your files

## 🔐 Security & Privacy

- **No credentials stored**: ClawBox doesn't store any Box.com credentials - they're managed securely by Box CLI
- **Local configuration only**: Your config file only contains non-sensitive folder IDs and file paths
- **JWT authentication**: Uses Box's secure JWT standard for server-to-server authentication
- **No network exposure**: Runs locally on your machine, only uploads to your Box account

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

## 🤝 Contributing

Issues and pull requests welcome! This is an open-source ClawHub skill.

## 🔗 Links

- [Box CLI Documentation](https://github.com/box/boxcli)
- [Box Developer Console](https://app.box.com/developers/console)  
- [ClawHub Skill Repository](https://clawhub.ai)
- [OpenClaw Documentation](https://openclaw.ai)

---

**Made with ❤️ for the OpenClaw community**