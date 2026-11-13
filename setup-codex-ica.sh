#!/usr/bin/env bash
# ==============================================================================
# IBM Codex + ICA (IBM Consulting Advantage) Automated Setup Script for macOS / Linux
# ==============================================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=================================================================${NC}"
echo -e "${CYAN}     IBM Codex + IBM Consulting Advantage (ICA) Setup Tool     ${NC}"
echo -e "${CYAN}                      macOS / Linux Edition                    ${NC}"
echo -e "${CYAN}=================================================================${NC}"

CODEX_DIR="$HOME/.codex"
MODEL_CATALOG_DIR="$CODEX_DIR/model-catalog"
CATALOG_JSON_FILE="$MODEL_CATALOG_DIR/ica-models.json"
CONFIG_FILE="$CODEX_DIR/config.toml"
ENV_FILE="$CODEX_DIR/.env"
TEST_DIR="$HOME/codex-ica-test"

# 1. Check Prerequisites
echo -e "\n${CYAN}[+] Checking prerequisites...${NC}"
check_cmd() {
    local name="$1"
    local cmd="$2"
    if command -v $cmd >/dev/null 2>&1; then
        local ver=$($cmd --version 2>/dev/null || $cmd -v 2>/dev/null || echo "installed")
        echo -e " ${GREEN}[OK]${NC} $name found: $ver"
    else
        echo -e " ${YELLOW}[WARN]${NC} $name is missing or not in PATH."
    fi
}

check_cmd "Node.js" "node"
check_cmd "npm" "npm"
check_cmd "Git" "git"
check_cmd "Python 3" "python3"
check_cmd "VS Code" "code"
check_cmd "Codex CLI" "codex"

# 2. Fix npm global permissions if on macOS and needed
if command -v npm >/dev/null 2>&1; then
    NPM_PREFIX=$(npm config get prefix)
    if [[ "$NPM_PREFIX" == "/usr/local" || "$NPM_PREFIX" == "/usr" ]]; then
        echo -e "\n${CYAN}[+] Configuring npm user prefix to ~/.npm-global to prevent permission errors...${NC}"
        mkdir -p "$HOME/.npm-global"
        npm config set prefix "$HOME/.npm-global"
        
        # Add to zshrc if not already present
        if [[ -f "$HOME/.zshrc" ]]; then
            if ! grep -q 'npm-global/bin' "$HOME/.zshrc"; then
                echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.zshrc"
                echo -e " ${GREEN}[OK]${NC} Added ~/.npm-global/bin to ~/.zshrc"
            fi
        fi
        export PATH="$HOME/.npm-global/bin:$PATH"
    fi
fi

# Check if Codex needs installation
if ! command -v codex >/dev/null 2>&1; then
    if command -v npm >/dev/null 2>&1; then
        echo -e "\n${YELLOW}[!] Codex CLI is not installed.${NC}"
        read -p "Would you like to install Codex CLI (@openai/codex) globally now? (Y/n): " install_codex
        if [[ "$install_codex" != "n" && "$install_codex" != "N" ]]; then
            echo "Running: npm install -g @openai/codex"
            npm install -g @openai/codex
            export PATH="$(npm config get prefix)/bin:$PATH"
        fi
    fi
fi

# 3. Create Directories
echo -e "\n${CYAN}[+] Creating configuration directories...${NC}"
mkdir -p "$MODEL_CATALOG_DIR"
mkdir -p "$TEST_DIR"
echo -e " ${GREEN}[OK]${NC} Verified directory: $MODEL_CATALOG_DIR"
echo -e " ${GREEN}[OK]${NC} Verified directory: $TEST_DIR"

# 4. Write ica-models.json
echo -e "\n${CYAN}[+] Writing ICA Model Catalog (ica-models.json)...${NC}"
cat << 'EOF' > "$CATALOG_JSON_FILE"
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
EOF

if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$CATALOG_JSON_FILE" >/dev/null && echo -e " ${GREEN}[OK]${NC} ica-models.json is valid JSON."
fi

# 5. Configure config.toml
echo -e "\n${CYAN}[+] Configuring config.toml...${NC}"

TOP_SETTINGS="model = \"gpt-advantage-assist\"\nmodel_provider = \"ica\"\nmodel_catalog_json = \"$CATALOG_JSON_FILE\"\nmodel_reasoning_effort = \"medium\""
PROVIDER_SECTION="[model_providers.ica]\nname = \"ICA\"\nbase_url = \"https://api.servicesessentials.ibm.com/v1\"\nwire_api = \"responses\"\nenv_key = \"ICA_API_KEY\"\nrequires_openai_auth = false"

if [[ -f "$CONFIG_FILE" ]]; then
    echo "Existing config.toml found. Merging configuration..."
    # Filter out existing top-level keys
    grep -v -E '^(model|model_provider|model_catalog_json|model_reasoning_effort)[[:space:]]*=' "$CONFIG_FILE" | \
    awk '/^\[model_providers\.ica\]/{flag=1;next}/^\[/{flag=0} !flag' > "$CONFIG_FILE.tmp" || true
    
    printf "%b\n\n" "$TOP_SETTINGS" > "$CONFIG_FILE"
    cat "$CONFIG_FILE.tmp" >> "$CONFIG_FILE"
    printf "\n%b\n" "$PROVIDER_SECTION" >> "$CONFIG_FILE"
    rm -f "$CONFIG_FILE.tmp"
else
    printf "%b\n\n%b\n" "$TOP_SETTINGS" "$PROVIDER_SECTION" > "$CONFIG_FILE"
fi

echo -e " ${GREEN}[OK]${NC} config.toml successfully written."

# 6. Configure API Key
echo -e "\n${CYAN}[+] Configuring ICA API Key (.env)...${NC}"
api_key=""
if [[ -f "$ENV_FILE" ]]; then
    existing_key=$(grep -E '^ICA_API_KEY=' "$ENV_FILE" | cut -d '=' -f2- || true)
    if [[ -n "$existing_key" && "$existing_key" != "REPLACE_WITH_YOUR_NEW_CODEX_CODING_AGENT_KEY" ]]; then
        echo -e " ${GREEN}[OK]${NC} Existing ICA_API_KEY found in $ENV_FILE."
        read -p "Do you want to overwrite it with a new key? (y/N): " overwrite_key
        if [[ "$overwrite_key" == "y" || "$overwrite_key" == "Y" ]]; then
            api_key=""
        else
            api_key="$existing_key"
        fi
    fi
fi

if [[ -z "$api_key" ]]; then
    echo -e "${YELLOW}To obtain your key:${NC}"
    echo " 1. Sign in to https://servicesessentials.ibm.com/"
    echo " 2. Select/Create your 2.0 team"
    echo " 3. Settings > API Keys > Coding Agents > Generate Coding Agent API Key"
    echo " 4. Copy the key in the Codex row."
    echo ""
    read -s -p "Paste your Codex Coding Agent API Key (input will not show): " api_key
    echo ""
fi

if [[ -n "$api_key" ]]; then
    echo "ICA_API_KEY=$api_key" > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo -e " ${GREEN}[OK]${NC} Saved API key to $ENV_FILE with chmod 600 permissions."
else
    echo -e " ${YELLOW}[WARN]${NC} No API key entered. You can add it manually to $ENV_FILE."
fi

# 7. Summary
echo -e "\n${GREEN}=================================================================${NC}"
echo -e "${GREEN}           IBM Codex + ICA Setup Completed Successfully!         ${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo -e "Configuration files:"
echo " - Model Catalog:  $CATALOG_JSON_FILE"
echo " - Codex Config:   $CONFIG_FILE"
echo " - API Key:        $ENV_FILE"
echo " - Test Directory: $TEST_DIR"
echo ""
echo -e "${YELLOW}Next Steps to Verify:${NC}"
echo " 1. Restart your terminal session or run: source ~/.zshrc"
echo " 2. cd \"$TEST_DIR\" && codex"
echo " 3. Inside Codex, verify with: /status"
echo -e "${GREEN}=================================================================${NC}\n"
