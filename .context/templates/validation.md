# Template Validation Rules

## Front Matter Requirements

### Task Template
```yaml
required:
  type: 
    value: "task"
    description: "Document type, must be 'task'"
  status:
    values: ["planned", "active", "hold", "completed"]
    description: "Current task status"
  created:
    format: "YYYY-MM-DD"
    description: "Creation date"
  updated:
    format: "YYYY-MM-DD"
    description: "Last update date"
  id:
    pattern: "TASK-\\d{3}"
    description: "Unique task identifier"
  memory_types:
    type: "array"
    values: ["procedural", "semantic", "episodic"]
    description: "Types of memory this task affects"
optional:
  priority:
    values: ["high", "medium", "low"]
    description: "Task priority level"
```

### Session Template
```yaml
required:
  type:
    value: "session"
    description: "Document type, must be 'session'"
  status:
    values: ["active", "completed"]
    description: "Current session status"
  started:
    format: "YYYY-MM-DD HH:MM:SS"
    description: "Session start time"
  id:
    pattern: "SESSION-\\d{3}"
    description: "Unique session identifier"
optional:
  ended:
    format: "YYYY-MM-DD HH:MM:SS"
    description: "Session end time"
```

### Decision Template
```yaml
required:
  type:
    value: "decision"
    description: "Document type, must be 'decision'"
  status:
    values: ["proposed", "accepted", "rejected", "superseded"]
    description: "Current decision status"
  created:
    format: "YYYY-MM-DD"
    description: "Creation date"
  updated:
    format: "YYYY-MM-DD"
    description: "Last update date"
  id:
    pattern: "DECISION-\\d{3}"
    description: "Unique decision identifier"
optional:
  relates_to:
    pattern: "TASK-\\d{3}"
    description: "Related task identifier"
  supersedes:
    pattern: "DECISION-\\d{3}"
    description: "Identifier of decision this supersedes"
```

## Validation Rules

### Common Rules
1. Front matter must be enclosed in triple-dashes (`---`)
2. All dates must use the specified format
3. IDs must follow the specified pattern
4. Status values must be from the allowed set
5. Required fields cannot be empty
6. Optional fields can be omitted but must be valid if present

### Task-Specific Rules
1. Status transitions must be valid:
   - planned → active
   - active → hold
   - active → completed
   - hold → active
2. Updated date must be >= created date
3. Priority must be specified for high-priority tasks

### Session-Specific Rules
1. Ended time must be > started time
2. Ended time required if status is completed
3. Cannot have ended time if status is active

### Decision-Specific Rules
1. Must include rationale if status is accepted
2. Must include consequences if status is accepted
3. Updated date must be >= created date
4. Must include supersedes reference if status is superseded

## Content Validation Rules

### Section Requirements

#### Task Template
```yaml
required_sections:
  Description:
    min_length: 20
    max_length: 500
    rules:
      - Must clearly state the task purpose
      - Must be written in present tense
      - Must be actionable
  
  Objectives:
    min_items: 1
    max_items: 5
    rules:
      - Each objective must be measurable
      - Must use bullet points
      - Must start with action verbs
  
  Steps:
    min_items: 1
    rules:
      - Must use checkbox format: "- [ ]"
      - Must be ordered logically
      - Must be atomic actions
  
  Progress:
    rules:
      - Must use bullet points
      - Must be updated with each change
      - Must reflect current state
  
  Dependencies:
    rules:
      - Must reference valid task IDs
      - Must indicate status ( or )
      - Must be ordered by dependency chain

optional_sections:
  Notes:
    rules:
      - Should provide context
      - Should highlight constraints
  
  Next Steps:
    min_items: 1
    max_items: 5
    rules:
      - Must be numbered list
      - Must be actionable items
  
  Completion Notes:
    required_if: "status == completed"
    rules:
      - Must summarize achievements
      - Must list any follow-up tasks
```

#### Session Template
```yaml
required_sections:
  Focus:
    min_length: 10
    max_length: 100
    rules:
      - Must state primary objective
      - Must be specific to session
  
  Context:
    required_fields:
      - Active Task
      - Branch
    rules:
      - Must reference valid tasks
      - Must include current state
  
  Progress:
    subsections:
      Completed:
        min_items: 0
        rules:
          - Must use bullet points
          - Must be verifiable actions
      In Progress:
        min_items: 0
        rules:
          - Must use checkbox format
          - Must be current work items

optional_sections:
  Decisions:
    rules:
      - Must be numbered
      - Must include context
      - Must state rationale
  
  Dependencies:
    rules:
      - Must use checkbox format
      - Must include impact
      - Must list resolution steps
  
  Next Steps:
    min_items: 1
    rules:
      - Must be numbered
      - Must be actionable
```

#### Decision Template
```yaml
required_sections:
  Context:
    min_length: 50
    rules:
      - Must explain motivation
      - Must provide background
  
  Problem Statement:
    min_length: 20
    rules:
      - Must be clear and specific
      - Must identify key issues
  
  Options Considered:
    min_items: 2
    rules:
      - Must list pros and cons
      - Must be viable options
      - Must be comparable
  
  Decision:
    required_if: "status in [accepted, rejected]"
    rules:
      - Must state clear choice
      - Must reference chosen option
  
  Rationale:
    required_if: "status in [accepted, rejected]"
    rules:
      - Must justify decision
      - Must address key factors

optional_sections:
  Implementation:
    required_if: "status == accepted"
    rules:
      - Must use checkbox format
      - Must be actionable steps
  
  Consequences:
    required_if: "status == accepted"
    subsections:
      Positive:
        min_items: 1
        rules:
          - Must use bullet points
      Negative:
        min_items: 1
        rules:
          - Must use bullet points
```

### Content Rules

1. General Format Rules:
   - Use consistent markdown formatting
   - Maintain section hierarchy
   - Use appropriate list formats
   - Keep content concise and clear

2. Writing Style:
   - Use active voice
   - Be specific and measurable
   - Use consistent terminology
   - Maintain professional tone

3. References:
   - Use correct ID formats
   - Link to existing documents
   - Maintain reference integrity
   - Update references when needed

4. Updates:
   - Preserve document history
   - Mark completed items
   - Update status correctly
   - Maintain timestamps

### Implementation Notes

1. Section Validation:
   ```python
   def validate_section(section, rules):
     # Check required fields
     for field in rules.required_fields:
       if field not in section:
         raise Error(f"Missing required field: {field}")
     
     # Check content rules
     if len(section) < rules.min_length:
       raise Error(f"Section too short: {len(section)}")
     
     # Check list items
     if rules.min_items and len(section.items) < rules.min_items:
       raise Error(f"Not enough items: {len(section.items)}")
   ```

2. Content Validation:
   ```python
   def validate_content(content, template_type):
     # Load template rules
     rules = load_rules(template_type)
     
     # Check required sections
     for section in rules.required_sections:
       if section not in content:
         raise Error(f"Missing section: {section}")
       
       validate_section(content[section], rules[section])
     
     # Check conditional sections
     for section, condition in rules.conditional_sections:
       if eval(condition) and section not in content:
         raise Error(f"Required section missing: {section}")
   ```

3. Error Messages:
   ```
   Error: Section '[name]' validation failed
   - Required field '[field]' is missing
   - Content length ([length]) below minimum ([min])
   - Not enough items ([count]) in list ([min] required)
   - Invalid format in item [item]: [details]
   ```

## Implementation Notes

### Front Matter Parsing
```markdown
---
type: [document_type]
other_fields: values
---
```

1. Extract content between `---` markers
2. Parse as YAML
3. Validate required fields
4. Validate field values
5. Check relationships
6. Verify dates and times

### Error Handling
1. Missing required field:
   ```
   Error: Required field '[field]' is missing
   ```

2. Invalid value:
   ```
   Error: Field '[field]' has invalid value '[value]'
   Valid values are: [valid_values]
   ```

3. Invalid format:
   ```
   Error: Field '[field]' does not match required format
   Expected: [format]
   Found: [value]
   ```

4. Invalid relationship:
   ```
   Error: Invalid reference in field '[field]'
   Referenced [type] '[id]' does not exist
   ```
