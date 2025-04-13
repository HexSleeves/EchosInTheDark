# Aegis Framework

This directory contains the core Aegis framework implementation. Each subdirectory serves a specific purpose in maintaining project state and managing operations.

## Directory Structure

### ai/
Contains AI assistant operations and patterns:
- `operations/`: Operation patterns and command implementation YAML files

### memory/
Stores framework and project memory in a structured, file-based system:
- `core/`: Framework knowledge and operation patterns
- `project/`: Project-specific memory and state
  - `context/`: Project context data
  - `self_improvement.json`: Self-improvement metrics and recommendations
- `session/`: Temporary session state and context
- Documentation files:
  - `SELF_IMPROVEMENT.md`: Documentation for the self-improvement system
  - `STRUCTURE.md`, `REFERENCES.md`, `STATE_TRACKING.md`, etc.

### templates/
Contains document templates for maintaining consistency:
- `tasks/`: Task definition templates
- `sessions/`: Session record templates
- `decisions/`: Decision record templates

### plan/
Stores planning documents and resources:
- `planning_document.md`: Current project plan

### tasks/
Manages tasks through their lifecycle:
- `planned/`: Tasks ready for implementation
- `active/`: Tasks currently in progress
- `hold/`: Tasks waiting on dependencies
- `completed/`: Finished tasks

### sessions/
Stores session records and progress:
- Files named by date: `YYYY-MM-DD.md`

### decisions/
Stores important decision records:
- Files named by ID: `DECISION-XXX.md`

## Key Files
- `AI_INSTRUCTIONS.md`: Comprehensive framework instructions for the AI assistant

## TDD Integration
The framework now supports Test-Driven Development with:
- Test Status tracking in task documents
- Conditional task completion based on test status
- Support for test statuses: Not Started, Failing, Passing, Not Applicable

## Usage
1. Copy this `.context` directory to your project root
2. Initialize with `/aegis start`
3. Begin with `/aegis plan`
