---
title: Implement tileset loading and slicing
type: task
status: planned
created: 2025-03-05T14:32:10
updated: 2025-03-05T14:32:10
id: TASK-003
priority: medium
memory_types: [procedural, semantic]
dependencies: [TASK-001]
tags: [assets, renderer]
---

## Description
Implement a function to load the tileset image and slice it into 8x8 tiles.

## Objectives
- Load the PNG at startup.
- Calculate tile size and slice into sub-images.

## Steps
1. Load the image using Raylib.
2. Calculate tile width/height.
3. Store references to each tile.

## Progress

## Dependencies
- TASK-001

## Notes

## Next Steps
- Use sliced tiles in rendering logic.
