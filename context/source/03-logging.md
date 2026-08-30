# Logging

All diagnostics go through `logger.info(message, context)` from `src/logger.js`.

- The CLI logs one startup and one shutdown entry through the logger.
- `console.log` is reserved exclusively for CLI stdout payload output.
