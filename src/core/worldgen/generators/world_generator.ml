open Base
open Types

(* batch generate all chunks (good for static worlds). *)
let generate_world ~config ~depth ~em : Entity_manager.t =
  let chunk_w = Constants.chunk_w in
  let chunk_h = Constants.chunk_h in
  let world_w = Constants.world_w in
  let world_h = Constants.world_h in

  let num_chunks_x = (world_w + chunk_w - 1) / chunk_w in
  let num_chunks_y = (world_h + chunk_h - 1) / chunk_h in

  let base_dir = Constants.chunk_dir_path depth in
  Utils.ensure_dir Constants.chunk_dir;
  Utils.ensure_dir base_dir;

  (* Generate the biome map for the whole world *)
  let biome_map =
    Biome_generator.generate_biome_map ~width:world_w ~height:world_h ~depth
      ~seed:config.Config.seed
  in

  let biome_counts = Hashtbl.create (module Biome_generator.BiomeCount) in
  for y = 0 to world_h - 1 do
    for x = 0 to world_w - 1 do
      let b = biome_map.(y).(x) in
      Hashtbl.update biome_counts b ~f:(function None -> 1 | Some n -> n + 1)
    done
  done;

  (* Pick the dominant biome for the whole world *)
  let biome =
    Hashtbl.fold biome_counts ~init:(BiomeType.Mine, 0)
      ~f:(fun ~key ~data (bmax, nmax) ->
        if data > nmax then (key, data) else (bmax, nmax))
    |> fst
  in

  let rng = Random.State.make [| config.Config.seed |] in
  let flat_tiles =
    Biome_generator.generate_biome_region ~width:world_w ~height:world_h ~biome
      ~rng
  in

  (* Wrap the world with walls *)
  for x = 0 to world_w - 1 do
    flat_tiles.(x) <- Dungeon.Tile.Wall;
    (* Top row *)
    flat_tiles.(((world_h - 1) * world_w) + x) <- Dungeon.Tile.Wall
    (* Bottom row *)
  done;
  for y = 0 to world_h - 1 do
    flat_tiles.(y * world_w) <- Dungeon.Tile.Wall;
    (* Left column *)
    flat_tiles.((y * world_w) + world_w - 1) <- Dungeon.Tile.Wall
    (* Right column *)
  done;

  for cx = 0 to num_chunks_x - 1 do
    for cy = 0 to num_chunks_y - 1 do
      let tiles =
        Array.init chunk_h ~f:(fun y ->
            Array.init chunk_w ~f:(fun x ->
                let wx = (cx * chunk_w) + x in
                let wy = (cy * chunk_h) + y in
                if wx < world_w && wy < world_h then
                  flat_tiles.((wy * world_w) + wx)
                else Dungeon.Tile.Wall))
      in

      let chunk_rng = Random.State.make [| config.Config.seed; cx; cy |] in
      let chunk_flat = Array.concat (Array.to_list tiles) in

      let entity_ids =
        Biome_generator.place_biome_features_and_entities ~biome
          ~tiles:chunk_flat ~width:chunk_w ~height:chunk_h ~rng:chunk_rng
      in

      let chunk : Chunk.t =
        {
          tiles;
          entity_ids;
          last_accessed_turn = 0;
          coords = Loc.make cx cy;
          metadata = { Chunk.seed = config.Config.seed; biome };
        }
      in

      let chunk_path = Constants.chunk_path cx cy depth in
      Chunk.save_chunk chunk_path chunk;
      let entity_path = Entity_manager.entity_path_for_chunk chunk_path in
      Entity_manager.save_entities entity_path entity_ids
    done
  done;
  em
