open Base
open Rl_types
open Dungeon

let ensure_dir path =
  if not (Stdlib.Sys.file_exists path) then Stdlib.Sys.mkdir path 0o755

let generate_full_world_tile ~biome ~rng =
  match biome with
  | BiomeType.Mine ->
      if Float.(Random.State.float rng 1.0 < 0.65) then Tile.Floor
      else Tile.Wall
  | BiomeType.Crystal_Caverns ->
      if Float.(Random.State.float rng 1.0 < 0.7) then Tile.Floor else Tile.Wall
  | BiomeType.Mushroom_Forest ->
      if Float.(Random.State.float rng 1.0 < 0.6) then Tile.Floor else Tile.Tree
  | BiomeType.Lava_Chambers ->
      if Float.(Random.State.float rng 1.0 < 0.5) then Tile.Water
      else Tile.Floor
  | BiomeType.Ice_Caves ->
      if Float.(Random.State.float rng 1.0 < 0.6) then Tile.Floor else Tile.Wall
  | BiomeType.Cursed_Depths ->
      if Float.(Random.State.float rng 1.0 < 0.5) then Tile.Floor else Tile.Wall
  | BiomeType.Ancient_Ruins ->
      if Float.(Random.State.float rng 1.0 < 0.6) then Tile.Floor else Tile.Wall
  | BiomeType.Enchanted_Grotto ->
      if Float.(Random.State.float rng 1.0 < 0.7) then Tile.Floor else Tile.Wall
  | BiomeType.Chasm ->
      if Float.(Random.State.float rng 1.0 < 0.2) then Tile.Chasm
      else Tile.Floor
  | BiomeType.Toxic_Sludge ->
      if Float.(Random.State.float rng 1.0 < 0.3) then Tile.Water
      else Tile.Floor
  | BiomeType.Gemstone_Vaults ->
      if Float.(Random.State.float rng 1.0 < 0.7) then Tile.Floor else Tile.Wall
  | BiomeType.Forgotten_Catacombs ->
      if Float.(Random.State.float rng 1.0 < 0.5) then Tile.Floor else Tile.Wall
  | BiomeType.Underground_Lake ->
      if Float.(Random.State.float rng 1.0 < 0.5) then Tile.Water
      else Tile.Floor
  | BiomeType.Obsidian_Halls ->
      if Float.(Random.State.float rng 1.0 < 0.5) then Tile.Wall else Tile.Floor

let generate_full_world ~width ~height ~seed ~biome_map =
  let rng = Random.State.make [| seed |] in
  Array.init height ~f:(fun y ->
      Array.init width ~f:(fun x ->
          let biome = biome_map.(y).(x) in
          generate_full_world_tile ~biome ~rng))

let generate_biome_map ~width ~height ~depth ~seed =
  Array.init height ~f:(fun y ->
      Array.init width ~f:(fun x ->
          Biome_generator.pick_biome ~depth ~x ~y ~world_seed:seed))

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

  let biome_map =
    generate_biome_map ~width:world_w ~height:world_h ~depth
      ~seed:config.Config.seed
  in
  let world =
    generate_full_world ~width:world_w ~height:world_h ~seed:config.Config.seed
      ~biome_map
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
      (* Pick the dominant biome in this chunk *)
      let module B = struct
        type t = BiomeType.biome_type [@@deriving compare, sexp]

        let compare = BiomeType.compare_biome_type
        let sexp_of_t = BiomeType.sexp_of_biome_type
        let hash = BiomeType.hash_biome_type
      end in
      let biome_counts = Hashtbl.create (module B) in
      for y = 0 to chunk_h - 1 do
        for x = 0 to chunk_w - 1 do
          let wx = (cx * chunk_w) + x in
          let wy = (cy * chunk_h) + y in
          if wx < world_w && wy < world_h then
            let b = biome_map.(wy).(wx) in
            Hashtbl.update biome_counts b ~f:(function
              | None -> 1
              | Some n -> n + 1)
        done
      done;
      let biome =
        Hashtbl.fold biome_counts ~init:(BiomeType.Mine, 0)
          ~f:(fun ~key ~data (bmax, nmax) ->
            if data > nmax then (key, data) else (bmax, nmax))
        |> fst
      in
      let flat_tiles = Array.concat (Array.to_list tiles) in
      let rng = Random.State.make [| config.Config.seed; cx; cy |] in
      let entity_ids =
        Biome_generator.place_biome_features_and_entities ~biome
          ~tiles:flat_tiles ~width:chunk_w ~height:chunk_h ~rng
      in
      let metadata = { Chunk.seed = config.Config.seed; biome } in
      let chunk : Chunk.t =
        {
          coords = chunk_coords;
          tiles;
          entity_ids;
          metadata;
          last_accessed_turn = 0;
        }
      in
      let chunk_path = Printf.sprintf "%s/chunk_%d_%d.json" base_dir cx cy in
      Chunk.save_chunk chunk_path chunk
    done
  done
