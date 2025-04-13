# Memory Operations

## Overview
Memory operations define how the framework interacts with memories, ensuring consistent state management and data integrity.

## Core Operations

### Read Operations
1. Load Memory
   ```yaml
   operation: load
   type: memory
   category: <core|project|session|user>
   id: memory-id
   ```
   - Validate permissions
   - Check existence
   - Load content
   - Verify schema

2. Query Memory
   ```yaml
   operation: query
   type: memory
   pattern: query-pattern
   filters:
     category: optional-category
     state: optional-state
   ```
   - Match pattern
   - Apply filters
   - Return results
   - Sort by relevance

3. List Memories
   ```yaml
   operation: list
   type: memory
   category: optional-category
   recursive: boolean
   ```
   - Get category
   - List contents
   - Filter results
   - Sort output

### Write Operations
1. Create Memory
   ```yaml
   operation: create
   type: memory
   category: required-category
   content: memory-content
   ```
   - Validate schema
   - Check permissions
   - Create file
   - Set initial state

2. Update Memory
   ```yaml
   operation: update
   type: memory
   id: memory-id
   changes: content-changes
   ```
   - Load current
   - Validate changes
   - Update content
   - Save state

3. Delete Memory
   ```yaml
   operation: delete
   type: memory
   id: memory-id
   force: boolean
   ```
   - Check references
   - Validate deletion
   - Remove content
   - Update state

### State Operations
1. Change State
   ```yaml
   operation: state
   type: memory
   id: memory-id
   new_state: target-state
   reason: change-reason
   ```
   - Verify transition
   - Update state
   - Record reason
   - Save changes

2. Track Changes
   ```yaml
   operation: track
   type: memory
   id: memory-id
   changes: change-list
   ```
   - Record changes
   - Update history
   - Save metadata
   - Notify system

3. Validate State
   ```yaml
   operation: validate
   type: memory
   id: memory-id
   rules: validation-rules
   ```
   - Check state
   - Verify rules
   - Report issues
   - Suggest fixes

## Operation Rules

### Access Control
1. Read Rules
   - Check permissions
   - Verify access
   - Load content
   - Return data

2. Write Rules
   - Validate changes
   - Check conflicts
   - Update content
   - Save state

3. Delete Rules
   - Check references
   - Verify permissions
   - Remove content
   - Update state

### Validation Rules
1. Schema Validation
   - Check format
   - Verify fields
   - Validate types
   - Check required

2. State Validation
   - Verify current
   - Check transition
   - Validate rules
   - Update state

3. Reference Validation
   - Check links
   - Verify targets
   - Update references
   - Maintain integrity

### Error Handling
1. Operation Errors
   - Log error
   - Report issue
   - Suggest fix
   - Roll back

2. Validation Errors
   - Show problem
   - Explain issue
   - Provide example
   - Guide fix

3. State Errors
   - Show current
   - Explain conflict
   - Suggest solution
   - Guide recovery

## Usage Patterns

### Basic Operations
1. Read Pattern
   ```javascript
   // Load memory
   memory = load(id)
   // Check content
   if (valid(memory)) {
     // Use content
     process(memory.content)
   }
   ```

2. Write Pattern
   ```javascript
   // Create changes
   changes = prepare_changes()
   // Update memory
   if (valid(changes)) {
     update(memory, changes)
     save(memory)
   }
   ```

3. State Pattern
   ```javascript
   // Change state
   if (can_transition(current, new)) {
     change_state(memory, new)
     track_change(memory)
   }
   ```

### Complex Operations
1. Batch Operations
   ```javascript
   // Process multiple
   memories = list(category)
   for (memory in memories) {
     if (should_process(memory)) {
       process(memory)
     }
   }
   ```

2. Reference Updates
   ```javascript
   // Update references
   refs = find_references(memory)
   for (ref in refs) {
     if (needs_update(ref)) {
       update_reference(ref)
     }
   }
   ```

3. State Sync
   ```javascript
   // Synchronize states
   states = get_states(category)
   for (state in states) {
     if (out_of_sync(state)) {
       sync_state(state)
     }
   }
   ```

## Implementation Notes
1. Always validate before write
2. Keep operations atomic
3. Maintain consistency
4. Handle errors gracefully
5. Track all changes
6. Update references
7. Preserve history
8. Follow patterns
