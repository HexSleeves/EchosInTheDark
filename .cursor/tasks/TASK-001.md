# Entity System Implementation

**Task ID**: TASK-001
**Status**: 📝 Open
**Created**: 2023-08-02
**Priority**: High

## Description

Implement the entity system for managing game actors including the player, enemies, and items. The entity system will be responsible for creating, updating, and managing all entities in the game world.

## Related Specifications

- SPEC-004: Entity System (to be created)
- SPEC-001: [Game State Management](.cursor/specs/backend/game_state.md)

## Requirements

1. Create an entity data structure with:
   - Unique identifier
   - Position
   - Entity type (player, enemy, item)
   - Entity-specific properties (health, damage, etc.)

2. Implement entity management functions:
   - Create entities
   - Update entity state
   - Remove entities
   - Query entities by various criteria

3. Add entity interaction mechanisms:
   - Collision detection
   - Combat system
   - Item pickup/use

4. Integrate with existing systems:
   - Update Backend module to store entities
   - Connect with tilemap for positioning
   - Interface with control modes for entity control

## Acceptance Criteria

- [ ] Entity data structure is defined and documented
- [ ] Entity creation and management functions are implemented
- [ ] Entities can be positioned and moved on the map
- [ ] Entities can interact with each other (combat, etc.)
- [ ] Player entity can be controlled through input
- [ ] Entity state updates correctly during game loop

## Notes

- Consider using an entity component system (ECS) approach
- Keep performance in mind for large numbers of entities
- Plan for future extensions like entity AI, equipment system, etc.
- May require updating the serialization system for save/load functionality

## Step-by-Step Plan: Refactor and Clarify Action/Turn Queue System

1. **Document Current Flow**
   - Map out the current flow: UI → actor action queue → turn system → action execution.
   - Identify all places where actions are created, queued, and executed for both player and NPCs.

2. **Unify Action Queuing**
   - Ensure all actors (player and NPCs) use the same action queue mechanism.
   - Refactor any code paths where actions are handled differently for different actor types.

3. **Decouple Action Creation from Execution**
   - Refactor actions to be stateless "intent" objects.
   - Ensure actions do not store or depend on entity state at creation; they should query state at execution.

4. **Centralize Action Processing**
   - Ensure all action execution goes through a single backend entry point (e.g., `action#execute`).
   - Remove any redundant or legacy "pending action" state outside the actor's action queue and the turn queue.

5. **Improve NPC/AI Action Queuing**
   - Implement or refactor logic for NPCs to queue their actions when their turn comes up, using the same mechanism as the player.

6. **Update Documentation**
   - Document the new architecture and flow in the appropriate memory files (architecture, technical, tasks, etc.).
   - Add code comments to clarify the responsibilities of each component.

7. **Test and Validate**
   - Write or update tests to ensure the new system works for both player and NPCs.
   - Validate that there is no redundant state and that the system is robust and maintainable.
