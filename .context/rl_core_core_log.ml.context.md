# Purpose

Provides logging utilities for the core subsystem. Ensures all logging in the core modules is consistent and centralized.

# Key Functions/Types

- **src**: Logging source for the core subsystem.
- **module Log**: Main logging module for error, warning, info, and debug levels.
- **err / warn / info / debug**: Logging functions for different log levels.
- **make_logger**: Creates a per-file/module logger with a custom source name.

# Notable Implementation Details

- Uses the `Logs` library for structured logging.
- Supports per-module loggers for granular log control.
- Centralizes logging setup to promote consistency across the core subsystem.
