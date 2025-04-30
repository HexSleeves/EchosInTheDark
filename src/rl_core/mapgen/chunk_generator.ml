open Base
open Types

(* No longer opening Types or Dungeon directly to avoid ambiguity, use qualified names *)

(* Placeholder for noise function - replace with actual library call *)
let get_noise_value (rng : Random.State.t) (_world_x : int) (_world_y : int) :
    float =
  Random.State.float rng 1.0

(* Placeholder for hashing function for seeding *)
let hash_coords world_seed cx cy =
  (* Very basic hash - replace with something better if needed *)
  (((world_seed * 31) + cx) * 31) + cy

let generate (chunk_coords : chunk_coord) ~(world_seed : int) : Dungeon.Chunk.t
    =
  let cx, cy = chunk_coords in
  let chunk_seed = hash_coords world_seed cx cy in
  let rng = Random.State.make [| chunk_seed |] in

  (* Initialize tile array *)
  let tiles =
    Array.init Dungeon.Chunk.chunk_height ~f:(fun _ ->
        Array.init Dungeon.Chunk.chunk_width ~f:(fun _ -> Dungeon.Tile.Floor))
  in

  (* Step 1: Base Terrain/Biome Generation *)
  let biome = ref Types.Plains in

  (* Default biome *)
  for y = 0 to Dungeon.Chunk.chunk_height - 1 do
    for x = 0 to Dungeon.Chunk.chunk_width - 1 do
      let world_x = (cx * Dungeon.Chunk.chunk_width) + x in
      let world_y = (cy * Dungeon.Chunk.chunk_height) + y in
      let noise_val = get_noise_value rng world_x world_y in
      (* Use world coords for consistency *)

      (* Example: Map noise to tile type *)
      let tile_type =
        if Float.compare noise_val 0.3 < 0 then Dungeon.Tile.Water
        else if Float.compare noise_val 0.6 < 0 then Dungeon.Tile.Floor
        else Dungeon.Tile.Wall
      in
      tiles.(y).(x) <- tile_type;

      (* Example: Determine biome based on average noise or other factors *)
      if Float.compare noise_val 0.7 > 0 then biome := Types.Mountain
      else if Float.compare noise_val 0.3 < 0 then biome := Types.Water_Body
      (* Keep Plains if intermediate *)
    done
  done;

  (* Step 2: Feature Overlay (Placeholder) *)
  (* TODO: Based on chunk_coords, biome, rng, decide if features generate *)
  (* Example: if Random.State.float rng 1.0 < 0.1 then place_feature(tiles, rng) *)

  (* Step 3: Entity Placement (Placeholder) *)
  let entity_ids : entity_id list =
    []
    (* TODO: Place entities based on biome/features/tiles *)
    (* Example: if !biome = Forest then add_entity(EntityType.Wolf, random_floor_tile) *)
  in

  (* Construct metadata *)
  let metadata : chunk_metadata = { seed = chunk_seed; biome = !biome } in

  (* Create the chunk *)
  {
    tiles;
    entity_ids;
    metadata;
    last_accessed_turn = 0;
    (* Initialize access turn *)
    Dungeon.Chunk.coords = chunk_coords;
  }
