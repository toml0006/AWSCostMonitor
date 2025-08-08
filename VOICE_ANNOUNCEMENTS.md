# Voice Announcements for AWSCostMonitor

This project includes a voice announcement system that uses macOS text-to-speech to notify you when tasks are completed.

## Features

- 🎙️ Uses Samantha voice (female) for all announcements
- 🔊 Different sounds for success, error, and warning states
- 📝 Logs all announcements to `~/.claude/awscostmonitor-announcements.log`
- 🎯 Project name "AWS Cost Monitor" included in announcements

## Usage

### Manual Announcements

```bash
# Announce task completion
./announce-completion.sh task "Dark mode implementation"

# Announce successful build
./announce-completion.sh build "Version 1.3.0" success

# Announce deployment
./announce-completion.sh deploy "Website updates" success

# Announce new feature
./announce-completion.sh feature "Voice announcements added"
```

### Event Types

- `task` - General task completion
- `build` - Build completed/failed
- `test` - Test suite results
- `deploy` - Deployment status
- `release` - New version released
- `commit` - Code committed
- `push` - Code pushed to repository
- `security` - Security updates
- `feature` - New feature added
- `fix` - Bug fix applied

### Status Types

- `success` - Glass sound (pleasant chime)
- `error` - Basso sound (error tone)
- `warning` - Pop sound (attention)
- Other - Tink sound (neutral)

## Configuration

The system is configured in `.claude/config.json` (local to your machine, not committed to git).

### Available Voices

You can change the voice by editing the `VOICE` variable in the scripts:
- Samantha (default - American female)
- Karen (Australian female)
- Moira (Irish female)
- Tessa (South African female)
- Fiona (Scottish female)
- Kate (British female)
- Serena (British female)
- Veena (Indian female)

## Integration with Claude

When using Claude Code with this project, task completions will automatically trigger voice announcements if the hooks are properly configured.

## Troubleshooting

If announcements aren't working:

1. Check that scripts are executable:
   ```bash
   chmod +x .claude/hooks/*.sh
   chmod +x announce-completion.sh
   ```

2. Test the voice system:
   ```bash
   say -v Samantha "Testing AWS Cost Monitor announcements"
   ```

3. Check the log file:
   ```bash
   tail ~/.claude/awscostmonitor-announcements.log
   ```

## Privacy

All announcement logs are stored locally on your machine and are never committed to the repository.