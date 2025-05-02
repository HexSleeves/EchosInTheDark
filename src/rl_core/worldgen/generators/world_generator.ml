open Base
open Rl_types
open Dungeon
open Algorithms

let ensure_dir path =
  if not (Stdlib.Sys.file_exists path) then Stdlib.Sys.mkdir path 0o755

let generate_full_world ~width ~height ~seed =
  let rng = Random.State.make [| seed |] in
  Ca.run ~width ~height ~rng

let slice_and_save_chunks ~config ~depth =
  let chunk_w = Constants.chunk_width in
  let chunk_h = Constants.chunk_height in
  let world_w = config.Config.width in
  let world_h = config.Config.height in
  let num_chunks_x = (world_w + chunk_w - 1) / chunk_w in
  let num_chunks_y = (world_h + chunk_h - 1) / chunk_h in
  let base_dir = Printf.sprintf "resources/chunks/%s" (Int.to_string depth) in
  ensure_dir "resources/chunks";
  ensure_dir base_dir;
  let world_1d =
    generate_full_world ~width:world_w ~height:world_h ~seed:config.Config.seed
  in
  let world =
    Array.init world_h ~f:(fun y ->
        Array.init world_w ~f:(fun x -> world_1d.(x + (y * world_w))))
  in
  for cx = 0 to num_chunks_x - 1 do
    for cy = 0 to num_chunks_y - 1 do
      let tiles =
        Array.init chunk_h ~f:(fun y ->
            Array.init chunk_w ~f:(fun x ->
                let wx = (cx * chunk_w) + x in
                let wy = (cy * chunk_h) + y in
                if wx < world_w && wy < world_h then world.(wy).(wx)
                else Tile.Wall))
      in
      let chunk_coords = Loc.make cx cy in
      let biome =
        Biome.pick_biome ~depth ~cx ~cy ~world_seed:config.Config.seed
      in
      let metadata = { Chunk.seed = config.Config.seed; biome } in
      let chunk : Chunk.t =
        {
          coords = chunk_coords;
          tiles;
          entity_ids = [];
          metadata;
          last_accessed_turn = 0;
        }
      in
      let chunk_path = Printf.sprintf "%s/chunk_%d_%d.json" base_dir cx cy in
      Chunk.save_chunk chunk_path chunk
    done
  done
