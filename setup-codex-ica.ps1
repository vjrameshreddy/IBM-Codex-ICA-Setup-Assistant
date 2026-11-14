# ==============================================================================
# IBM ICA (IBM Consulting Advantage) + Codex Automated Setup Script for Windows
# Version: 2.0.0
# ==============================================================================
[CmdletBinding()]
param(
    [Alias("Preview", "Plan")]
    [switch]$DryRun,

    [Alias("AssumeYes")]
    [switch]$Yes,

    [switch]$AutoBackup,
    [switch]$Overwrite,
    [switch]$InstallChatGPT,
    [switch]$SkipKeyPrompt,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Text)
    Write-Host "`n[+] $Text" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Text)
    Write-Host " [OK] $Text" -ForegroundColor Green
}

function Write-WarningMsg {
    param([string]$Text)
    Write-Host " [WARN] $Text" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Text)
    Write-Host " [ERROR] $Text" -ForegroundColor Red
}

function Write-HeaderBox {
    param([string]$Title, [string]$Subtitle)
    Write-Host "`n=================================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    if ($Subtitle) {
        Write-Host "  $Subtitle" -ForegroundColor DarkCyan
    }
    Write-Host "=================================================================" -ForegroundColor Cyan
}

function Ask-UserApproval {
    param([string]$PromptText, [bool]$DefaultYes = $true)
    
    if ($Yes -or $NonInteractive -or $AutoBackup -or $Overwrite) {
        return $DefaultYes
    }
    
    $options = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    $response = Read-Host "$PromptText $options"
    
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultYes
    }
    
    return ($response.Trim().ToLower() -eq 'y' -or $response.Trim().ToLower() -eq 'yes')
}

function Backup-ConfigFile {
    param(
        [string]$Path,
        [string]$Description,
        [bool]$IsSecret = $false
    )
    if (-not (Test-Path $Path)) { return }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $bakFile = "$Path.bak.$timestamp"
    try {
        Copy-Item -Path $Path -Destination $bakFile -Force
        if ($IsSecret) {
            $currentUser = $env:USERNAME
            & icacls "$bakFile" /inheritance:r /grant:r "${currentUser}:F" 2>$null | Out-Null
        }
        Write-Success "Backup created for $Description -> $bakFile"
    } catch {
        Write-WarningMsg "Could not backup $Description`: $_"
    }
}

function Prompt-FileAction {
    param(
        [string]$FilePath,
        [string]$Description
    )
    if (-not (Test-Path $FilePath)) {
        return "Write"
    }
    if ($AutoBackup) {
        return "BackupAndUpdate"
    }
    if ($Overwrite) {
        return "Overwrite"
    }
    if ($Yes -or $NonInteractive) {
        return "BackupAndUpdate"
    }
    
    Write-Host "`n [!] Existing $Description detected at $FilePath" -ForegroundColor Yellow
    Write-Host "     [1] Auto-Backup and Update (Recommended - creates a timestamped .bak file)" -ForegroundColor Cyan
    Write-Host "     [2] Overwrite in-place (no backup file)" -ForegroundColor DarkYellow
    Write-Host "     [3] Skip modifying this file" -ForegroundColor DarkGray
    $choice = Read-Host "     Select option [1/2/3] (Default: 1)"
    
    switch ($choice.Trim()) {
        "2" { return "Overwrite" }
        "3" { return "Skip" }
        Default { return "BackupAndUpdate" }
    }
}

Clear-Host
Write-HeaderBox "IBM ICA (IBM Consulting Advantage) + Codex Setup Tool" "Windows Edition with Dry-Run Preview & Explicit Confirmation"

# 1. Environment & Path Definitions
$CodexDir = Join-Path $HOME ".codex"
$ModelCatalogDir = Join-Path $CodexDir "model-catalog"
$CatalogJsonFile = Join-Path $ModelCatalogDir "ica-models.json"
$ConfigFile = Join-Path $CodexDir "config.toml"
$EnvFile = Join-Path $CodexDir ".env"
$TestDir = Join-Path $HOME "codex-ica-test"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 2. Check Prerequisites
Write-Step "Inspecting current system environment..."

$Prereqs = @{
    "Node.js" = "node -v"
    "npm"     = "npm -v"
    "Git"     = "git --version"
    "Python"  = "python --version"
    "VS Code" = "code --version"
}

$ToolStatus = @{}
foreach ($Tool in $Prereqs.Keys) {
    try {
        $cmd = $Prereqs[$Tool]
        $output = Invoke-Expression $cmd 2>$null
        if ($LASTEXITCODE -eq 0 -and $output) {
            $ToolStatus[$Tool] = $output.Trim()
            Write-Success "$Tool found: $($ToolStatus[$Tool])"
        } else {
            $ToolStatus[$Tool] = $null
            if ($Tool -eq "VS Code") {
                Write-WarningMsg "VS Code not found or not in PATH. (IBMers: Install via official 'PC@IBM' internal software catalog)"
            } else {
                Write-WarningMsg "$Tool not found or not in PATH."
            }
        }
    } catch {
        $ToolStatus[$Tool] = $null
        if ($Tool -eq "VS Code") {
            Write-WarningMsg "VS Code is missing. (IBMers: Install via official 'PC@IBM' internal software catalog)"
        } else {
            Write-WarningMsg "$Tool is missing."
        }
    }
}

# Check Codex CLI
$CodexVer = $null
try {
    $codexOut = Invoke-Expression "codex --version" 2>$null
    if ($LASTEXITCODE -eq 0 -and $codexOut) {
        $CodexVer = $codexOut.Trim()
        Write-Success "Codex CLI found: $CodexVer"
    }
} catch {}

if (-not $CodexVer) {
    Write-WarningMsg "Codex CLI (@openai/codex) is not currently installed."
}

# Check running background daemons
$RunningDaemons = @()
try {
    $RunningDaemons = Get-Process -Name 'codex', 'node_repl' -ErrorAction SilentlyContinue
} catch {}

# Check existing configuration files & ChatGPT desktop installation
$HasCatalog = Test-Path $CatalogJsonFile
$HasConfig = Test-Path $ConfigFile
$HasEnv = Test-Path $EnvFile
$HasTestDir = Test-Path $TestDir

$HasChatGPTDesktop = $false
if (Test-Path "$env:LOCALAPPDATA\Programs\ChatGPT\ChatGPT.exe") {
    $HasChatGPTDesktop = $true
} elseif (Test-Path "$env:ProgramFiles\ChatGPT\ChatGPT.exe") {
    $HasChatGPTDesktop = $true
}

# 3. Model Catalog Definition (Pure RFC 8259 JSON)
$ModelCatalogContent = @'
{
  "models": [
    {
      "slug": "gpt-advantage-assist",
      "display_name": "GPT Advantage Assist",
      "description": "GPT Advantage Assist from ICA",
      "default_reasoning_level": "medium",
      "base_instructions": "You are Codex, an AI coding agent. Follow the user's request, inspect relevant files before editing, make focused changes, use available tools appropriately, and verify completed work.",
      "supported_reasoning_levels": [
        {
          "effort": "low",
          "description": "Faster responses with lighter reasoning"
        },
        {
          "effort": "medium",
          "description": "Balanced speed and reasoning"
        },
        {
          "effort": "high",
          "description": "Deeper reasoning for complex tasks"
        },
        {
          "effort": "xhigh",
          "description": "Maximum reasoning for difficult tasks"
        }
      ],
      "shell_type": "shell_command",
      "visibility": "list",
      "supported_in_api": true,
      "support_verbosity": true,
      "truncation_policy": {
        "mode": "bytes",
        "limit": 10000
      },
      "experimental_supported_tools": [],
      "priority": 0,
      "upgrade": null
    },
    {
      "slug": "gpt-5.6-sol",
      "display_name": "GPT-5.6 Sol",
      "description": "GPT-5.6 Sol from ICA",
      "default_reasoning_level": "medium",
      "base_instructions": "You are Codex, an AI coding agent. Follow the user's request, inspect relevant files before editing, make focused changes, use available tools appropriately, and verify completed work.",
      "supported_reasoning_levels": [
        {
          "effort": "low",
          "description": "Faster responses with lighter reasoning"
        },
        {
          "effort": "medium",
          "description": "Balanced speed and reasoning"
        },
        {
          "effort": "high",
          "description": "Deeper reasoning for complex tasks"
        },
        {
          "effort": "xhigh",
          "description": "Maximum reasoning for difficult tasks"
        }
      ],
      "shell_type": "shell_command",
      "visibility": "list",
      "supported_in_api": true,
      "support_verbosity": true,
      "truncation_policy": {
        "mode": "bytes",
        "limit": 10000
      },
      "experimental_supported_tools": [],
      "priority": 0,
      "upgrade": null
    },
    {
      "slug": "gpt-5.6-luna",
      "display_name": "GPT-5.6 Luna",
      "description": "GPT-5.6 Luna from ICA",
      "default_reasoning_level": "medium",
      "base_instructions": "You are Codex, an AI coding agent. Follow the user's request, inspect relevant files before editing, make focused changes, use available tools appropriately, and verify completed work.",
      "supported_reasoning_levels": [
        {
          "effort": "low",
          "description": "Faster responses with lighter reasoning"
        },
        {
          "effort": "medium",
          "description": "Balanced speed and reasoning"
        },
        {
          "effort": "high",
          "description": "Deeper reasoning for complex tasks"
        },
        {
          "effort": "xhigh",
          "description": "Maximum reasoning for difficult tasks"
        }
      ],
      "shell_type": "shell_command",
      "visibility": "list",
      "supported_in_api": true,
      "support_verbosity": true,
      "truncation_policy": {
        "mode": "bytes",
        "limit": 10000
      },
      "experimental_supported_tools": [],
      "priority": 0,
      "upgrade": null
    },
    {
      "slug": "gpt-5.6-terra",
      "display_name": "GPT-5.6 Terra",
      "description": "GPT-5.6 Terra from ICA",
      "default_reasoning_level": "medium",
      "base_instructions": "You are Codex, an AI coding agent. Follow the user's request, inspect relevant files before editing, make focused changes, use available tools appropriately, and verify completed work.",
      "supported_reasoning_levels": [
        {
          "effort": "low",
          "description": "Faster responses with lighter reasoning"
        },
        {
          "effort": "medium",
          "description": "Balanced speed and reasoning"
        },
        {
          "effort": "high",
          "description": "Deeper reasoning for complex tasks"
        },
        {
          "effort": "xhigh",
          "description": "Maximum reasoning for difficult tasks"
        }
      ],
      "shell_type": "shell_command",
      "visibility": "list",
      "supported_in_api": true,
      "support_verbosity": true,
      "truncation_policy": {
        "mode": "bytes",
        "limit": 10000
      },
      "experimental_supported_tools": [],
      "priority": 0,
      "upgrade": null
    },
    {
      "slug": "gpt-5.4",
      "display_name": "GPT-5.4",
      "description": "GPT-5.4 from ICA",
      "default_reasoning_level": "medium",
      "base_instructions": "You are Codex, an AI coding agent. Follow the user's request, inspect relevant files before editing, make focused changes, use available tools appropriately, and verify completed work.",
      "supported_reasoning_levels": [
        {
          "effort": "low",
          "description": "Faster responses with lighter reasoning"
        },
        {
          "effort": "medium",
          "description": "Balanced speed and reasoning"
        },
        {
          "effort": "high",
          "description": "Deeper reasoning for complex tasks"
        },
        {
          "effort": "xhigh",
          "description": "Maximum reasoning for difficult tasks"
        }
      ],
      "shell_type": "shell_command",
      "visibility": "list",
      "supported_in_api": true,
      "support_verbosity": true,
      "truncation_policy": {
        "mode": "bytes",
        "limit": 10000
      },
      "experimental_supported_tools": [],
      "priority": 0,
      "upgrade": null
    },
    {
      "slug": "gpt-5.1",
      "display_name": "GPT-5.1",
      "description": "GPT-5.1 from ICA",
      "default_reasoning_level": "medium",
      "base_instructions": "You are Codex, an AI coding agent. Follow the user's request, inspect relevant files before editing, make focused changes, use available tools appropriately, and verify completed work.",
      "supported_reasoning_levels": [
        {
          "effort": "low",
          "description": "Faster responses with lighter reasoning"
        },
        {
          "effort": "medium",
          "description": "Balanced speed and reasoning"
        },
        {
          "effort": "high",
          "description": "Deeper reasoning for complex tasks"
        },
        {
          "effort": "xhigh",
          "description": "Maximum reasoning for difficult tasks"
        }
      ],
      "shell_type": "shell_command",
      "visibility": "list",
      "supported_in_api": true,
      "support_verbosity": true,
      "truncation_policy": {
        "mode": "bytes",
        "limit": 10000
      },
      "experimental_supported_tools": [],
      "priority": 0,
      "upgrade": null
    }
  ]
}
'@

# 4. Compute Merged config.toml Content
$EscapedCatalogPath = $CatalogJsonFile.Replace('\', '\\')

$TopLevelSettings = @"
model = "gpt-advantage-assist"
model_provider = "ica"
model_catalog_json = "$EscapedCatalogPath"
model_reasoning_effort = "medium"
"@

$ProviderSection = @"
[model_providers.ica]
name = "ICA"
base_url = "https://api.servicesessentials.ibm.com/v1"
wire_api = "responses"
env_key = "ICA_API_KEY"
requires_openai_auth = false
"@

$FinalConfigContent = ""
if (Test-Path $ConfigFile) {
    $ExistingLines = Get-Content $ConfigFile
    $FilteredLines = @()
    $InIcaSection = $false
    
    foreach ($Line in $ExistingLines) {
        $trimmed = $Line.Trim()
        if ($trimmed -match '^\[model_providers\.ica\]') {
            $InIcaSection = $true
            continue
        } elseif ($InIcaSection -and $trimmed -match '^\[') {
            $InIcaSection = $false
        }
        if ($InIcaSection) { continue }
        if ($trimmed -match '^(model|model_provider|model_catalog_json|model_reasoning_effort)\s*=') { continue }
        $FilteredLines += $Line
    }
    $FinalConfigContent = "$TopLevelSettings`r`n`r`n" + ($FilteredLines -join "`r`n") + "`r`n`r`n$ProviderSection`r`n"
} else {
    $FinalConfigContent = "$TopLevelSettings`r`n`r`n$ProviderSection`r`n"
}

# ==============================================================================
# PREVIEW / DRY-RUN SUMMARY (REQUIRED BEHAVIOR)
# ==============================================================================
Write-Host "`n+---------------------------------------------------------------+" -ForegroundColor Yellow
Write-Host "|                 PLANNED ACTIONS PREVIEW                       |" -ForegroundColor Yellow
Write-Host "+---------------------------------------------------------------+" -ForegroundColor Yellow

Write-Host " 1. Directory Structure:" -ForegroundColor White
Write-Host "    - Model Catalog Folder : $ModelCatalogDir $(if ($HasCatalog) { '[Exists]' } else { '[Will Create]' })" -ForegroundColor Gray
Write-Host "    - Test Workspace Folder: $TestDir $(if ($HasTestDir) { '[Exists]' } else { '[Will Create]' })" -ForegroundColor Gray

Write-Host "`n 2. Configuration Files:" -ForegroundColor White
Write-Host "    - Model Catalog ($CatalogJsonFile):" -ForegroundColor Gray
Write-Host "      Will write 6 ICA models (gpt-advantage-assist, gpt-5.6-sol, etc.) in UTF-8 without BOM.$(if ($HasCatalog) { ' [Auto-Backup offered]' })" -ForegroundColor DarkGray
Write-Host "    - Codex Config ($ConfigFile):" -ForegroundColor Gray
Write-Host "      Will $(if ($HasConfig) { 'merge with existing config [Auto-Backup offered]' } else { 'create new config' }) placing top-level ICA settings at top." -ForegroundColor DarkGray

Write-Host "`n 3. Secret & Environment Management:" -ForegroundColor White
Write-Host "    - Secret File : $EnvFile (Will store ICA_API_KEY with owner-only NTFS permissions$(if ($HasEnv) { ', Auto-Backup offered' }))" -ForegroundColor Gray
Write-Host "    - Environment : Will register ICA_API_KEY in Windows User Environment variables" -ForegroundColor Gray

Write-Host "`n 4. Process & Extension Management:" -ForegroundColor White
if (-not $CodexVer) {
    Write-Host "    - Software    : Will offer to install @openai/codex globally via npm" -ForegroundColor Yellow
} else {
    Write-Host "    - Software    : Codex CLI already installed ($CodexVer)" -ForegroundColor Gray
}
if ($HasChatGPTDesktop) {
    Write-Host "    - ChatGPT App : Desktop app detected (Will inherit ICA config automatically)" -ForegroundColor Gray
} else {
    Write-Host "    - ChatGPT App : Not installed (Will offer optional install via winget)" -ForegroundColor Gray
}
if ($RunningDaemons.Count -gt 0) {
    Write-Host "    - Daemons     : Will terminate $($RunningDaemons.Count) running codex/node_repl processes to reload environment" -ForegroundColor Yellow
} else {
    Write-Host "    - Daemons     : No stale background daemons running" -ForegroundColor Gray
}

Write-Host "+---------------------------------------------------------------+`n" -ForegroundColor Yellow

# If Dry-Run requested, display detailed preview and exit
if ($DryRun) {
    Write-Host "[DRY-RUN MODE ACTIVATED] Detailed file preview:" -ForegroundColor Cyan
    Write-Host "`n--- config.toml Preview ---" -ForegroundColor DarkCyan
    Write-Host $FinalConfigContent -ForegroundColor Gray
    Write-Host "--- End config.toml Preview ---`n" -ForegroundColor DarkCyan

    Write-Host "[DRY-RUN] No changes were made to your system. To apply these changes, run without -DryRun." -ForegroundColor Green
    exit 0
}

# ==============================================================================
# EXPLICIT USER CONFIRMATION (REQUIRED BEHAVIOR)
# ==============================================================================
$Proceed = Ask-UserApproval "Do you want to proceed with executing the planned setup actions?" $true

if (-not $Proceed) {
    Write-WarningMsg "Setup cancelled by user. No files or settings were modified."
    exit 0
}

# ------------------------------------------------------------------------------
# STEP 1: Install Codex CLI (if missing) with explicit confirmation
# ------------------------------------------------------------------------------
if (-not $CodexVer) {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $InstallCodex = Ask-UserApproval "Codex CLI (@openai/codex) is missing. Install globally now via npm?" $true
        if ($InstallCodex) {
            Write-Step "Installing @openai/codex globally via npm..."
            npm install -g @openai/codex
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Codex CLI installed successfully."
                $CodexVer = "Installed"
            } else {
                Write-ErrorMsg "Failed to install Codex CLI. Please check your npm permissions."
            }
        }
    } else {
        Write-WarningMsg "npm is not installed. Please install Node.js LTS from https://nodejs.org/ first."
    }
}

# ------------------------------------------------------------------------------
# STEP 1b: Optional ChatGPT Desktop App Installation (with explicit confirmation)
# ------------------------------------------------------------------------------
if (-not $HasChatGPTDesktop -and (Get-Command winget -ErrorAction SilentlyContinue)) {
    $shouldInstall = $false
    if ($InstallChatGPT) {
        $shouldInstall = $true
    } elseif (-not ($Yes -or $NonInteractive -or $AutoBackup -or $Overwrite)) {
        $shouldInstall = Ask-UserApproval "Would you like to install the official ChatGPT Desktop App via winget?" $false
    }

    if ($shouldInstall) {
        Write-Step "Installing ChatGPT Desktop App via winget..."
        try {
            & winget install --id OpenAI.ChatGPT -e --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Success "ChatGPT Desktop App installed successfully."
                $HasChatGPTDesktop = $true
            } else {
                Write-WarningMsg "winget could not complete installation. You can install manually from https://chatgpt.com/download/ if permitted by IBM policy."
            }
        } catch {
            Write-WarningMsg "Could not invoke winget: $_"
        }
    }
}

# ------------------------------------------------------------------------------
# STEP 2: Create Directories
# ------------------------------------------------------------------------------
Write-Step "Creating directories..."
if (-not (Test-Path $ModelCatalogDir)) {
    New-Item -ItemType Directory -Force -Path $ModelCatalogDir | Out-Null
    Write-Success "Created: $ModelCatalogDir"
} else {
    Write-Success "Verified: $ModelCatalogDir"
}

if (-not (Test-Path $TestDir)) {
    New-Item -ItemType Directory -Force -Path $TestDir | Out-Null
    Write-Success "Created: $TestDir"
} else {
    Write-Success "Verified: $TestDir"
}

# ------------------------------------------------------------------------------
# STEP 3: Write ica-models.json (RFC 8259 Pure UTF-8 without BOM)
# ------------------------------------------------------------------------------
Write-Step "Configuring ICA Model Catalog (ica-models.json)..."
$catalogAction = Prompt-FileAction $CatalogJsonFile "model catalog (ica-models.json)"
if ($catalogAction -eq "BackupAndUpdate") {
    Backup-ConfigFile $CatalogJsonFile "model catalog (ica-models.json)"
}
if ($catalogAction -ne "Skip") {
    [System.IO.File]::WriteAllText($CatalogJsonFile, $ModelCatalogContent, $Utf8NoBom)
    try {
        $null = Get-Content $CatalogJsonFile -Raw | ConvertFrom-Json
        Write-Success "ica-models.json written and validated successfully."
    } catch {
        Write-ErrorMsg "Failed to validate generated ica-models.json: $_"
    }
} else {
    Write-WarningMsg "Skipped modifying ica-models.json as requested."
}

# ------------------------------------------------------------------------------
# STEP 4: Configure config.toml
# ------------------------------------------------------------------------------
Write-Step "Configuring config.toml..."
$configAction = Prompt-FileAction $ConfigFile "Codex config (config.toml)"
if ($configAction -eq "BackupAndUpdate") {
    Backup-ConfigFile $ConfigFile "config.toml"
}
if ($configAction -ne "Skip") {
    [System.IO.File]::WriteAllText($ConfigFile, $FinalConfigContent, $Utf8NoBom)
    Write-Success "config.toml updated with ICA model provider and catalog path."
} else {
    Write-WarningMsg "Skipped modifying config.toml as requested."
}

# ------------------------------------------------------------------------------
# STEP 5: Secure API Key Configuration
# ------------------------------------------------------------------------------
Write-Step "Configuring ICA API Key..."

if ($SkipKeyPrompt) {
    Write-WarningMsg "Skipping API key prompt as requested."
} else {
    $ApiKey = $null
    $ShouldWriteEnv = $true
    
    if (Test-Path $EnvFile) {
        $ExistingEnv = Get-Content $EnvFile -Raw -ErrorAction SilentlyContinue
        if ($ExistingEnv -match 'ICA_API_KEY=\s*(\S+)' -and $Matches[1] -ne 'REPLACE_WITH_YOUR_NEW_CODEX_CODING_AGENT_KEY') {
            Write-Success "An existing ICA_API_KEY was found in $EnvFile."
            if ($AutoBackup) {
                $ApiKey = $Matches[1]
                $ShouldWriteEnv = $false
                Write-Success "Retained active ICA_API_KEY."
            } elseif ($Overwrite) {
                $ApiKey = $null
            } else {
                Write-Host "`n [!] Existing .env secret file detected." -ForegroundColor Yellow
                Write-Host "     [1] Keep existing key (Recommended)" -ForegroundColor Cyan
                Write-Host "     [2] Auto-Backup .env and enter a new key" -ForegroundColor DarkCyan
                Write-Host "     [3] Overwrite .env in-place with new key" -ForegroundColor DarkYellow
                Write-Host "     [4] Skip secret configuration" -ForegroundColor DarkGray
                $keyChoice = Read-Host "     Select option [1/2/3/4] (Default: 1)"
                
                switch ($keyChoice.Trim()) {
                    "2" {
                        Backup-ConfigFile $EnvFile ".env (secret)" -IsSecret $true
                        $ApiKey = $null
                    }
                    "3" {
                        $ApiKey = $null
                    }
                    "4" {
                        $ShouldWriteEnv = $false
                    }
                    Default {
                        $ApiKey = $Matches[1]
                        $ShouldWriteEnv = $false
                        Write-Success "Retained active ICA_API_KEY."
                    }
                }
            }
        }
    }
    
    if ($ShouldWriteEnv -and (-not $ApiKey)) {
        Write-Host "To obtain your Coding Agent API key:" -ForegroundColor Cyan
        Write-Host " 1. Sign in to https://servicesessentials.ibm.com/" -ForegroundColor Gray
        Write-Host " 2. Select/Create your 2.0 team (e.g. '<YourName> Codex Training')" -ForegroundColor Gray
        Write-Host " 3. Settings > API Keys > Coding Agents > Generate Coding Agent API Key" -ForegroundColor Gray
        Write-Host " 4. Copy the key from the 'Codex' row (NOT general ICA key)" -ForegroundColor Gray
        Write-Host ""
        
        $SecureString = Read-Host "Paste your Codex Coding Agent API Key (input will be hidden)" -AsSecureString
        if ($SecureString) {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            $ApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }
    
    if ($ShouldWriteEnv -and (-not [string]::IsNullOrWhiteSpace($ApiKey))) {
        $EnvContent = "ICA_API_KEY=$ApiKey`r`n"
        [System.IO.File]::WriteAllText($EnvFile, $EnvContent, $Utf8NoBom)
        
        # Apply strict NTFS owner-only permissions
        try {
            $currentUser = $env:USERNAME
            & icacls "$EnvFile" /inheritance:r /grant:r "${currentUser}:F" 2>$null | Out-Null
            Write-Success ".env file created with strict user-only permissions."
        } catch {
            Write-WarningMsg "Could not set icacls permissions on .env file: $_"
        }
    }
    
    # Set for current PowerShell session & persistent User Environment Variable if key exists
    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        $env:ICA_API_KEY = $ApiKey
        try {
            [System.Environment]::SetEnvironmentVariable('ICA_API_KEY', $ApiKey, 'User')
            Write-Success "Registered ICA_API_KEY user environment variable for VS Code and GUI apps."
        } catch {}
    } elseif (-not $ShouldWriteEnv) {
        Write-Success ".env retained untouched."
    } else {
        Write-WarningMsg "No API key was entered. You will need to manually configure $EnvFile later."
    }
}

# ------------------------------------------------------------------------------
# STEP 6: Process Management (Terminate Stale Daemons with Confirmation)
# ------------------------------------------------------------------------------
if ($RunningDaemons.Count -gt 0) {
    Write-Step "Background Process Management..."
    $KillDaemons = Ask-UserApproval "Terminate $($RunningDaemons.Count) stale background Codex process(es) to reload environment?" $true
    if ($KillDaemons) {
        try {
            Get-Process -Name 'codex', 'node_repl' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Success "Stopped background Codex daemons. They will restart automatically with fresh environment."
        } catch {
            Write-WarningMsg "Could not stop daemon processes: $_"
        }
    }
}

# ------------------------------------------------------------------------------
# STEP 7: Completion & Next Steps
# ------------------------------------------------------------------------------
Write-HeaderBox "IBM ICA + Codex Setup Completed Successfully!"

Write-Host "Configuration files:" -ForegroundColor Cyan
Write-Host " - Model Catalog:  $CatalogJsonFile" -ForegroundColor Gray
Write-Host " - Codex Config:   $ConfigFile" -ForegroundColor Gray
Write-Host " - API Key:        $EnvFile" -ForegroundColor Gray
Write-Host " - Test Directory: $TestDir" -ForegroundColor Gray

Write-Host "`nNext Steps to Verify:" -ForegroundColor Yellow
Write-Host " 1. Reload environment in this current PowerShell window (run this command):" -ForegroundColor White
Write-Host "      `$env:ICA_API_KEY = [System.Environment]::GetEnvironmentVariable('ICA_API_KEY', 'User')" -ForegroundColor Cyan
Write-Host " 2. Open terminal in test folder and run Codex CLI:" -ForegroundColor White
Write-Host "      cd `"$TestDir`"" -ForegroundColor Cyan
Write-Host "      codex" -ForegroundColor Cyan
Write-Host "    Inside Codex, check status by typing:" -ForegroundColor White
Write-Host "      /status" -ForegroundColor Cyan
Write-Host "    (It should display: provider: ica, model: gpt-advantage-assist)" -ForegroundColor Gray
Write-Host " 3. For Visual Studio Code:" -ForegroundColor White
Write-Host "    - Install 'Codex - OpenAI''s coding agent' (OpenAI.chatgpt) extension." -ForegroundColor Gray
Write-Host "    - Open folder: `"$TestDir`" and click Trust." -ForegroundColor Gray
Write-Host "    - Open the Codex tab to start coding with ICA!" -ForegroundColor Gray
Write-Host "=================================================================`n" -ForegroundColor Green
