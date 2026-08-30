# Errors

All thrown errors are `AppError(code, message)` instances from `src/errors.js`.

- Registry code `1001` means invalid input.
- The message text for code `1001` is exactly `invalid input`.
- The CLI prints the registry message to stderr and exits `1`.
