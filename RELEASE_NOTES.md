# Release Notes — IBM ICA + Codex Integration Toolkit

All notable changes, architectural updates, security assessments, and configuration schema migrations for the **IBM ICA (IBM Consulting Advantage) + Codex Integration Toolkit** are documented in this file.

---

## [2.0.0] — 2026-11-14

### Overview
Major release adding automated file backup and overwrite engines, unified branding alignment (*IBM ICA + Codex*), enterprise security hardening (NTFS owner-only ACLs & POSIX `chmod 600`), project-wide rule governance (`AGENTS.md` and `.bob/rules-*/`), and a comprehensive 5-step verification roadmap.

### 🚀 Features Added & Enhanced
- **Auto-Backup & Overwrite Engine**:
  - Implemented timestamped automatic backups (`*.bak.YYYYMMDD_HHMMSS`) for `config.toml`, `.env`, and `ica-models.json`.
  - Added CLI flags: `-AutoBackup` / `--auto-backup`, `-Overwrite` / `--overwrite`, `-DryRun` / `--dry-run`, `-Yes` / `--yes`.
- **Branding Alignment**:
  - Standardized project title and interface branding to **IBM ICA (IBM Consulting Advantage) + Codex** across scripts, web guides, documentation, and configuration headers.
- **5-Step Setup & Verification Roadmap**:
  - Restructured the setup lifecycle into 5 distinct, sequential steps (1: Prerequisites, 2: ICA Portal & Key, 3: Configuration, 4: Client Setup, 5: Verification & Testing).
  - Added 1-click `✓ Mark All 5 Steps Done (100%)` button in `index.html` for Fast-Track script users.
  - Added detailed verification sections for Codex CLI, VS Code extension (`OpenAI.chatgpt`), and ChatGPT Desktop app.
- **Agent Rules & Governance**:
  - Added root [`AGENTS.md`](AGENTS.md) and mode-specific rules in `.bob/rules-agent/AGENTS.md`, `.bob/rules-ask/AGENTS.md`, and `.bob/rules-plan/AGENTS.md`.
- **Repository Hygiene & `.gitignore`**:
  - Added complete enterprise `.gitignore` protecting `.env`, credentials, backups (`*.bak*`), and system caches.

### 🔒 Security Findings & Vulnerability Fixes
1. **SEC-01 (High — CWE-732 / Credential Exposure)**: Storing API keys in `.env.bak` could leave backup keys world-readable if default file permissions applied.
   - *Fix*: Backups of `.env` now explicitly inherit owner-only permissions via `icacls` on Windows and `chmod 600` on macOS/Linux.
2. **SEC-02 (Medium — CWE-200 / Information Disclosure)**: Interactive API key prompts could expose keys on screen or in shell histories.
   - *Fix*: Integrated `Read-Host -AsSecureString` with marshal zero-free memory cleanup on Windows and `read -s` on POSIX systems.
3. **BUG-01 (Medium — Functional Parser Failure)**: Duplicate catalog block in `setup-codex-ica.sh` referenced obsolete `gpt-5.6-sol-pro` slug.
   - *Fix*: Consolidated catalog writer in `setup-codex-ica.sh` to write the standard 6-model catalog (`gpt-5.6-luna`) matching `ica-models.json`.

### 🗄️ Database Changes & Migrations
- **Database Architecture**: This project is a client-side setup automation and developer toolkit that operates on local filesystem configuration files (`~/.codex/config.toml`, `~/.codex/model-catalog/ica-models.json`, `~/.codex/.env`). It does not utilize a relational or NoSQL database.
- **Schema & Configuration Migrations**:
  - *v1.0.0 &rarr; v2.0.0*: Model catalog upgraded to pure RFC 8259 JSON schema with 6 validated models (`gpt-advantage-assist`, `gpt-5.6-sol`, `gpt-5.6-luna`, `gpt-5.6-terra`, `gpt-5.4`, `gpt-5.1`).
  - *Configuration Format*: Top-level TOML settings enforce `wire_api = "responses"`, `model_provider = "ica"`, and `base_url = "https://api.servicesessentials.ibm.com/v1"`.

---

## [1.2.0] — 2026-11-13

### 🚀 Features Added
- Added Dry-Run / Preview Mode (`-DryRun` / `--dry-run`) displaying full file diffs and action previews before execution.
- Added explicit user approval prompts before every installation, file modification, or background process termination.
- Integrated automated ChatGPT Desktop App installation checks via `winget` (Windows) and `brew` (macOS).

### 🔒 Security & Bug Fixes
- Fixed UTF-8 BOM encoding issue where PowerShell `[System.Text.Encoding]::UTF8` wrote a 3-byte BOM, crashing Codex's Rust JSON parser (`expected value at line 1 column 1`). Resolved by writing pure UTF-8 without BOM via `New-Object System.Text.UTF8Encoding($false)`.
- Fixed background daemon environment variable caching where stale `codex.exe` and `node_repl.exe` processes held old empty environments in memory.

---

## [1.1.0] — 2026-11-13

### 🚀 Features Added
- Created interactive single-page offline web setup assistant ([`index.html`](index.html)) with Dark and Light IBM Carbon themes.
- Added platform switcher toggling instructions dynamically between Windows (PowerShell) and macOS (Terminal / Zsh).
- Built automated setup scripts: `setup-codex-ica.ps1` for Windows and `setup-codex-ica.sh` for macOS/Linux.

---

## [1.0.0] — 2026-11-13

### 🚀 Initial Release
- Comprehensive analysis of `IBM_Codex_ICA_Getting_Started_Guide.docx`.
- Initial definition of `ica-models.json` and manual setup instructions.

---

## 🛡️ Security & Vulnerability Assessment — Summary

| Assessment Category | Status | Details & Compliance |
|---|:---:|---|
| **Hardcoded Credentials** | **PASSED** | Zero hardcoded keys or passwords in codebase. All keys loaded via secure user input into user-restricted `.env` / User Environment. |
| **Input Validation & Injection** | **PASSED** | TOML config merging strips conflicting sections; JSON catalog is validated via RFC 8259 parser. |
| **File Permissions & ACLs** | **PASSED** | Secrets protected by NTFS owner-only ACLs on Windows and `chmod 600` on macOS/Linux. |
| **Dependency Vulnerabilities** | **PASSED** | Zero external runtime dependencies in `index.html` (pure vanilla HTML5/CSS3/ES6, no external CDNs). Scripts use native OS tools. |
| **Offline Air-Gap Readiness** | **PASSED** | Fully operable within firewalled or air-gapped corporate environments without external network egress. |
| **IBM Security Standards** | **COMPLIANT** | Adheres to IBM Security Meta-Rules, SAML/API key authentication boundaries, and least-privilege principles. |
