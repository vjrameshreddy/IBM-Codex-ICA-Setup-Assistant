# ==============================================================================
# IBM Codex + ICA (IBM Consulting Advantage) Automated Setup Script for Windows
# ==============================================================================
[CmdletBinding()]
param(
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

Clear-Host
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "     IBM Codex + IBM Consulting Advantage (ICA) Setup Tool     " -ForegroundColor White
Write-Host "                      Windows Edition                          " -ForegroundColor DarkCyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Environment & Path Setup
$CodexDir = Join-Path $HOME ".codex"
$ModelCatalogDir = Join-Path $CodexDir "model-catalog"
$CatalogJsonFile = Join-Path $ModelCatalogDir "ica-models.json"
$ConfigFile = Join-Path $CodexDir "config.toml"
$EnvFile = Join-Path $CodexDir ".env"
$TestDir = Join-Path $HOME "codex-ica-test"

# 2. Check Prerequisites
Write-Step "Checking prerequisites..."

$Prereqs = @{
    "Node.js" = "node -v"
    "npm"     = "npm -v"
    "Git"     = "git --version"
    "Python"  = "python --version"
    "VS Code" = "code --version"
}

$MissingTools = @()

foreach ($Tool in $Prereqs.Keys) {
    try {
        $cmd = $Prereqs[$Tool]
        $output = Invoke-Expression $cmd 2>$null
        if ($LASTEXITCODE -eq 0 -and $output) {
            Write-Success "$Tool found: $output"
        } else {
            Write-WarningMsg "$Tool not found or not in PATH."
            $MissingTools += $Tool
        }
    } catch {
        Write-WarningMsg "$Tool is missing."
        $MissingTools += $Tool
    }
}

# Check Codex CLI specifically
$CodexInstalled = $false
try {
    $codexVer = Invoke-Expression "codex --version" 2>$null
    if ($LASTEXITCODE -eq 0 -and $codexVer) {
        Write-Success "Codex CLI found: $codexVer"
        $CodexInstalled = $true
    }
} catch {}

if (-not $CodexInstalled) {
    Write-WarningMsg "Codex CLI (@openai/codex) is not installed."
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $InstallCodex = "Y"
        if (-not $NonInteractive) {
            $InstallCodex = Read-Host "Would you like to install Codex CLI globally now via npm? (Y/n)"
        }
        if ($InstallCodex -ne "n" -and $InstallCodex -ne "N") {
            Write-Host "Installing @openai/codex globally..." -ForegroundColor Gray
            npm install -g @openai/codex
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Codex CLI installed successfully."
                $CodexInstalled = $true
            } else {
                Write-ErrorMsg "Failed to install Codex CLI. You may need to run PowerShell as normal user and ensure npm is configured."
            }
        }
    }
}

# 3. Create .codex and model-catalog folders
Write-Step "Creating configuration directories..."
if (-not (Test-Path $ModelCatalogDir)) {
    New-Item -ItemType Directory -Force -Path $ModelCatalogDir | Out-Null
}
Write-Success "Directory verified: $ModelCatalogDir"

if (-not (Test-Path $TestDir)) {
    New-Item -ItemType Directory -Force -Path $TestDir | Out-Null
}
Write-Success "Test directory verified: $TestDir"

# 4. Generate ica-models.json
Write-Step "Writing ICA Model Catalog (ica-models.json)..."

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

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($CatalogJsonFile, $ModelCatalogContent, $Utf8NoBom)

# Validate JSON
try {
    $null = Get-Content $CatalogJsonFile -Raw | ConvertFrom-Json
    Write-Success "ica-models.json created and validated successfully."
} catch {
    Write-ErrorMsg "Failed to parse generated ica-models.json: $_"
}

# 5. Configure config.toml
Write-Step "Configuring config.toml..."

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

if (Test-Path $ConfigFile) {
    Write-Host "Existing config.toml found. Merging configuration..." -ForegroundColor Gray
    $ExistingLines = Get-Content $ConfigFile
    
    # Filter out existing top-level ICA keys and old provider section to cleanly update
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
        
        if ($InIcaSection) {
            continue
        }
        
        if ($trimmed -match '^(model|model_provider|model_catalog_json|model_reasoning_effort)\s*=') {
            continue
        }
        
        $FilteredLines += $Line
    }
    
    # Reassemble: Top-level settings first, then remaining lines, then [model_providers.ica]
    $NewContent = "$TopLevelSettings`r`n`r`n" + ($FilteredLines -join "`r`n") + "`r`n`r`n$ProviderSection`r`n"
    [System.IO.File]::WriteAllText($ConfigFile, $NewContent, $Utf8NoBom)
} else {
    $NewContent = "$TopLevelSettings`r`n`r`n$ProviderSection`r`n"
    [System.IO.File]::WriteAllText($ConfigFile, $NewContent, $Utf8NoBom)
}

Write-Success "config.toml updated with ICA model provider and catalog path."

# 6. Secure API Key Configuration
Write-Step "Configuring ICA API Key (.env)..."

if ($SkipKeyPrompt) {
    Write-WarningMsg "Skipping API key prompt as requested."
} else {
    $ApiKey = $null
    
    if (Test-Path $EnvFile) {
        $ExistingEnv = Get-Content $EnvFile -Raw -ErrorAction SilentlyContinue
        if ($ExistingEnv -match 'ICA_API_KEY=\s*(\S+)' -and $Matches[1] -ne 'REPLACE_WITH_YOUR_NEW_CODEX_CODING_AGENT_KEY') {
            Write-Success "An existing ICA_API_KEY was found in .env."
            $UpdateKey = Read-Host "Do you want to overwrite it with a new key? (y/N)"
            if ($UpdateKey -ne "y" -and $UpdateKey -ne "Y") {
                $ApiKey = $Matches[1]
            }
        }
    }
    
    if (-not $ApiKey) {
        Write-Host "To obtain your Coding Agent API key:" -ForegroundColor Cyan
        Write-Host " 1. Sign in to https://servicesessentials.ibm.com/" -ForegroundColor Gray
        Write-Host " 2. Select/Create your 2.0 team (e.g., '<YourName> Codex Training')" -ForegroundColor Gray
        Write-Host " 3. Navigate to Settings > API Keys > Coding Agents > Generate Coding Agent API Key" -ForegroundColor Gray
        Write-Host " 4. Copy the key specifically from the 'Codex' row (NOT general ICA key)" -ForegroundColor Gray
        Write-Host ""
        
        $SecureString = Read-Host "Paste your Codex Coding Agent API Key (input will be hidden)" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        $ApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
    
    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        $EnvContent = "ICA_API_KEY=$ApiKey`r`n"
        [System.IO.File]::WriteAllText($EnvFile, $EnvContent, $Utf8NoBom)
        
        # Apply strict file permissions (icacls)
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

        # Terminate any stale background daemon server so it restarts fresh with the new key
        try {
            Get-Process -Name 'codex', 'node_repl' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Success "Stopped existing background Codex daemon processes to refresh environment."
        } catch {}
    } else {
        Write-WarningMsg "No API key was entered. You will need to manually edit $EnvFile later."
    }
}

# 7. Final Summary and Verification Instructions
Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host "           IBM Codex + ICA Setup Completed Successfully!         " -ForegroundColor White
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "`nConfiguration files created:" -ForegroundColor Cyan
Write-Host " - Model Catalog:  $CatalogJsonFile" -ForegroundColor Gray
Write-Host " - Codex Config:   $ConfigFile" -ForegroundColor Gray
Write-Host " - API Key (.env): $EnvFile" -ForegroundColor Gray
Write-Host " - Test Directory: $TestDir" -ForegroundColor Gray

Write-Host "`nNext Steps to Verify:" -ForegroundColor Yellow
Write-Host " 1. RELOAD ENVIRONMENT in this current PowerShell window (run this command):" -ForegroundColor White
Write-Host "      `$env:ICA_API_KEY = [System.Environment]::GetEnvironmentVariable('ICA_API_KEY', 'User')" -ForegroundColor Cyan
Write-Host "    (Or close and open a brand NEW PowerShell window so it loads automatically)" -ForegroundColor Gray
Write-Host " 2. Open terminal in test folder and run Codex CLI:" -ForegroundColor White
Write-Host "      cd `"$TestDir`"" -ForegroundColor Cyan
Write-Host "      codex" -ForegroundColor Cyan
Write-Host "    Inside Codex, check status by typing:" -ForegroundColor White
Write-Host "      /status" -ForegroundColor Cyan
Write-Host "    (It should display: provider: ica, model: gpt-advantage-assist)" -ForegroundColor Gray
Write-Host " 3. For VS Code:" -ForegroundColor White
Write-Host "    - Install 'Codex - OpenAI''s coding agent' (OpenAI.chatgpt) extension." -ForegroundColor Gray
Write-Host "    - Open the test folder: `"$TestDir`" and Trust it." -ForegroundColor Gray
Write-Host "    - Use the Codex tab to send a test message." -ForegroundColor Gray
Write-Host "=================================================================`n" -ForegroundColor Green
