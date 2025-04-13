# Memory System

## Overview
The memory system manages framework state, configuration, and context across different scopes and lifetimes.

## Directory Structure
```
memory/
├── README.md           # This file
├── STRUCTURE.md        # Memory system architecture
├── OPERATIONS.md       # Memory operations guide
├── REFERENCES.md       # Reference system spec
├── RECOVERY.md         # Recovery procedures
├── core/              # Framework memories
│   ├── state.json     # Framework state
│   ├── config.json    # Framework config
│   └── rules.json     # Framework rules
├── project/           # Project memories
│   └── context/       # Project context
└── session/           # Session memories
    └── active.json    # Current session
```

## Implementation Files

### STRUCTURE.md
Defines the memory system architecture including:
- Directory organization
- File formats
- Memory categories
- Storage patterns
- Access rules

### OPERATIONS.md
Documents memory operations:
- Read operations
- Write operations
- State operations
- Operation rules
- Error handling
- Usage patterns

### REFERENCES.md
Specifies the reference system:
- Reference types
- Validation rules
- Usage patterns
- Error handling
- Recovery procedures

### RECOVERY.md
Details recovery procedures:
- Recovery types
- Automatic recovery
- Manual procedures
- Prevention measures
- Recovery tools
- Implementation notes

## Memory Categories

### Core Memories
Location: `core/`
Purpose: Framework configuration and state
Files:
- `state.json`: Current framework state
- `config.json`: Framework configuration
- `rules.json`: Framework rules and patterns

### Project Memories
Location: `project/`
Purpose: Project-specific information
Files:
- `context/project.json`: Project context and state

### Session Memories
Location: `session/`
Purpose: Active session tracking
Files:
- `active.json`: Current session state

### User Memories
Location: `user/`
Purpose: User preferences and settings
Files:
- `settings.json`: User configuration

## Usage

### Reading Memory
1. Check README.md for structure
2. Reference OPERATIONS.md for patterns
3. Follow REFERENCES.md for linking
4. Use RECOVERY.md if needed

### Writing Memory
1. Follow STRUCTURE.md patterns
2. Use OPERATIONS.md guidelines
3. Validate with REFERENCES.md
4. Ensure RECOVERY.md compliance

### Recovery
1. Check RECOVERY.md procedures
2. Follow documented steps
3. Use provided tools
4. Verify system state

## Implementation Notes
1. Keep memories organized by category
2. Follow defined patterns
3. Maintain proper references
4. Handle errors gracefully
5. Document all changes
6. Test recovery procedures
