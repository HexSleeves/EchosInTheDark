(***
  Chunk Generator: Modular, functional chunk generation for the
  Supports biomes, pluggable algorithms, and entity/feature placement.
***)

open Base
open Worldgen_types

(** Hashing function for deterministic chunk seeding *)
let hash_coords (world_seed : int) (cx : int) (cy : int) : int =
  (((world_seed * 31) + cx) * 31) + cy

(* --- Modular Chunk Generation --- *)

(** Strategy for picking algorithm per chunk. You can make this smarter! *)
let pick_algo_for_chunk (cx, cy) ~world_seed : chunk_gen_algo =
  if (cx + cy + world_seed) % 2 = 0 then CA else Rooms

(** Unified chunk generation function *)
let run_chunk_algo ~(algo : chunk_gen_algo) ~(width : int) ~(height : int)
    ~(rng : Random.State.t) : Dungeon.Tile.t array =
  match algo with
  | Prefab filename -> Algorithms.Prefab.load_prefab ~width ~height filename
  | CA -> Algorithms.Ca.run ~width ~height ~rng
  | Rooms -> fst (Algorithms.Rooms.rooms_generator ~width ~height ~rng)
  | Custom f -> f ~width ~height ~rng

(* --- Biome-specific entity/feature placement --- *)

(** Main chunk generation entry point *)
let generate ~(chunk_coords : Chunk.chunk_coord) ~(world_seed : int)
    ~(depth : int) : Chunk.t =
  let cx, cy = Rl_types.Loc.to_tuple chunk_coords in
  Core_log.info (fun m ->
      m "[GEN] Generating chunk at (%d, %d), depth %d" cx cy depth);
  let chunk_seed = hash_coords world_seed cx cy in
  let width = Constants.chunk_width in
  let height = Constants.chunk_height in
  let rng = Random.State.make [| chunk_seed |] in

  (* Step 1: Pick biome and algorithm *)
  let biome = Biome.pick_biome ~depth ~cx ~cy ~world_seed in
  let algo = Biome.algo_for_biome biome in
  let tiles_1d = run_chunk_algo ~algo ~width ~height ~rng in
  let tiles =
    Array.init height ~f:(fun y ->
        Array.init width ~f:(fun x -> tiles_1d.(x + (y * width))))
  in

  (* Step 2: Feature Overlay (Placeholder for biome-specific features) *)
  (* TODO: Mutate tiles here for biome-specific features (ore, lava, ice, etc) *)

  (* Step 3: Entity Placement (biome-specific) *)
  let entity_ids =
    Biome.place_biome_features_and_entities ~biome ~tiles:tiles_1d ~width
      ~height ~rng
  in

  (* Step 4: Construct metadata and return chunk *)
  let metadata : Chunk.chunk_metadata = { seed = chunk_seed; biome } in
  {
    tiles;
    metadata;
    entity_ids;
    last_accessed_turn = 0;
    Chunk.coords = chunk_coords;
  }
