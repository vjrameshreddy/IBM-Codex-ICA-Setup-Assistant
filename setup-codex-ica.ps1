# ==============================================================================
# IBM Codex + ICA (IBM Consulting Advantage) Automated Setup Script for Windows
# ==============================================================================
[CmdletBinding()]
param(
    [Alias("Preview", "Plan")]
    [switch]$DryRun,

    [Alias("AssumeYes")]
    [switch]$Yes,

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
    
    if ($Yes -or $NonInteractive) {
        return $true
    }
    
    $options = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    $response = Read-Host "$PromptText $options"
    
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultYes
    }
    
    return ($response.Trim().ToLower() -eq 'y' -or $response.Trim().ToLower() -eq 'yes')
}

Clear-Host
Write-HeaderBox "IBM Codex + IBM Consulting Advantage (ICA) Setup Tool" "Windows Edition with Dry-Run Preview & Explicit Confirmation"

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
            Write-WarningMsg "$Tool not found or not in PATH."
        }
    } catch {
        $ToolStatus[$Tool] = $null
        Write-WarningMsg "$Tool is missing."
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

# Check existing configuration files
$HasCatalog = Test-Path $CatalogJsonFile
$HasConfig = Test-Path $ConfigFile
$HasEnv = Test-Path $EnvFile
$HasTestDir = Test-Path $TestDir

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
Write-Host "      Will write 6 ICA models (gpt-advantage-assist, gpt-5.6-sol, etc.) in UTF-8 without BOM." -ForegroundColor DarkGray
Write-Host "    - Codex Config ($ConfigFile):" -ForegroundColor Gray
Write-Host "      Will $(if ($HasConfig) { 'merge with existing config' } else { 'create new config' }) placing top-level ICA settings at top." -ForegroundColor DarkGray

Write-Host "`n 3. Secret & Environment Management:" -ForegroundColor White
Write-Host "    - Secret File : $EnvFile (Will store ICA_API_KEY with owner-only NTFS permissions)" -ForegroundColor Gray
Write-Host "    - Environment : Will register ICA_API_KEY in Windows User Environment variables" -ForegroundColor Gray

Write-Host "`n 4. Process & Extension Management:" -ForegroundColor White
if (-not $CodexVer) {
    Write-Host "    - Software    : Will offer to install @openai/codex globally via npm" -ForegroundColor Yellow
} else {
    Write-Host "    - Software    : Codex CLI already installed ($CodexVer)" -ForegroundColor Gray
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
Write-Step "Writing ICA Model Catalog (ica-models.json)..."
[System.IO.File]::WriteAllText($CatalogJsonFile, $ModelCatalogContent, $Utf8NoBom)

try {
    $null = Get-Content $CatalogJsonFile -Raw | ConvertFrom-Json
    Write-Success "ica-models.json created and validated successfully."
} catch {
    Write-ErrorMsg "Failed to validate generated ica-models.json: $_"
}

# ------------------------------------------------------------------------------
# STEP 4: Configure config.toml
# ------------------------------------------------------------------------------
Write-Step "Configuring config.toml..."
[System.IO.File]::WriteAllText($ConfigFile, $FinalConfigContent, $Utf8NoBom)
Write-Success "config.toml updated with ICA model provider and catalog path."

# ------------------------------------------------------------------------------
# STEP 5: Secure API Key Configuration
# ------------------------------------------------------------------------------
Write-Step "Configuring ICA API Key..."

if ($SkipKeyPrompt) {
    Write-WarningMsg "Skipping API key prompt as requested."
} else {
    $ApiKey = $null
    
    if (Test-Path $EnvFile) {
        $ExistingEnv = Get-Content $EnvFile -Raw -ErrorAction SilentlyContinue
        if ($ExistingEnv -match 'ICA_API_KEY=\s*(\S+)' -and $Matches[1] -ne 'REPLACE_WITH_YOUR_NEW_CODEX_CODING_AGENT_KEY') {
            Write-Success "An existing ICA_API_KEY was found in $EnvFile."
            $Overwrite = Ask-UserApproval "Do you want to overwrite it with a new key?" $false
            if (-not $Overwrite) {
                $ApiKey = $Matches[1]
            }
        }
    }
    
    if (-not $ApiKey) {
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
    
    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        $EnvContent = "ICA_API_KEY=$ApiKey`r`n"
        [System.IO.File]::WriteAllText($EnvFile, $EnvContent, $Utf8NoBom)
        
        # Apply strict NTFS owner-only permissions
        try {
            $currentUser = $env:USERNAME
            & icacls "$EnvFile" /inheritance:r /grant:r "${currentUser}:F" | Out-Null
            Write-Success ".env file created with strict user-only permissions."
        } catch {
            Write-WarningMsg "Could not set icacls permissions on .env file: $_"
        }
        
        # Set for current PowerShell session & persistent User Environment Variable
        $env:ICA_API_KEY = $ApiKey
        try {
            [System.Environment]::SetEnvironmentVariable('ICA_API_KEY', $ApiKey, 'User')
            Write-Success "Registered ICA_API_KEY user environment variable for VS Code and GUI apps."
        } catch {}
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
Write-HeaderBox "IBM Codex + ICA Setup Completed Successfully!"

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
