---
title: Refactor render_cell for configurable rendering
type: task
status: planned
created: 2025-03-05T14:32:10
updated: 2025-03-05T14:32:10
id: TASK-005
priority: medium
memory_types: [procedural, semantic]
dependencies: [TASK-002, TASK-003, TASK-004]
tags: [renderer, refactor]
---

## Description
Refactor the render_cell function to branch on render_mode, drawing either a tile image or ASCII glyph.

## Objectives
- Support both rendering modes.
- Fallback to ASCII if tile is missing.

## Steps
1. Update render_cell to check render_mode.
2. Draw tile or glyph as appropriate.
3. Implement fallback logic.

## Progress

## Dependencies
- TASK-002
- TASK-003
- TASK-004

## Notes

## Next Steps
- Test both modes in-game.
