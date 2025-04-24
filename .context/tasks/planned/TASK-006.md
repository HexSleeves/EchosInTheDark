---
title: Add in-game toggle for render mode
type: task
status: active
created: 2025-03-05T14:32:10
updated: 2025-03-05T14:47:25
id: TASK-006
priority: medium
memory_types: [procedural, semantic]
dependencies: [TASK-002, TASK-005]
tags: [input, renderer]
---

## Description
Add a keybinding (e.g., T) to toggle between ASCII and Tiles mode during gameplay.

## Objectives
- Allow user to switch modes at runtime.
- Update renderer state and redraw.

## Steps
1. Add key event handler for toggle.
2. Update render mode and force redraw.

## Progress
- Created toggle_render_mode function in Constants module
- Made render_mode mutable with a reference
- Added T key detection in Input module
- Implemented toggle handler in play.ml
- Added logging when toggle occurs

## Dependencies
- TASK-002
- TASK-005

## Notes
The implementation uses a mutable reference in Constants.ml and updates the render context when the mode changes.

## Next Steps
- Test toggle in-game.
- Ensure both modes display correctly.
