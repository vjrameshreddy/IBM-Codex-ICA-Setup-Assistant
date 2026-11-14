# Development & Architecture Plan — IBM ICA + Codex Integration Toolkit

**Current Version**: `v2.0.0`  
**Status**: Active / Production Ready  
**Upstream Reference**: `IBM_Codex_ICA_Getting_Started_Guide.docx`

---

## 1. Project Overview & Architecture

The **IBM ICA + Codex Integration Toolkit** bridges **OpenAI Codex** (CLI, VS Code extension, and official ChatGPT Desktop application) with **IBM Consulting Advantage (ICA 2.0)** enterprise endpoints (`https://api.servicesessentials.ibm.com/v1`).

```
+-----------------------------------------------------------------------------------+
|                              Client Interfaces                                    |
|   [Codex CLI]              [VS Code (OpenAI.chatgpt)]       [ChatGPT Desktop App]  |
+------------------------------------+----------------------------------+-----------+
                                     | (Reads shared config & env)
                                     v
+-----------------------------------------------------------------------------------+
|                        User Home Configuration (~/.codex/)                        |
|   ├── config.toml                 (wire_api = "responses", provider = "ica")      |
|   ├── model-catalog/                                                              |
|   │   └── ica-models.json         (6 validated ICA models, pure UTF-8 no BOM)     |
|   └── .env                        (ICA_API_KEY with NTFS ACL / chmod 600)         |
+------------------------------------+----------------------------------------------+
                                     | (Authenticated HTTPS / TLS 1.2+)
                                     v
+-----------------------------------------------------------------------------------+
|                    IBM Consulting Advantage (ICA 2.0) Gateway                     |
|                    https://api.servicesessentials.ibm.com/v1                      |
+-----------------------------------------------------------------------------------+
```

---

## 2. Core Components & Deliverables

| Deliverable | Target System | Version | Role |
|---|---|:---:|---|
| [`setup-codex-ica.ps1`](setup-codex-ica.ps1) | Windows (PowerShell 5.1/7+) | `v2.0.0` | Automated setup, non-BOM UTF-8 catalog writer, TOML merger, NTFS security, background daemon recycler. |
| [`setup-codex-ica.sh`](setup-codex-ica.sh) | macOS / Linux (Zsh / Bash) | `v2.0.0` | Automated setup, `.npm-global` prefix configuration, TOML merger, `chmod 600` secret permissions. |
| [`index.html`](index.html) | Modern Web Browsers | `v2.0.0` | Standalone zero-dependency interactive setup assistant with dark/light themes and live config generators. |
| [`ica-models.json`](ica-models.json) | Local Codex Catalog | `v2.0.0` | RFC 8259 JSON catalog supporting all 6 ICA models. |
| [`AGENTS.md`](AGENTS.md) | AI Coding Agents | `v2.0.0` | Root engineering rules, critical gotchas, and non-obvious project knowledge. |
| [`RELEASE_NOTES.md`](RELEASE_NOTES.md) | All Developers / Audit | `v2.0.0` | Comprehensive version-wise changes, security assessments, and migration history. |

---

## 3. Database & Storage Architecture

- **Database Engine**: None (N/A). The project is completely file-based.
- **State Storage**:
  - Global user configuration: `~/.codex/config.toml` (TOML format)
  - Model catalog: `~/.codex/model-catalog/ica-models.json` (JSON format)
  - Secret credentials: `~/.codex/.env` (Key-value format)
  - Interactive web preferences: Browser `localStorage` (`codex_ica_platform`, `codex_ica_theme`, `codex_ica_progress`).

---

## 4. Security & Compliance Strategy

1. **Secret Isolation**: `ICA_API_KEY` is never written to public repos or transmitted to third parties. Backups inherit strict owner-only permissions.
2. **Deterministic Previews**: All automation scripts must provide `-DryRun` / `--dry-run` to preview operations before making disk modifications.
3. **Encoding Safety**: All file writes to `.codex` must bypass default BOM emitters to preserve compatibility with Rust-based parser runtimes.
4. **Offline Resilience**: `index.html` operates without network calls or external font/script dependencies.

---

## 5. Maintenance & Versioning Policy

For all future changes:
- Follow **Semantic Versioning** (`MAJOR.MINOR.PATCH`).
- Keep [`README.md`](README.md), [`RELEASE_NOTES.md`](RELEASE_NOTES.md), [`plan.md`](plan.md), and script headers synchronized.
- Document any schema modifications or model catalog updates.
