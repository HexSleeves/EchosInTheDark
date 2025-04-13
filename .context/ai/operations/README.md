# Operation Patterns

## Overview
This directory contains the operation patterns for all framework commands. These patterns define how the framework processes commands through text-based operations.

## Command Processing
Commands are processed entirely through text operations:
1. File system operations (mv, cp)
2. Content updates (front matter)
3. State tracking (memory system)
4. Template usage

## Directory Contents
```
operations/
├── README.md            # This file
├── plan.yaml            # Planning operations
├── start.yaml           # Session start
├── save.yaml            # Progress saving
├── status.yaml          # Status checking
├── task.yaml            # Task management
├── task_creation.yaml   # Task creation operations
├── task_transition.yaml # Task state transition operations
├── context.yaml         # Context refresh
├── reconcile.yaml       # State reconciliation
├── validation.yaml      # Validation patterns
└── help.yaml            # Help system
```

## Operation Pattern Structure
Each YAML file defines:
1. Command inputs and options
2. Required validations
3. Step-by-step process
4. Error handling
5. Recovery procedures
6. Command templates with required components

### Example Pattern (plan.yaml)
```yaml
name: plan
description: Creates/updates planning document
input:
  type: command
  pattern: /aegis plan
steps:
  - validate framework
  - check permissions
  - process planning
  - create tasks
```

## Command Templates
Each operation YAML file includes a `command_template` section that defines:

1. **Required Components** for each execution phase:
   - Pre-execution: Validation and context loading
   - Execution: Core command functionality
   - Post-execution: Verification and reporting
   - Error handling: Error detection and resolution

2. **Component Definition** for each required component:
   - Description of the component's purpose
   - Validation rules for the component
   - Step-by-step implementation instructions

3. **Implementation Examples** showing:
   - How to implement each command correctly
   - How to handle common scenarios
   - How to validate and verify the implementation
   - How to handle errors and edge cases

### Example Command Template Structure
```yaml
command_template:
  name: command_name
  description: "Template for implementing the command"
  version: 1.0
  
  required_components:
    pre_execution:
      - component_name:
          description: "Component description"
          validation:
            - validation_rule: "Rule description"
          implementation: |
            1. Step one
            2. Step two
            3. Step three
    
    execution:
      # Execution components
    
    post_execution:
      # Post-execution components
    
    error_handling:
      # Error handling components
  
  implementation_example: |
    # Example implementation
```

## Validation Patterns
The `validation.yaml` file contains validation patterns for:

1. **Framework Validation**: Ensuring the framework structure is valid
2. **Task Validation**: Validating task states and transitions
3. **Session Validation**: Validating session states and content
4. **Project Validation**: Validating project context and state
5. **Self-Improvement Validation**: Validating self-improvement data
6. **Command Validation**: Ensuring complete and correct command implementation

Command validation patterns define validation steps for:
- Pre-execution validation
- Execution validation
- Post-execution validation
- Completion validation

## Usage Rules
1. All operations must:
   - Follow YAML format
   - Include all sections
   - Define error handling
   - Specify recovery
   - Include command templates

2. Text Operations:
   - Use mv for file transitions
   - Update front matter for state
   - Follow template rules
   - Maintain references

3. State Management:
   - Track in memory system
   - Update consistently
   - Validate changes
   - Handle errors

## Command Flow
1. Pre-Operation:
   - Validate framework
   - Check permissions
   - Load context
   - Validate command inputs

2. Operation:
   - Follow YAML steps
   - Update state
   - Move files
   - Track changes
   - Create required artifacts

3. Post-Operation:
   - Verify changes
   - Update memory
   - Handle errors
   - Clean up
   - Validate completion

## Error Handling
1. Framework Errors:
   - Invalid structure
   - Missing files
   - Permission issues

2. Operation Errors:
   - Invalid state
   - Missing dependencies
   - Reference errors
   - Incomplete implementation

3. Recovery:
   - Follow YAML procedures
   - Maintain consistency
   - Log issues
   - Guide resolution
   - Apply recovery strategies

## Implementation Notes
1. Keep operations atomic
2. Validate all changes
3. Maintain consistency
4. Follow patterns exactly
5. Document changes
6. Test thoroughly
7. Follow command templates
8. Implement all required components
9. Verify implementation against templates

## Command Implementation Fail-Safes
To ensure complete and correct implementation of commands, the framework includes:

1. **Command Checklists**: Detailed checklists for each command in AI_INSTRUCTIONS.md
2. **Command Validation Patterns**: Validation patterns in validation.yaml
3. **Command Templates**: Required components and implementation instructions
4. **Error Prevention Instructions**: Common failure points and prevention strategies
5. **Recovery Procedures**: Steps to recover from incomplete implementations

These fail-safe mechanisms help prevent incomplete command implementations and ensure the integrity of the framework's memory system.

## References
- See memory/STRUCTURE.md for memory system
- See templates/README.md for templates
- See tasks/README.md for task management
- See AI_INSTRUCTIONS.md for framework rules and command checklists
- See validation.yaml for validation patterns
