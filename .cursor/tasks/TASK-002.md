# Entity Interaction & Combat System

**Task ID**: TASK-002
**Status**: 📝 Open
**Created**: 2024-06-10
**Priority**: High

## Description

Enable entities (player and NPCs) to interact with each other and the environment. This includes basic combat (attack, damage, death), item pickup/use, and groundwork for more advanced interactions (e.g., doors, traps).

## Step-by-Step Plan

1. **Design Interaction Actions**
   - Define and document the possible interaction actions (e.g., `Interact`, `Pickup`, `Drop`, `Attack`).
   - Update the `action_type` enum if needed.

2. **Implement Interaction Logic in Backend**
   - Add logic to `handle_action` for `Interact`, `Pickup`, `Drop`, and `Attack`.
   - Ensure all state changes (e.g., health, inventory) are handled in the backend.

3. **UI Triggers for Interactions**
   - Map new keys to interaction actions in `input.ml`.
   - Update the UI to allow the player to trigger these actions.

4. **Entity State Updates**
   - Ensure entity state (e.g., health, inventory, alive/dead) updates correctly after interactions.
   - Handle entity removal on death.

5. **Feedback and Messaging**
   - Provide feedback to the player (e.g., log messages, UI updates) when interactions occur.

6. **Testing**
   - Manually test all new interactions.
   - Add unit tests for backend logic if possible.

7. **Documentation**
   - Update architecture and technical docs to reflect the new interaction system.

## Acceptance Criteria

- [ ] Player can attack and defeat NPCs (and vice versa).
- [ ] Player can pick up and drop items.
- [ ] Entity state updates correctly after interactions.
- [ ] All interaction logic is handled in the backend.
- [ ] UI can trigger all supported interactions.
- [ ] Documentation is updated.
