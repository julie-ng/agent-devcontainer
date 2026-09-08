# julieio/agent-devcontainer:frontend
#
# Frontend variant of agent-devcontainer — adds a headless Chromium for
# screenshotting/inspecting UIs. Separate image, not a stage in the main
# Dockerfile, so the base image stays small for projects that don't need it.
#
# Notes:
#   - No devcontainer feature installs a usable browser: chromium-checkout
#     only fetches source, and playwright's installChromium downloads Chrome
#     for Testing to ~/.cache/ms-playwright, which has no linux-arm64 build.
#     Hence a plain apt install of Debian's (arm64-native) chromium below.
#   - Debian's apt chromium is arm64-native, unlike Puppeteer's own Chrome for
#     Testing download, which ships no linux-arm64 build (this is why
#     mermaid-cli's bundled browser never rendered on arm64 — see Dockerfile).
#   - BASE_IMAGE defaults to the published tag; override to a locally built
#     tag (e.g. julieio/agent-devcontainer:test) to verify before publishing.

ARG BASE_IMAGE=julieio/agent-devcontainer:latest
FROM ${BASE_IMAGE}

RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
        chromium \
        fonts-liberation \
        fonts-noto-color-emoji \
    && sudo rm -rf /var/lib/apt/lists/*

# @playwright/mcp — lets a coding agent drive a browser to check/screenshot
# frontends. Playwright ignores PUPPETEER_EXECUTABLE_PATH (that's Puppeteer-
# only, confirmed by testing) and has no env var for a custom browser path,
# so the system chromium must be passed explicitly: MCP server args need
# `--executable-path /usr/bin/chromium --browser chromium`.
RUN npm install -g @playwright/mcp

# CHROME_BIN: some tools read this directly for a system browser.
# PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD: stops Playwright fetching its own
# Chromium, which has no linux-arm64 build anyway (same gap as Puppeteer's).
ENV CHROME_BIN=/usr/bin/chromium \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

# ---- Sanity check at build time --------------------------------------------
# Two checks, not one: chromium --headless --screenshot proves the browser
# renders at all, and the playwright-core launch proves @playwright/mcp's
# actual code path (explicit executablePath, no env var) also works. A
# passing `chromium --version` alone wouldn't catch either failure mode —
# the same blind spot that hid mermaid-cli's arm64 breakage in the base
# image's own check.
RUN echo '<h1>ok</h1>' > /tmp/t.html && \
    chromium --headless --no-sandbox --disable-gpu \
        --screenshot=/tmp/t.png --window-size=200,100 file:///tmp/t.html && \
    test -s /tmp/t.png && \
    node -e "require('$(npm root -g)/@playwright/mcp/node_modules/playwright-core').chromium.launch({headless:true,executablePath:'/usr/bin/chromium',args:['--no-sandbox']}).then(b=>b.close())" && \
    rm -f /tmp/t.html /tmp/t.png
