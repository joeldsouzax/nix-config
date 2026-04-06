# AI Agents Design: Paperclip + Hermes

**Date**: 2026-04-01
**Approach**: Nix-managed git clones + declarative service wrappers (Approach 2)

## Overview

Install Paperclip (AI agent orchestration) and Hermes Agent (autonomous AI agent) as persistent services on both NixOS and Darwin, with SOPS-managed secrets and Slack gateway for Hermes.

## Architecture

```
modules/home/ai-agents.nix          # Cross-platform shared module
  ├── home.packages                  # Runtime deps (node, python, pnpm, uv, etc.)
  ├── home.activation                # Git clone + dep install (~/.local/share/)
  ├── home.file                      # Hermes config.yaml, wrapper scripts
  ├── systemd.user.services (Linux)  # paperclip + hermes services
  └── launchAgents (Darwin)          # paperclip + hermes launch agents
```

## Files Changed

| File | Change |
|------|--------|
| `flake.nix` | Pass `sops-nix` to Darwin config |
| `darwin/default.nix` | Import sops-nix Darwin module, add SOPS config block |
| `modules/home/ai-agents.nix` | NEW — full cross-platform module |
| `modules/home/default.nix` | Add `./ai-agents.nix` to imports |
| `secrets/secrets.yaml` | Add `hermes_slack_bot_token` |
| `hosts/configuration.nix` | Add SOPS secret entries for new secrets |

## SOPS Secrets

- `claude_key` (existing) — reused as ANTHROPIC_API_KEY for both Paperclip and Hermes
- `hermes_slack_bot_token` (new) — Slack bot token for Hermes gateway

## SOPS on Darwin (new)

Currently NixOS-only. Enable by:
1. Adding `sops-nix.darwinModules.sops` to Darwin modules in `flake.nix`
2. Configuring `sops` block in `darwin/default.nix` with `age.keyFile = "/Users/joel/.config/sops/age/keys.txt"`

Darwin age key (`admin_trive`: `age1qpmwdqqdl23pd9m7xmyz8yhal5yxepgklml3eejjmt5u5436jd9s58rv7y`) is already in `.sops.yaml` creation rules.

## Service Details

### Paperclip
- **Install path**: `~/.local/share/paperclip` (git clone from `paperclipai/paperclip`)
- **Build**: `pnpm install` during activation
- **Runs on**: port 3100
- **Database**: Embedded PostgreSQL (bundled by Paperclip)
- **Secret**: ANTHROPIC_API_KEY from `claude_key`

### Hermes
- **Install path**: `~/.local/share/hermes` (git clone from `NousResearch/hermes-agent`)
- **Build**: `uv pip install -e ".[all]"` + `npm install` during activation
- **Config**: `~/.hermes/config.yaml` (declarative, Anthropic provider)
- **Gateway**: Slack (bot token from SOPS)
- **Secrets**: ANTHROPIC_API_KEY from `claude_key`, SLACK_BOT_TOKEN from `hermes_slack_bot_token`

## Platform-Specific Service Management

### NixOS (systemd user services)
- `systemd.user.services.paperclip` — ExecStart with node, EnvironmentFile for secrets
- `systemd.user.services.hermes` — ExecStart with python, EnvironmentFile for secrets

### Darwin (launchd agents)
- `launchAgents` via home-manager — wrapper scripts that read SOPS secret paths and export as env vars before exec (launchd doesn't support EnvironmentFile)

## Manual Steps (one-time)

1. Create Slack app at api.slack.com with bot scopes
2. `sops secrets/secrets.yaml` — add `hermes_slack_bot_token: xoxb-...`
3. Run `nixswitch` on each platform
