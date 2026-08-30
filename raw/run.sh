#!/usr/bin/env bash
set -euo pipefail

# Fresh raw-path evaluation run, executed inside the auxiliary container with
# the experiment directory mounted at /workspace:
#   cd /workspace && ./raw/run.sh
# Assembles a disposable workspace (pinned starter + synchronized corpus +
# raw/CLAUDE.md) and runs the fixed task headless. The client's API credentials
# must already be in the environment. Response and invocation details are
# appended to evaluation/results.md. MODEL and TASK are the shared evaluation
# settings; the indexed run reuses them unchanged.

MODEL="claude-sonnet-5"
read -r TASK <<'EOF'
Implement the `greeter` command-line utility. Running `npm run greet -- <name>` must print exactly one greeting line to stdout. Empty or whitespace-only names must be rejected. Log startup and shutdown through the service logger. Follow the project's guidance documents.
EOF

cd "$(dirname "$0")/.."
EXP_ROOT="$PWD"

./context/sync.sh

WS="$(mktemp -d /tmp/raw-workspace.XXXXXX)"
mkdir -p "$WS/src" "$WS/.claude/corpus"

cat > "$WS/package.json" <<'EOF'
{
  "type": "module",
  "scripts": {
    "greet": "node src/cli.js"
  }
}
EOF

cat > "$WS/src/errors.js" <<'EOF'
export class AppError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}
EOF

cat > "$WS/src/logger.js" <<'EOF'
export const logger = {
  info(message, context) {
    console.error(`[info] ${message}${context ? ' ' + JSON.stringify(context) : ''}`);
  },
};
EOF

cat > "$WS/src/config.js" <<'EOF'
const env = process.env;
export const config = {
  greeting_template: env.GREETER_GREETING ?? 'Hello, {name}!',
};
EOF

cp .claude/corpus/*.md "$WS/.claude/corpus/"
cp raw/CLAUDE.md "$WS/CLAUDE.md"

cd "$WS"
set +e
ANTHROPIC_MODEL="$MODEL" claude -p --dangerously-skip-permissions "$TASK" > response.txt 2> response.err
STATUS=$?
set -e

OUT="$EXP_ROOT/evaluation/results.md"
[ -s "$OUT" ] || echo "# Evaluation results" > "$OUT"
{
  echo
  echo "## Raw baseline run"
  echo
  echo "- Executed: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "- Container: $(cat /etc/hostname)"
  echo "- Client: claude $(claude --version)"
  echo "- Model: ANTHROPIC_MODEL=$MODEL"
  echo "- Base URL: ${ANTHROPIC_BASE_URL:-unset}"
  echo "- Command: ANTHROPIC_MODEL=$MODEL claude -p --dangerously-skip-permissions <task>"
  echo "- Task prompt: $TASK"
  echo "- Exit: $STATUS"
  echo "- Workspace: $WS"
  echo
  echo "### Unedited response"
  echo
  cat response.txt
  echo
  if [ -s response.err ]; then
    echo "### Client stderr"
    echo
    cat response.err
    echo
  fi
} >> "$OUT"

exit "$STATUS"
