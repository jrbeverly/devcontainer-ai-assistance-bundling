# Evaluation Rubric

The scoring rule is fixed here. Scoring is mechanical: every point is a binary check on the artifact files, and no qualitative judgement is permitted.

## Setup constants (identical across both paths)

- Starter workspace: `package.json` with `"type": "module"` and script `greet` → `node src/cli.js`; `src/errors.js` (`AppError(code, message)`, code `1001` = invalid input); `src/logger.js` (`logger.info(message, context?)`); `src/config.js` (property `greeting_template` read from `GREETER_GREETING`, default `Hello, {name}!`). `src/` contains nothing else.
- No environment variables set in trials (`GREETER_*` unset), so the default template applies.
- Corpus: the five documents fixed by the contract in `task.md`, identical content on both paths.
- Prompt: verbatim from `task.md`.
- Model `claude-sonnet-5`; one user message; no follow-ups; three trials per path; 10-minute trial cap.
- The same dev container image and the same sidecar image for every trial.

## Gate (not scored)

`npm run greet -- Ada` exits 0 and prints exactly one line: `Hello, Ada!` (trailing newline allowed). An artifact that fails the gate scores 0 for that trial.

## Points

Flat scoring: 1 point each, no weights, no partial credit.

1. Layout — `src/greeter.js` exists (`01-platform.md`).
2. Envelope — the greeting path returns `{ ok: true, data: <greeting> }` (`05-output.md`).
3. Error convention — the validation path throws `AppError` with code `1001` for empty or whitespace-only names (`02-errors.md`).
4. Logging convention — `src/cli.js` contains at least two `logger.info(...)` calls (startup and shutdown); `console.log` appears nowhere outside `src/cli.js` (`03-logging.md`).
5. Config convention — `src/greeter.js` and `src/cli.js` contain no greeting string literal (grep for `Hello` finds nothing) and take the template from `src/config.js` via `greeting_template` (`04-config.md`).
6. CLI error surface — `npm run greet -- ' '` exits with code 1 and prints exactly `invalid input` to stderr (`02-errors.md`).

## Procedure

1. Run the gate, then checks 1-6 in the stated order, on each artifact.
2. Score each check 0 or 1 exactly as written. No interpretation of intent, no partial credit.
3. Score all six artifacts in fixed order A1, A2, A3, B1, B2, B3 before comparing paths.
4. Record one row per trial in `evaluation/results.md`: path, trial, gate (pass/fail), points 1-6 (0/1 each), total (0-6).
5. Compare medians: processed median minus raw median. A difference of at least 2 points is material, as declared in advance in `task.md`.
