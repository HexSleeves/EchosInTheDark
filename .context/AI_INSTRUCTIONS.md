# Aegis Framework Instructions

## Overview
Comprehensive implementation guide for the Aegis framework, containing detailed patterns, rules, and workflows. For quick command reference, see `COMMANDS.md`.

## Command Execution Rules
> CRITICAL: These rules must be followed for all command operations

1. **Command Interpretation**
   - `/aegis` commands are NEVER executed directly in the terminal
   - These commands are interpreted by the AI assistant, not the shell
   - The AI should gather information from project files and present it to the user
   - NEVER use `run_terminal_cmd` to execute any `/aegis` command

2. **Information Gathering**
   - Use file reading and search tools to gather information
   - Process and organize information according to command requirements
   - Present information in a structured, readable format
   - Do not attempt to execute framework commands as shell commands

3. **Command vs. Shell Distinction**
   - `/aegis status` → AI interprets and presents project status
   - `/aegis plan` → AI helps with planning, doesn't run a shell command
   - `/aegis task` → AI manages task information, doesn't execute in terminal
   - All other `/aegis` commands follow the same pattern

## Command Implementation Patterns
> See individual patterns in .context/ai/operations/*.yaml

### Pre-Operation Checks
1. **Framework Validation**
   - Directory structure exists
   - Required files present
   - Permissions correct
   - References valid

2. **Task State Validation**
   - Current state valid
   - Target state allowed
   - Dependencies met
   - Progress tracked
   - Test status appropriate

3. **Memory Validation**
   - Front matter valid
   - References exist
   - Types compatible
   - Content complete

### Post-Operation Checks
1. **State Verification**
   - Changes applied
   - State consistent
   - References updated
   - History recorded

### Command Implementation Checklists
> CRITICAL: These checklists MUST be followed for each command

#### `/aegis save` Checklist
- [ ] Update session document (status, progress, timestamps)
- [ ] Create decision record for significant decisions
- [ ] Update self-improvement record with new insights
- [ ] Update task progress and status
- [ ] Update project.json with current task lists
- [ ] Update timestamps to current time
- [ ] Verify all files have been properly updated
- [ ] Confirm completion only when ALL steps are checked

#### `/aegis start` Checklist
- [ ] Check if there's already an active session
- [ ] Create a new session document
- [ ] Set the initial focus for the session
- [ ] Load recommendations from self-improvement
- [ ] Update session memory with new session
- [ ] Update project.json with current task lists
- [ ] Update timestamps to current time
- [ ] Verify all files have been properly updated
- [ ] Confirm completion only when ALL steps are checked

#### `/aegis task` Checklist
- [ ] Identify the task operation (create, update, transition)
- [ ] Validate the current task state
- [ ] Perform the requested task operation
- [ ] Update the task document
- [ ] Verify test status when completing a task
- [ ] Prompt for confirmation if test status is not "Passing" or "Not Applicable"
- [ ] Update project.json with task changes
- [ ] Update timestamps to current time
- [ ] Verify all files have been properly updated
- [ ] Confirm completion only when ALL steps are checked

#### `/aegis status` Checklist
- [ ] Load project context
- [ ] Load active tasks
- [ ] Load recent changes
- [ ] Generate status report
- [ ] Include active tasks in report
- [ ] Include recent changes in report
- [ ] Include self-improvement insights in report
- [ ] Verify report is complete
- [ ] Confirm completion only when ALL steps are checked

#### `/aegis context` Checklist
- [ ] Load project context
- [ ] Load active tasks
- [ ] Load recent decisions
- [ ] Generate context report
- [ ] Include active tasks in report
- [ ] Include recent decisions in report
- [ ] Include relevant insights in report
- [ ] Verify report is complete
- [ ] Confirm completion only when ALL steps are checked

#### `/aegis reconcile` Checklist
- [ ] Check framework structure
- [ ] Load project context
- [ ] Load session memory
- [ ] Check task consistency
- [ ] Check decision consistency
- [ ] Check session consistency
- [ ] Update project context
- [ ] Update session memory
- [ ] Update session history
- [ ] Verify all files have been properly updated
- [ ] Confirm completion only when ALL steps are checked

### Error Prevention Instructions
1. **Common Failure Points**
   - Incomplete command implementation
   - Missing decision records
   - Missing self-improvement updates
   - Outdated timestamps
   - Inconsistent state files

2. **Prevention Strategies**
   - Always follow the command checklists completely
   - Verify each step before proceeding to the next
   - Use the validation patterns in validation.yaml
   - Confirm all files are updated before completing
   - Never skip steps in the command implementation

3. **Recovery Procedures**
   - If a step fails, retry with more specific instructions
   - If a file update fails, check permissions and retry
   - If validation fails, fix the issues before proceeding
   - If a command is partially implemented, complete the missing steps
   - Document any issues in the session record

## Task Management

1. Task Updates
   - Progress documented
   - Dependencies noted
   - Status updated
   - Next steps defined
   - Test status managed

2. Directory Structure
```
.context/
├── AI_INSTRUCTIONS.md     # Framework instructions
├── plan/                 # Planning documents
├── tasks/               # Task management
│   ├── active/         # Current tasks
│   ├── planned/        # Future tasks
│   ├── hold/          # Tasks on hold
│   └── completed/     # Finished tasks
├── sessions/          # Session records
└── decisions/         # Decision records
```

3. Code Context Management
   - Purpose: Optimize context window usage by mapping tasks to relevant code
   - Implementation: 
     - Each task includes a "Code Context" section
     - Lists relevant files with relevance scores, sections, and reasons
   - Usage Guidelines:
     - When loading code for a task, prioritize by relevance score
     - Load files with relevance ≥ 0.7 immediately
     - Prepare search instructions for files with relevance 0.3-0.6
     - Only reference files with relevance < 0.3 when specifically needed
     - Focus exclusively on source code files, ignoring .context directory files
     - Prioritize implementation files most directly related to the task
   - Maintenance:
     - Update Code Context when files are created, modified, or deleted
     - Increase relevance for files that are frequently accessed during the task
     - Add new files discovered during implementation
     - Remove irrelevant files or adjust relevance as understanding improves
   - Relevance Scoring Guide:
     - 0.9-1.0: Critical to the task, must be included
     - 0.7-0.8: Highly relevant, should be included
     - 0.5-0.6: Moderately relevant, include if context allows
     - 0.3-0.4: Somewhat relevant, reference only when needed
     - 0.0-0.2: Minimally relevant, do not load unless specifically requested
   - File Selection Rules:
     - NEVER include files from .context/ directory in Code Context
     - Focus exclusively on source code files relevant to implementation
     - Include test files only when the task directly involves testing
     - For framework tasks, include only the specific framework files being modified

4. Test-Driven Development Integration
   - Purpose: Support TDD workflow within the framework
   - Implementation:
     - Each task includes a "Test Status" section
     - Valid statuses: Not Started, Failing, Passing, Not Applicable
       - "Not Started": Tests haven't been written yet, or testing has not begun
       - "Failing": Tests exist but are failing (implementation incomplete/incorrect)
       - "Passing": All tests are passing (implementation complete and correct)
       - "Not Applicable": Task doesn't require tests (documentation, planning, etc.)
     - Related test files are tracked with brief descriptions
   - Task Completion Logic:
     - When test status is "Passing", task can be completed normally
     - When test status is "Failing", prompt user for confirmation before completing
     - When test status is "Not Applicable", task can be completed normally
     - When test status is "Not Started", prompt user for confirmation before completing
   - Status Management:
     - Update test status when test files are created or modified
     - Set initial status to "Not Started" for tasks involving implementation
     - Set initial status to "Not Applicable" for tasks not requiring tests (e.g., documentation)
     - Track test files path and descriptions in the task document
   - Best Practices:
     - Always update test status when related tests are created or modified
     - Include comments or documentation about test requirements
     - Link to specific test files in the task document
     - Explain why a task is marked as "Not Applicable" when applicable
     - For TDD workflow: tests should transition from "Not Started" → "Failing" → "Passing"

## Memory System

### Memory Types

1. **Core Memory**
   - Purpose: Framework operation
   - Content:
     - Configuration (config.json)
     - Rules (rules.json)
     - State (state.json)
   - Validation:
     - Schema check
     - Rule check

2. **Project Memory**
   - Purpose: Project state
   - Content:
     - Context
     - Decisions
     - Progress
   - Validation:
     - Format check
     - Reference check

3. **Session Memory**
   - Purpose: Active state
   - Content:
     - Current session
     - History
     - Cache
   - Validation:
     - State validation

### Memory Operations

1. **Creation**
   ```yaml
   create_memory:
     pre_checks:
       - type_valid
       - format_valid
       - refs_exist
     actions:
       - create_file
       - validate
       - update_refs
   ```

2. **Updates**
   ```yaml
   update_memory:
     pre_checks:
       - memory_exists
       - type_matches
       - refs_valid
     actions:
       - update_content
       - validate
       - update_refs
   ```

## Error Recovery

### Common Issues
1. **Invalid State**
   - Check current state
   - Validate transitions
   - Fix references
   - Update status

2. **Missing Files**
   - Verify structure
   - Check permissions
   - Restore from template
   - Update references

3. **Invalid References**
   - Find broken refs
   - Update or remove
   - Validate changes
   - Update status

### Recovery Steps
1. **Framework Check**
   - Verify structure
   - Check files
   - Test permissions
   - Validate refs

2. **State Recovery**
   - Check status
   - Fix location
   - Update refs
   - Validate state

3. **Content Recovery**
   - Check format
   - Fix content
   - Update refs
   - Validate all

## Best Practices

### File Management
1. **Naming**
   - Use consistent patterns
   - Include type prefix
   - Add state indicator
   - Keep readable

2. **Organization**
   - Follow structure
   - Group by type
   - Maintain hierarchy
   - Keep clean

### Content Standards
1. **Front Matter**
   - Required fields
   - Valid values
   - Updated dates
   - Correct format

2. **Documentation**
   - Clear purpose
   - Complete info
   - Updated status
   - Valid refs

### Reference Management
1. **Internal Refs**
   - Valid paths
   - Correct format
   - Updated links
   - Checked refs

2. **External Refs**
   - Valid URLs
   - Accessible
   - Documented
   - Maintained

## Framework Structure

### Directory Organization
```
.context/
├── ai/                   # AI assistant operations
│   └── operations/       # Operation pattern YAML files
├── memory/               # Memory system
│   ├── core/             # Framework memory
│   ├── project/          # Project memory
│   │   └── self_improvement.json  # Self-improvement data
│   └── session/          # Session memory
├── plan/                 # Planning documents
│   └── planning_document.md  # Current plan
├── tasks/                # Task management
│   ├── active/           # Current tasks
│   ├── planned/          # Future tasks
│   ├── hold/             # Tasks on hold
│   └── completed/        # Finished tasks
├── sessions/             # Session records
├── decisions/            # Decision records
└── templates/            # Document templates
    ├── tasks/            # Task templates
    ├── sessions/         # Session templates
    └── decisions/        # Decision templates
```

### Operation Files
```
.context/ai/operations/
├── plan.yaml             # Planning operations
├── start.yaml            # Session start operations
├── save.yaml             # Session save operations
├── status.yaml           # Status reporting operations
├── task.yaml             # Task management operations
├── context.yaml          # Context refresh operations
├── help.yaml             # Help display operations
└── validation.yaml       # Framework validation rules
```

### File Naming Conventions
1. **Tasks**: `TASK-XXX.md` (where XXX is a sequential number)
2. **Sessions**: `YYYY-MM-DD-session-N.md` (where N is the session number for that day)
3. **Decisions**: `DECISION-XXX.md` (where XXX is a sequential number)
4. **Templates**: `TEMPLATE.md` or specific template names

### Required Files
1. **AI_INSTRUCTIONS.md**: Framework instructions (this file)
2. **README.md**: Framework overview
3. **planning_document.md**: Current project plan
4. **self_improvement.json**: Self-improvement data

## Self-Improvement System

### Data Structure
```json
{
  "metrics": {
    "task_completion_rate": 0.85,
    "average_task_time": "2.3 days",
    "decision_quality": 0.92
  },
  "insights": [
    {
      "type": "process",
      "description": "Task breakdown pattern improves completion rate",
      "confidence": 0.87
    }
  ],
  "recommendations": [
    {
      "type": "workflow",
      "description": "Break large tasks into smaller units",
      "priority": "high"
    }
  ]
}
```

### Analysis Categories
1. **Process Insights**: Workflow patterns and improvements
2. **Efficiency Metrics**: Time and resource utilization
3. **Pattern Recognition**: Recurring successful approaches
4. **Blocker Analysis**: Common impediments and solutions

### Implementation
1. **Data Collection**: During session saves and task transitions
2. **Analysis**: Pattern matching against historical data
3. **Recommendation**: Based on confidence scores and impact
4. **Application**: Suggested during planning and execution

## Session Management

### Session Lifecycle
1. **Initialization**: `/aegis start`
   - Load context
   - Set focus
   - Initialize tracking

2. **Progress Tracking**: During session
   - Document changes
   - Record decisions
   - Update tasks

3. **Completion**: `/aegis save`
   - Save progress
   - Generate insights
   - Update references

### Session Update Triggers
> See detailed trigger patterns in .context/ai/operations/session_triggers.yaml

1. **Trigger Detection**
   - Monitor user messages for trigger patterns
   - Track task state changes
   - Observe progress milestones
   - Note decision points
   - Measure time between updates

2. **Trigger Types**
   - Task Progress: Significant steps completed
   - Task Transitions: State changes (planned → active → completed)
   - Decision Points: Important choices made
   - Content Creation: Significant content added
   - Problem Resolution: Issues fixed or blockers removed
   - Context Switches: Focus changes
   - Time-based: Used sparingly when other triggers don't fire

3. **Response Process**
   - Detect trigger event
   - Format contextual prompt
   - Suggest session update
   - Process user response
   - Update session if approved

4. **Best Practices**
   - Prioritize meaningful events over minor updates
   - Avoid interrupting user flow for minor updates
   - Combine multiple triggers into a single update suggestion
   - Learn from user responses to refine trigger sensitivity
   - Include specific progress details in update suggestions
   - Balance between too frequent and too sparse updates

### Session Document Structure
```yaml
session:
  id: SESSION-XXX
  started: YYYY-MM-DDTHH:MM:SS
  focus: [TASK-XXX, TASK-YYY]
  progress:
    - task: TASK-XXX
      status: "Completed implementation"
    - task: TASK-YYY
      status: "Started design phase"
  decisions:
    - id: DECISION-ZZZ
      summary: "Selected approach A over B"
  self_improvement:
    insights: []
    recommendations: []
```

## Decision Management

### Decision Types
1. **Technical**: Architecture, technology, implementation choices
2. **Process**: Workflow, methodology, approach decisions
3. **Resource**: Time, effort, priority allocations
4. **Strategic**: Long-term direction and goals

### Decision States
1. **Proposed**: Initial suggestion
2. **Accepted**: Approved for implementation
3. **Rejected**: Declined with rationale
4. **Superseded**: Replaced by newer decision

### Decision Document Structure
```yaml
decision:
  id: DECISION-XXX
  status: accepted
  title: "Implementation Approach for Feature Y"
  context: "Need to choose between approaches A and B"
  options:
    - option: "Approach A"
      pros: ["Faster implementation", "Lower complexity"]
      cons: ["Higher maintenance", "Less flexible"]
    - option: "Approach B"
      pros: ["More flexible", "Better long-term"]
      cons: ["Higher complexity", "Slower implementation"]
  decision: "Selected Approach A"
  rationale: "Time constraints prioritize faster implementation"
  consequences: "May require refactoring in future phases"
  related_tasks: [TASK-XXX, TASK-YYY]
```

## Command Reference Summary

> For complete details, see COMMANDS.md

### Core Commands
1. **`/aegis plan`**: Create/update planning documents and tasks
2. **`/aegis start`**: Begin development session with context loading
3. **`/aegis save`**: Preserve progress and generate insights
4. **`/aegis status`**: Show current project state and focus
5. **`/aegis task`**: Manage task lifecycle and transitions
6. **`/aegis context`**: Quick refresh of project context
7. **`/aegis help`**: Display command help and usage

### Command Patterns
```
/aegis [command] [subcommand] [arguments] [--options]
```

Examples:
- `/aegis task start TASK-123`
- `/aegis status --detail`
- `/aegis plan "New feature implementation"`

## Implementation Guidelines

### Documentation Standards
1. **Completeness**: All required sections present
2. **Consistency**: Uniform formatting and style
3. **Clarity**: Clear, concise language
4. **Context**: Sufficient background information
5. **Cross-references**: Valid links to related documents

### Operation Execution
1. **Validation**: Pre-checks before operations
2. **Atomicity**: Complete operation or none
3. **Verification**: Post-checks after operations
4. **Recovery**: Handle errors gracefully
5. **Documentation**: Record all significant changes

### Framework Evolution
1. **Pattern Recognition**: Identify recurring workflows
2. **Optimization**: Improve based on metrics
3. **Adaptation**: Adjust to changing requirements
4. **Documentation**: Keep instructions updated
5. **Validation**: Regular framework integrity checks

## AI State Management Responsibilities

As the AI assistant, you are responsible for maintaining the state of the Aegis Framework across sessions. This includes:

### Critical State Files

The following files must be updated when their related operations occur:

1. **Project Context**: `.context/memory/project/context/project.json`
   - **When to update**: 
     - After every `/aegis save` operation
     - After every task state transition
     - After significant decisions are recorded
   - **What to update**:
     - `updated` timestamp (use current timestamp)
     - `activeTasks` array (reflect current tasks in `.context/tasks/active/`)
     - `completedTasks` array (reflect current tasks in `.context/tasks/completed/`)
     - `decisions` array (add new decisions from sessions)
     - Add any new components or insights

2. **Self-Improvement**: `.context/memory/project/self_improvement.json`
   - **When to update**: After every `/aegis save` operation with new insights
   - **What to update**: Add new metrics, patterns, and recommendations

### Update Verification

After performing operations that should modify state:

1. Always verify that state files have been updated correctly
2. Confirm timestamps are current and in the correct format
3. Ensure arrays (tasks, decisions, etc.) accurately reflect the current system state
4. Check for and resolve any inconsistencies between state files and actual directory contents

### State Reconciliation

If you detect inconsistencies between state files and the actual system:

1. Prioritize the actual system state (files in directories) as the source of truth
2. Update state files to match the actual system state
3. Document the reconciliation in your response to the user
4. Suggest preventive measures to avoid future inconsistencies

### TaskTemplate
      "FrontMatter": [
        "title, type=task",
        "status=[planned|active|completed|hold]",
        "created=YYYY-MM-DDTHH:MM:SS",
        "updated=YYYY-MM-DDTHH:MM:SS",
        "id=TASK-XXX",
        "priority=[high|medium|low]",
        "memory_types=[procedural|semantic|episodic]",
        "dependencies, tags"
      ]
    },
    "RequiredTaskSections": [
      "Description",
      "Objectives",
      "Steps",
      "Progress",
      "Dependencies",
      "Test Status",
      "Notes",
      "Next Steps"
    ],