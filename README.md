# IBM ICA (IBM Consulting Advantage) + Codex Integration Toolkit

![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)
![Status](https://img.shields.io/badge/status-active-brightgreen.svg)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS-informational.svg)

A comprehensive setup, automation, and guidance toolkit to configure **OpenAI Codex** (CLI, Visual Studio Code extension, and ChatGPT desktop app) to connect securely with **IBM Consulting Advantage (ICA 2.0)** on **Windows** and **macOS (Apple Silicon)**.

---

## 🚀 Key Deliverables in this Repository

| File | Description |
| :--- | :--- |
| [**`index.html`**](index.html) | **Interactive Web Integration Toolkit** (`v2.0.0`) — A visual, step-by-step assistant for non-technical users and developers with an OS toggle, live config generator, and troubleshooting guide. |
| [**`setup-codex-ica.ps1`**](setup-codex-ica.ps1) | **Windows Automation Script** (`v2.0.0`) — Automated PowerShell setup (directory scaffolding, BOM-free model catalog creation, TOML merging, secure key prompt, and NTFS permissions). |
| [**`setup-codex-ica.sh`**](setup-codex-ica.sh) | **macOS / Linux Automation Script** (`v2.0.0`) — Automated Shell script (npm global prefix fix, model catalog creation, TOML merging, and `chmod 600`). |
| [**`ica-models.json`**](ica-models.json) | **ICA Model Catalog** — Complete, valid JSON definition for all 6 ICA models (`gpt-advantage-assist`, `gpt-5.6-sol`, `gpt-5.6-luna`, `gpt-5.6-terra`, `gpt-5.4`, `gpt-5.1`). |
| [**`RELEASE_NOTES.md`**](RELEASE_NOTES.md) | **Release Notes & Security Assessment** — Complete version history, security vulnerability audit, and filesystem migration records. |
| [**`plan.md`**](plan.md) | **Architecture & Development Plan** — System architecture, client integration boundaries, and maintenance strategy. |
| [**`AGENTS.md`**](AGENTS.md) | **Engineering & Agent Rules** — Non-obvious project knowledge, critical gotchas, and execution commands. |

---

## ⚡ Fast-Track: Automated Installation

### 1. Preview / Dry-Run (No Changes Made)
Inspect planned changes, file diffs, and directory creations before executing:

- **Windows (PowerShell)**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\setup-codex-ica.ps1 -DryRun
  ```
- **macOS (Terminal)**:
  ```bash
  chmod +x setup-codex-ica.sh && ./setup-codex-ica.sh --dry-run
  ```

---

### 2. Run Automated Installation (With Auto-Backup & Overwrite Options)
The script provides a clear action preview and requires your explicit confirmation before applying changes, storing credentials, or terminating daemon processes:

- **Windows (PowerShell)**:
  ```powershell
  # Interactive mode with Auto-Backup & Overwrite prompts for existing files:
  powershell -ExecutionPolicy Bypass -File .\setup-codex-ica.ps1

  # Force automatic timestamped backups without prompting:
  powershell -ExecutionPolicy Bypass -File .\setup-codex-ica.ps1 -AutoBackup

  # Force direct overwrite without creating backup files:
  powershell -ExecutionPolicy Bypass -File .\setup-codex-ica.ps1 -Overwrite
  ```
  *(To bypass interactive confirmation in automated CI workflows, use `-Yes`)*

- **macOS (Terminal)**:
  ```bash
  # Interactive mode with Auto-Backup & Overwrite prompts for existing files:
  chmod +x setup-codex-ica.sh
  ./setup-codex-ica.sh

  # Force automatic timestamped backups without prompting:
  ./setup-codex-ica.sh --auto-backup

  # Force direct overwrite without creating backup files:
  ./setup-codex-ica.sh --overwrite
  ```
  *(To bypass interactive confirmation in automated CI workflows, use `--yes`)*

---

### 🛡️ Safe Backup & Overwrite Safeguards
When existing files (`config.toml`, `.env`, `ica-models.json`) are detected, the tool offers three safe choices:
1. **Auto-Backup and Update** *(Recommended)*: Creates a timestamped `.bak.YYYYMMDD_HHMMSS` copy (with NTFS owner-only or `chmod 600` permissions for `.env`) before updating.
2. **Overwrite In-Place**: Directly replaces configuration without creating `.bak` files.
3. **Keep Existing / Skip**: Retains existing file untouched.

---

## 🌐 Interactive Web Integration Toolkit

For a guided, visual walkthrough tailored for non-technical users:
1. Double-click or open [`index.html`](index.html) in any web browser.
2. Select your operating system (**Windows** or **macOS**).
3. Follow the visual steps, copy single-line commands with 1-click buttons, or generate customized configuration files.

---

## 🎯 Full 5-Step Setup & Verification Roadmap

The integration process consists of 5 clear stages:

| Step | Stage | Description |
|:---:|:---|:---|
| **Step 1** | **Prerequisites** | Verify Node.js, npm, Git, Python, and install Codex CLI (`@openai/codex`). *(IBMers: Install VS Code via `PC@IBM` / `Mac@IBM`)* |
| **Step 2** | **ICA 2.0 Portal** | Access Essentials Portal and generate a dedicated **Codex Coding Agent API Key**. |
| **Step 3** | **Configuration** | Deploy `ica-models.json`, update `config.toml`, and store `ICA_API_KEY` securely. |
| **Step 4** | **Client Setup** | Install VS Code Extension (`OpenAI.chatgpt`) and (optional) ChatGPT Desktop App. *(IBM Workstations: VS Code from `PC@IBM` / `Mac@IBM`)* |
| **Step 5** | **Verification & Testing** | Run the 30-second CLI test, VS Code `hello.py` test prompt, and desktop validation. |

---

### Step 5 Details: End-to-End Verification

#### 5.1 30-Second Terminal Test (CLI)
Open PowerShell or Terminal and run:

- **Windows (PowerShell)**:
  ```powershell
  $env:ICA_API_KEY = [System.Environment]::GetEnvironmentVariable('ICA_API_KEY', 'User')
  New-Item -ItemType Directory -Force "$HOME\codex-ica-test" | Out-Null
  cd "$HOME\codex-ica-test"
  codex
  ```

- **macOS / Linux (Terminal)**:
  ```bash
  mkdir -p ~/codex-ica-test
  cd ~/codex-ica-test
  codex
  ```
1. Type `/status` &rarr; verify **`provider: ica`** and **`model: gpt-advantage-assist`**.
2. Send safe test prompt:
   ```text
   Say hello in one sentence. Do not create or modify any files.
   ```
3. Type `/exit` to close.

#### 5.2 VS Code Coding Agent Validation
1. Open **Visual Studio Code** on `~/codex-ica-test`.
2. Open the **Codex icon** in the left Activity Bar.
3. Run the coding verification prompt:
   ```text
   Create a Python program named hello.py that prints "IBM Codex ICA integration successful". Run the program, verify its output, and report the result. Do not modify any other files.
   ```
4. Verify by running: `python hello.py`.

#### 5.3 ChatGPT Desktop App Integration
1. Open a Codex conversation in the desktop app on your `~/codex-ica-test` workspace.
2. Send test prompt: `Say hello in one sentence. Do not create or modify any files.`
3. A successful response confirms the desktop app is using ICA credentials.

---

## 🛠️ Manual Configuration Reference

If you prefer to configure files manually, use the following layout:

### 1. Model Catalog: `~/.codex/model-catalog/ica-models.json`
Create the file in UTF-8 without BOM using the contents of [`ica-models.json`](ica-models.json).

### 2. Codex Configuration: `~/.codex/config.toml`
Place top-level settings before any section headers:
```toml
model = "gpt-advantage-assist"
model_provider = "ica"
model_catalog_json = "C:\\Users\\YOUR_USERNAME\\.codex\\model-catalog\\ica-models.json"
model_reasoning_effort = "medium"

# (Keep existing desktop/plugin configuration here...)

[model_providers.ica]
name = "ICA"
base_url = "https://api.servicesessentials.ibm.com/v1"
wire_api = "responses"
env_key = "ICA_API_KEY"
requires_openai_auth = false
```
*(On macOS, use `/Users/YOUR_USERNAME/.codex/model-catalog/ica-models.json`)*.

### 3. API Key File: `~/.codex/.env`
Create the `.env` file containing:
```env
ICA_API_KEY=YOUR_CODEX_CODING_AGENT_KEY
```

Apply restricted owner-only permissions:
- **Windows**:
  ```powershell
  icacls "$HOME\.codex\.env" /inheritance:r /grant:r "$($env:USERNAME):F"
  ```
- **macOS**:
  ```bash
  chmod 600 ~/.codex/.env
  ```

---

## ❓ Troubleshooting & Diagnostics

| Symptom / Error | Root Cause | Solution |
| :--- | :--- | :--- |
| `failed to parse model_catalog_json ... expected value at line 1 column 1` | `ica-models.json` contains a UTF-8 Byte Order Mark (BOM). | Re-save the file as pure UTF-8 (No BOM) or run `setup-codex-ica.ps1`. |
| `Missing environment variable: ICA_API_KEY` | Codex background daemon server (`codex.exe`) is caching an old environment. | Terminate stale daemon processes: `Get-Process -Name 'codex', 'node_repl' \| Stop-Process -Force` and reload `$env:ICA_API_KEY`. |
| `running scripts is disabled on this system` | PowerShell execution policy restriction. | Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` or use `codex.cmd`. |
| `/status shows provider: openai instead of ica` | Top-level settings in `config.toml` placed below a `[section]` header. | Move the 4 top-level settings to the very top of `~/.codex/config.toml`. |
| `npm EACCES permission error` (macOS) | Global npm folder requiring root permissions. | Configure user prefix: `npm config set prefix "$HOME/.npm-global"` (handled automatically by `setup-codex-ica.sh`). |
| `.env.txt` or `ica-models.json.txt` created | Windows Notepad appending `.txt` extension. | In File Explorer, enable **View > Show > File name extensions** and remove the trailing `.txt`. |

---

## 🔒 Security & IBM Policy Requirements

- **API Keys are Secrets**: Treat your ICA Coding Agent API Key as confidential. Never commit `.env` or `config.toml` containing credentials to source control, chat channels, or screenshots.
- **Separate Work and Personal Profiles**: Keep your personal ChatGPT accounts strictly separate from IBM work directories.
- **Dedicated Team Isolation**: Use an authorized ICA 2.0 team for coding agent workflows.
