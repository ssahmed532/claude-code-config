# claude-code-config

My personal [Claude Code](https://claude.com/claude-code) configuration, including global instructions, settings, custom statusline scripts, and reference documents.

## Repository Structure

This repo mirrors the `~/.claude/` directory structure. Tracked files contain configuration and customizations; sensitive/ephemeral directories are excluded via `.gitignore` with placeholder READMEs explaining their purpose.

```
.claude/
├── CLAUDE.md                          # Global instructions (the main config)
├── CLAUDE-old1.md                     # Previous version of global instructions
├── settings.json                      # Claude Code settings (model, statusline, etc.)
├── statusline-command.ps1             # Custom statusline script (PowerShell, working)
├── statusline-command.sh              # Custom statusline script (Bash)
├── NOT_WORKING_statusline-command.ps1 # Earlier statusline attempt (kept for reference)
├── plugins/
│   └── blocklist.json                 # Plugin blocklist configuration
│   └── known_marketplaces.json        # Registered plugin marketplaces
├── backups/                           # [excluded] Auto-generated config backups
├── cache/                             # [excluded] Runtime cache
├── debug/                             # [excluded] Debug logs
├── downloads/                         # [excluded] Session downloads
├── file-history/                      # [excluded] File modification tracking
├── ide/                               # [excluded] IDE integration state
├── projects/                          # [excluded] Per-project session transcripts
├── sessions/                          # [excluded] Global session state
├── shell-snapshots/                   # [excluded] Shell environment snapshots
├── tasks/                             # [excluded] In-session task tracking
├── telemetry/                         # [excluded] Usage telemetry
├── todos/                             # [excluded] Todo items
└── usage-data/                        # [excluded] Insights analytics data

reference/
└── prompts/
    └── insights_prompt_reconstruction.md  # Reverse-engineered /insights prompt

templates/
└── CLAUDE.md.template                 # Skeleton for per-project CLAUDE.md files
```

## Key Files

| File | Purpose |
|------|---------|
| `.claude/CLAUDE.md` | Global instructions loaded into every Claude Code session. Covers coding style, git workflow, verification, error handling, and platform-specific rules. |
| `.claude/settings.json` | Model selection and statusline configuration. |
| `.claude/statusline-command.ps1` | PowerShell script for custom Claude Code statusline with ANSI colors, token count display. |
| `.claude/statusline-command.sh` | Bash equivalent with git branch, context usage, cost, and session duration. |
| `templates/CLAUDE.md.template` | Starting point for creating per-project CLAUDE.md files. |

## Usage

This repo is for tracking and versioning my Claude Code configuration. To use:

1. **As reference**: Browse the global `CLAUDE.md` for ideas on structuring your own.
2. **As template**: Copy `templates/CLAUDE.md.template` into a new project and fill in the sections.
3. **Statusline scripts**: Adapt the `.ps1` or `.sh` scripts for your own Claude Code statusline.

## License

[MIT](LICENSE)
