# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Non-Obvious Project Gotchas & Critical Rules

- **UTF-8 BOM Prohibition**: Windows PowerShell `[System.Text.Encoding]::UTF8` and `Out-File -Encoding utf8` emit a UTF-8 BOM (`\ufeff`). The Rust-based Codex JSON parser fails with `expected value at line 1 column 1` on BOM files. ALWAYS write files with `New-Object System.Text.UTF8Encoding($false)` via `[System.IO.File]::WriteAllText()`.
- **TOML Top-Level Placement**: In `~/.codex/config.toml`, `model`, `model_provider`, `model_catalog_json`, and `model_reasoning_effort` MUST precede any `[table]` headers. Placing them below any section header attaches them to that table, causing Codex to fall back to `provider: openai`.
- **Windows Path Escaping in TOML**: `model_catalog_json` in `config.toml` requires double-escaped backslashes (`C:\\Users\\<user>\\.codex\\model-catalog\\ica-models.json`).
- **Codex Daemon Cache**: Codex CLI spawns persistent background processes (`codex.exe`, `node_repl.exe`). Changes to `ICA_API_KEY` require killing daemons (`Stop-Process -Name codex,node_repl -Force`) and setting the User Environment Variable (`[System.Environment]::SetEnvironmentVariable('ICA_API_KEY', $k, 'User')`).
- **Secret Permissions**: Any file holding `ICA_API_KEY` (`.env` or `.env.bak.*`) must use owner-only permissions: `icacls $path /inheritance:r /grant:r "${env:USERNAME}:F"` on Windows, `chmod 600` on macOS/Linux.
- **ChatGPT Desktop App Shared Scope**: The desktop app reads `~/.codex/config.toml` directly. Do not mix personal ChatGPT accounts with the work `~/.codex` profile.
- **Standalone Web Architecture**: `index.html` is zero-dependency (no external CDNs/fonts/scripts) to work completely offline in air-gapped or restricted IBM intranet environments.
- **IBM Enterprise Workstation Banner**: `index.html` repeats the same "🏢 IBM Enterprise Workstation Requirement (PC@IBM / Mac@IBM)" callout in three tabs: Fast-Track (`tab-auto`), Step 1 (`tab-prereqs`), and Step 4 (`tab-clients`). Keep the three copies identical when editing.
- **Script Flag Parity**: `setup-codex-ica.ps1` (`-DryRun -Yes -AutoBackup -Overwrite -InstallChatGPT -SkipKeyPrompt -NonInteractive`) and `setup-codex-ica.sh` (`--dry-run --yes --auto-backup --overwrite --install-chatgpt --skip-key-prompt`) must stay in sync. There is no automated test suite; validate with the dry-run and syntax commands below.

## Essential Commands

- **Dry-run PowerShell setup**: `powershell -ExecutionPolicy Bypass -File .\setup-codex-ica.ps1 -DryRun`
- **Dry-run Shell setup**: `bash ./setup-codex-ica.sh --dry-run`
- **Validate PowerShell script syntax**: `powershell -Command "[System.Management.Automation.Language.Parser]::ParseFile('.\setup-codex-ica.ps1', [ref]\$null, [ref]\$null)"`
- **Validate Bash script syntax**: `bash -n ./setup-codex-ica.sh`
- **Validate Model Catalog JSON**: `python -m json.tool .\ica-models.json`
- **Single Test Prompt via CLI**: `cd "$HOME\codex-ica-test"; codex exec "Say hello in one sentence. Do not create or modify any files."`
