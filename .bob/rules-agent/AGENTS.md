# Project Coding Rules (Non-Obvious Only)

- **PowerShell File Writing**: Never use `Out-File` or `Set-Content` without strictly overriding UTF-8 encoding. Standard `[System.Text.Encoding]::UTF8` in Windows PowerShell (5.1) emits a 3-byte BOM (`EF BB BF`) that crashes the Codex Rust JSON parser. Use `New-Object System.Text.UTF8Encoding($false)`.
- **TOML Merging Logic**: When editing `config.toml`, preserve existing user configurations (`[plugins]`, `[marketplaces]`, `[mcp_servers]`, `[shell_environment_policy]`), but strip conflicting top-level keys (`model`, `model_provider`, `model_catalog_json`, `model_reasoning_effort`) and stale `[model_providers.ica]` blocks before prepending new settings.
- **Secret Masking & Input**: Never pass `ICA_API_KEY` in plain arguments or commit to git. Use `Read-Host -AsSecureString` with marshal unprotect on Windows and `read -s` on macOS/Linux.
- **Safe Backups**: Backups must use timestamp pattern `*.bak.yyyyMMdd_HHmmss` to prevent collisions. Any backup of `.env` must immediately have ACLs restricted to the owner (`icacls /inheritance:r` or `chmod 600`).
- **Daemon Lifecycle**: Never assume setting an environment variable in PowerShell propagates to already running Codex background services. Explicitly recycle `codex` and `node_repl` processes when credentials change.
