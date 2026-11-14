# Project Architecture Rules (Non-Obvious Only)

- **Provider Routing Scheme**: Codex uses custom endpoint configuration via `[model_providers.ica]` with `wire_api = "responses"` and `env_key = "ICA_API_KEY"`. Do not change `wire_api` to `openai` or standard completions format.
- **Model Catalog Coupling**: `ica-models.json` is tightly coupled to `config.toml` via `model_catalog_json`. Every slug in `config.toml` (e.g. `gpt-advantage-assist`, `gpt-5.6-sol`) MUST exist inside the catalog's `"models"` array.
- **Dual Credential Mechanism**: The CLI looks for `ICA_API_KEY` in session environment variables and `.codex/.env`. VS Code and GUI desktop apps read Windows User Environment variables or user profile `.env`. Setting both is mandatory for multi-client compatibility.
- **Dry-Run Determinism**: All script operations must support non-mutating preview (`-DryRun` / `--dry-run`) computing exact diffs before touching disk.
- **Idempotent Directories & Backups**: Workspace `~/codex-ica-test` and catalog `~/.codex/model-catalog` directories must use idempotent creation (`mkdir -p` / `New-Item -Force`). File modifications must offer timestamped backups prior to write.
