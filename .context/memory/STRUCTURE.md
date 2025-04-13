# Memory System Structure

## Overview
The memory system maintains state across sessions using a hierarchical file structure.

## Directory Layout
```
memory/
├── core/              # Framework core memories
│   ├── state.json    # Framework state
│   ├── config.json   # Framework configuration
│   └── rules.json    # Framework rules
├── project/          # Project-specific memories
│   └── context/      # Project context and metadata
└── session/          # Session state
    ├── active.json   # Active session state
    └── history/      # Session history
```

## File Formats

### JSON Schema
All memory files use JSON format with the following base schema:
```json
{
  "type": "memory",
  "category": "<core|project|session|user>",
  "id": "unique-identifier",
  "created": "ISO-8601-date",
  "updated": "ISO-8601-date",
  "content": {
    // Memory-specific content
  }
}
```

### Memory Categories

#### Core Memories
- Immutable framework rules
- Configuration settings
- State tracking
- Operation patterns

#### Project Memories
- Project context and metadata
- Project state tracking
- Project configuration
- Dependencies

#### Session Memories
- Active session state
- Command history
- Recent changes
- Temporary data

## Usage Rules

### Memory Operations
1. Read Operations
   - Always validate schema
   - Check memory category
   - Verify permissions

2. Write Operations
   - Follow schema exactly
   - Update timestamps
   - Maintain history
   - Validate content

3. Update Operations
   - Preserve existing fields
   - Track changes
   - Update references
   - Maintain consistency

### Access Patterns
1. Core Access
   - Read-only for most operations
   - Updates through framework only
   - Version controlled

2. Project Access
   - Read-write during sessions
   - History preserved
   - References maintained

3. Session Access
   - Active session read-write
   - History append-only
   - Cleanup on completion

## Implementation Notes
1. Use atomic operations
2. Maintain backups
3. Handle conflicts
4. Validate references
5. Track dependencies
