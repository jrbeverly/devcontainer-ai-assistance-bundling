FROM node:20-bookworm-slim

# Evaluation client: Claude Code CLI (npm distribution).
RUN npm install -g @anthropic-ai/claude-code

# Git is required by the client; the MCP server needs only node.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

USER node
WORKDIR /workspace
