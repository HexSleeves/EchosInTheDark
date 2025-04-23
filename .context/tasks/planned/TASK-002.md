---
title: Add render_mode type and mutable state
type: task
status: planned
created: 2025-03-05T14:32:10
updated: 2025-03-05T14:32:10
id: TASK-002
priority: medium
memory_types: [procedural, semantic]
dependencies: [TASK-001]
tags: [renderer, config]
---

## Description
Define a render_mode type (Ascii | Tiles) and add mutable state to track the current rendering mode, defaulting to Tiles.

## Objectives
- Add type and state for render mode.
- Ensure default is Tiles.

## Steps
1. Define the type in renderer.ml.
2. Add a mutable ref for the current mode.

## Progress

## Dependencies
- TASK-001

## Notes

## Next Steps
- Use this state in rendering logic.
