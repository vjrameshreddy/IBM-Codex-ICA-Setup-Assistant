# Project Documentation Rules (Non-Obvious Only)

- **Official Upstream Guide**: Based on `IBM_Codex_ICA_Getting_Started_Guide.docx`. Any architectural deviation must reference sections in this document.
- **ICA 2.0 vs 1.0**: The API key required is the dedicated **Codex Coding Agent API Key** from Essentials Portal (`https://servicesessentials.ibm.com/` > Team > Settings > API Keys > Coding Agents > Codex row). A general ICA workspace API key will fail authentication on the responses API endpoint.
- **ChatGPT Account Boundary**: Logging into ChatGPT with an `@ibm.com` address does NOT route requests to ICA. Authentication is governed strictly by the `ICA_API_KEY` header and `https://api.servicesessentials.ibm.com/v1` base URL.
- **Zero-Dependency UI**: `index.html` is an offline-first single page app. Do not introduce CDN references (Google Fonts, unpkg, cdnjs) or external stylesheet links as it must render in air-gapped enterprise environments.
- **Progress Counter Architecture**: In `index.html`, progress percentage calculation evaluates all elements matching `.step-check`. The 5 numbered steps map 1:1 to `check-prereqs`, `check-portal`, `check-manual`, `check-clients`, and `check-testing`.
- **Repeated IBM Banner**: The "IBM Enterprise Workstation Requirement (PC@IBM / Mac@IBM)" callout appears in the Fast-Track, Step 1, and Step 4 tabs of `index.html`; `README.md` and `RELEASE_NOTES.md` only mention it in text.
