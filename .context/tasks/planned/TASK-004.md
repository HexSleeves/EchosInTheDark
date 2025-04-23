---
title: Map game tile types to tileset coordinates
type: task
status: planned
created: 2025-03-05T14:32:10
updated: 2025-03-05T14:32:10
id: TASK-004
priority: medium
memory_types: [procedural, semantic]
dependencies: [TASK-001]
tags: [mapping, renderer]
---

## Description
Create a mapping from each game tile type to its (row, col) in the tileset.

## Objectives
- Ensure every tile type has a corresponding tile in the tileset.

## Steps
1. Enumerate all tile types.
2. Assign (row, col) for each.

## Progress

## Dependencies
- TASK-001

## Notes

## Next Steps
- Use this mapping in the render_cell function.
