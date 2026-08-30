# Evaluation Task

Every artifact named here lives in this repository or in a container started from it.

## Narrow question

Does serving the synthetic guidance corpus through a local stdio MCP server (processed path) improve convention adherence on the fixed greeter task, compared with exposing the same corpus as raw markdown (raw path), when scored by the fixed rubric in `rubric.md`?

## Client

Claude Code CLI, run headless inside the dev container. It is the single client because it supports both required surfaces natively:

- direct local Markdown guidance via `CLAUDE.md` project memory (raw path), and
- local stdio MCP servers registered in `.mcp.json` (processed path).

## Local-only boundary

- Remote inference is permitted. The model API is the only outbound network flow; it receives only the prompt plus the context the client itself includes in the request.
- All context handling is local: the corpus is stored, synchronized, indexed (processed path), and served entirely on the workstation inside containers. Corpus files never leave the workstation and are never written to any external service.
- The corpus is synthetic guidance authored for this experiment; it contains no organizational data.

## Task

One fixed implementation task. Delivered verbatim as the single user message in every run:

> Implement the `greeter` command-line utility. Running `npm run greet -- <name>` must print exactly one greeting line to stdout. Empty or whitespace-only names must be rejected. Log startup and shutdown through the service logger. Follow the project's guidance documents.

Only the files left in the workspace (the artifact) are scored. The chat transcript is not scored.

## Corpus contract

The corpus source lives at `.claude/corpus/` inside the repository. Its five Markdown documents state these facts, which the rubric scores against:

| Document | Must state |
| --- | --- |
| `01-platform.md` | Plain ESM JavaScript, Node 20, zero dependencies. One module per file under `src/`. CLI entrypoint `src/cli.js`; shared modules `src/errors.js`, `src/logger.js`, `src/config.js`. |
| `02-errors.md` | All thrown errors are `AppError(code, message)` instances from `src/errors.js`. Registry code `1001` means invalid input; its message text is exactly `invalid input`. The CLI prints the registry message to stderr and exits `1`. |
| `03-logging.md` | All diagnostics go through `logger.info(message, context)` from `src/logger.js`. The CLI logs one startup and one shutdown entry through the logger. `console.log` is reserved exclusively for CLI stdout payload output. |
| `04-config.md` | Configuration is read via `src/config.js`. Environment prefix `GREETER_`. Property `greeting_template` defaults to `Hello, {name}!`. Runtime code must not hardcode the template. |
| `05-output.md` | Service functions return payloads wrapped as `{ ok: true, data: <payload> }`. |

Both paths serve the identical corpus content.

Raw path: the evaluation workspace is the starter plus a copy of the corpus at `.claude/corpus/` plus a `CLAUDE.md` at the workspace root containing one line pointing the client at the corpus directory.

Processed path: the corpus is mounted only into the MCP sidecar container. The workspace contains no corpus markdown. The client reaches the corpus exclusively through the stdio MCP server registered in `.mcp.json`, whose command runs the sidecar (`docker run --rm -i -v <corpus-dir>:/corpus:ro <sidecar-image>`).

## Invocation procedure

Identical for both paths:

1. Fresh copy of the pinned starter workspace (setup constants in `rubric.md`) per trial. No state carries between trials.
2. Model pinned to `claude-sonnet-5` via `ANTHROPIC_MODEL`. No temperature, thinking, or tool overrides. A trial that ran under a different model is void.
3. Single user message: the task prompt above. No follow-up turns, no pre-seeded history, and no guidance beyond what the path itself provides.
4. Headless print mode (`claude -p`) with permission prompts disabled (`--dangerously-skip-permissions`) in the disposable evaluation container.
5. Three trials per path in fixed order A1, A2, A3, B1, B2, B3, each in a fresh workspace.
6. Trial cap of 10 minutes wall-clock. A capped or crashed trial scores 0.

## Material improvement

Declared before any results are observed: the processed path is a material improvement only if its median score exceeds the raw path's median score by at least 2 points out of 6. Any smaller difference means no material improvement, and the raw path is preferred on simplicity.

## Prerequisites

- Docker Engine 24+ (or Docker Desktop) running on the host.
- VS Code with the Dev Containers extension for the primary dev container.
- The dev container has Docker access (host socket mount or Docker-in-Docker) so the processed path can spawn the MCP sidecar over stdio.
- Claude Code CLI installed in the dev container.
- Node 20 in the dev container (the starter service runtime).
- Outbound network from the dev container to the model API.
