# IBM Codex + IBM Consulting Advantage (ICA) Integration Toolkit

A comprehensive setup, automation, and guidance toolkit to configure **OpenAI Codex** (CLI, Visual Studio Code extension, and ChatGPT desktop app) to connect securely with **IBM Consulting Advantage (ICA 2.0)** on **Windows** and **macOS (Apple Silicon)**.

---

## 🚀 Key Deliverables in this Repository

| File | Description |
| :--- | :--- |
| [**`index.html`**](index.html) | **Interactive Web Setup Assistant** — A visual, step-by-step assistant for non-technical users and developers with an OS toggle, live config generator, and troubleshooting guide. |
| [**`setup-codex-ica.ps1`**](setup-codex-ica.ps1) | **Windows Automation Script** — Automated PowerShell setup (directory scaffolding, BOM-free model catalog creation, TOML merging, secure key prompt, and NTFS permissions). |
| [**`setup-codex-ica.sh`**](setup-codex-ica.sh) | **macOS / Linux Automation Script** — Automated Shell script (npm global prefix fix, model catalog creation, TOML merging, and `chmod 600`). |
| [**`ica-models.json`**](ica-models.json) | **ICA Model Catalog** — Complete, valid JSON definition for all 6 ICA models (`gpt-advantage-assist`, `gpt-5.6-sol`, `gpt-5.6-luna`, `gpt-5.6-terra`, `gpt-5.4`, `gpt-5.1`). |

---

## ⚡ Fast-Track: Automated Installation

### 1. On Windows (PowerShell)
Open PowerShell as your standard user and run:
```powershell
powershell -ExecutionPolicy Bypass -File .\setup-codex-ica.ps1
```
*The script automatically verifies prerequisites, writes `ica-models.json`, merges `config.toml`, masks your API key during input, applies owner-only permissions, and refreshes background daemons.*

### 2. On macOS (Terminal - zsh)
Open Terminal and run:
```bash
chmod +x setup-codex-ica.sh
./setup-codex-ica.sh
```

---

## 🌐 Interactive Web Setup Assistant

For a guided, visual walkthrough tailored for non-technical users:
1. Double-click or open [`index.html`](index.html) in any web browser.
2. Select your operating system (**Windows** or **macOS**).
3. Follow the visual steps, copy single-line commands with 1-click buttons, or generate customized configuration files.

---

## 🎯 Post-Installation Verification: 2-Step Roadmap

Once the setup script finishes, follow these two verification steps:

### Step 1: 30-Second Terminal Test (Confirm Connection)
Open PowerShell or Terminal and run:
```powershell
cd "$HOME\codex-ica-test"
codex
```

Inside the interactive Codex prompt:
1. Type `/status` &rarr; verify that it shows:
   - **`provider: ica`**
   - **`model: gpt-advantage-assist`**
2. Send the safe test prompt:
   ```text
   Say hello in one sentence. Do not create or modify any files.
   ```
   *(Expected response: `Hello!` directly from ICA)*
3. Type `/exit` to close the CLI session.

---

### Step 2: Daily Coding in Visual Studio Code
1. Open **Visual Studio Code**.
2. Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>X</kbd> (macOS: <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>X</kbd>) and install **Codex - OpenAI's coding agent** (`OpenAI.chatgpt`).
3. Open your test folder (`C:\Users\<username>\codex-ica-test` or any project folder) via **File > Open Folder**.
4. If prompted with Restricted Mode, select **"Trust this folder"**.
5. Click the **Codex icon** in the left Activity Bar to open the chat panel.
6. Run the coding verification prompt:
   ```text
   Create a Python program named hello.py that prints "IBM Codex ICA integration successful". Run the program, verify its output, and report the result. Do not modify any other files.
   ```
7. Verify by running the generated program in your terminal:
   ```powershell
   python hello.py
   ```

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
