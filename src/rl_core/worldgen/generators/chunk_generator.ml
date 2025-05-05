(***
  Chunk Generator: Modular, functional chunk generation for the
  Supports biomes, pluggable algorithms, and entity/feature placement.
***)

open Base
open Rl_types
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
  | Rooms -> Algorithms.Rooms.run ~width ~height ~rng |> fst
  | Custom f -> f ~width ~height ~rng

(* generate one chunk at a time (good for procedural/infinite worlds). *)
let generate_and_save_chunk ~cx ~cy ~chunk_w ~chunk_h ~world_w ~world_h
    ~biome_map ~config ~depth (em : Entity_manager.t) : Entity_manager.t =
  (* Pick the dominant biome in this chunk *)
  let biome_counts =
    Biome_generator.generate_count_map ~chunk_w ~chunk_h ~world_w ~world_h
      ~biome_map ~cx ~cy
  in
  let biome =
    Hashtbl.fold biome_counts ~init:(BiomeType.Mine, 0)
      ~f:(fun ~key ~data (bmax, nmax) ->
        if data > nmax then (key, data) else (bmax, nmax))
    |> fst
  in

  let rng = Random.State.make [| config.Config.seed; cx; cy |] in
  let flat_tiles =
    Biome_generator.generate_biome_region ~width:chunk_w ~height:chunk_h ~biome
      ~rng
  in
  let entity_ids =
    Biome_generator.place_biome_features_and_entities ~biome ~tiles:flat_tiles
      ~width:chunk_w ~height:chunk_h ~rng
  in
  let tiles =
    Array.init chunk_h ~f:(fun y ->
        Array.init chunk_w ~f:(fun x -> flat_tiles.((y * chunk_w) + x)))
  in

  let chunk : Chunk.t =
    {
      tiles;
      entity_ids;
      coords = Loc.make cx cy;
      last_accessed_turn = 0;
      metadata = { Chunk.seed = config.Config.seed; biome };
    }
  in

  let chunk_path = Constants.chunk_path cx cy depth in
  Chunk.save_chunk chunk_path chunk;
  let entity_path = Entity_manager.entity_path_for_chunk chunk_path in
  Entity_manager.save_entities entity_path entity_ids;

  em
