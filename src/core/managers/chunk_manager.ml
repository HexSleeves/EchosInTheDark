(***
  Chunk Manager: Handles loading/unloading and coordinate mapping for world chunks.
  Functional, idiomatic OCaml style.
***)

open Base
open Types
open Utils

(* Constants *)
let load_radius = Constants.chunk_load_radius

(* Type alias for the hash table storing active chunks *)
type active_chunks = (Chunk.chunk_coord, Chunk.t) Hashtbl.t

(* Module for chunk coordinate sets *)
module ChunkCoord = struct
  (* Need sexp_of_t for Hashtbl.create *)
  type t = Chunk.chunk_coord [@@deriving compare, hash, sexp]

  include Comparator.Make (struct
    type t = Chunk.chunk_coord [@@deriving compare, sexp_of]
  end)
end

(* The state managed by the Chunk Manager *)
type t = {
  world_seed : int;
  level : string; (* Add level for chunk file pathing *)
  active_chunks : active_chunks;
  last_player_chunk : Chunk.chunk_coord option;
}

(* --- Coordinate Conversion Helpers --- *)

let world_to_chunk_coord (pos : Chunk.world_pos) : Chunk.chunk_coord =
  Loc.make
    (floor_div pos.x Constants.chunk_w)
    (floor_div pos.y Constants.chunk_h)

let world_to_local_coord (pos : Chunk.world_pos) : Chunk.local_pos =
  let lx = Int.rem pos.x Constants.chunk_w in
  let ly = Int.rem pos.y Constants.chunk_h in
  (* Ensure positive remainder for negative coordinates *)
  let lx = if lx < 0 then lx + Constants.chunk_w else lx in
  let ly = if ly < 0 then ly + Constants.chunk_h else ly in
  Loc.make lx ly (* Assuming Loc is defined in Types *)

let make_position (world : Types.Loc.t) : Components.Position.t =
  let chunk = world_to_chunk_coord world in
  let local = world_to_local_coord world in
  { world_pos = world; chunk_pos = chunk; local_pos = local }

(* --- Manager Functions --- *)

let create ~world_seed ~level : t =
  {
    world_seed;
    level;
    last_player_chunk = None;
    active_chunks = Hashtbl.create (module ChunkCoord);
  }

let get_active_chunks (t : t) : active_chunks = t.active_chunks

let get_loaded_chunk (coords : Chunk.chunk_coord) (t : t) : Chunk.t option =
  Hashtbl.find t.active_chunks coords

let set_loaded_chunk (coords : Chunk.chunk_coord) (chunk : Chunk.t) (t : t) : t
    =
  Hashtbl.set t.active_chunks ~key:coords ~data:chunk;
  t

(* Gets the tile at a specific world position, if the chunk is loaded *)
let get_tile_at (world_pos : Chunk.world_pos) (t : t) : Dungeon.Tile.t option =
  let chunk_coords = world_to_chunk_coord world_pos in
  Option.bind (get_loaded_chunk chunk_coords t) ~f:(fun chunk ->
      let local_pos = world_to_local_coord world_pos in
      if Utils.in_chunk_bounds (local_pos.x, local_pos.y) then
        Some chunk.tiles.(local_pos.y).(local_pos.x)
      else None)

(* Helper to get chunk file path *)
let chunk_path ~level (coords : Chunk.chunk_coord) =
  Printf.sprintf "resources/chunks/%s/chunk_%d_%d.json" level coords.x coords.y

(* Load a chunk from disk, log error if missing *)
let load_chunk_from_disk ~em ~level coords =
  let path = chunk_path ~level coords in
  if Stdlib.Sys.file_exists path then (
    let chunk = Chunk.load_chunk path in

    (* Load and register entities *)
    let entity_path = Entity_manager.entity_path_for_chunk path in
    match Stdlib.Sys.file_exists entity_path with
    | true ->
        let entities = Entity_manager.load_entities entity_path in
        let em = Entity_manager.register_entities entities em in
        Some (chunk, em)
    | false ->
        Core_log.err (fun m -> m "Entity file missing: %s" entity_path);
        Some (chunk, em))
  else (
    Core_log.err (fun m -> m "Chunk file missing: %s" path);
    None)

let unload_chunk_to_disk ~level ~em (chunk : Chunk.t) =
  let open Entity_manager in
  let path = chunk_path ~level chunk.coords in
  Chunk.save_chunk path chunk;

  let entity_path = entity_path_for_chunk path in
  save_entities entity_path chunk.entity_ids;
  remove_entities chunk.entity_ids em

(* Calculate the set of chunk coordinates required around a central chunk *)
let get_required_chunks (center : Chunk.chunk_coord) : Set.M(ChunkCoord).t =
  let open Base in
  let required = ref (Set.empty (module ChunkCoord)) in
  for dx = -load_radius to load_radius do
    for dy = -load_radius to load_radius do
      required := Set.add !required (Loc.make (center.x + dx) (center.y + dy))
    done
  done;
  !required

(* Ensures required chunks around the player are loaded, unloading others *)
let update_loaded_chunks_around_player ~em (t : t)
    (player_world_pos : Chunk.world_pos) ~depth : t * Entity_manager.t =
  let current_player_chunk = world_to_chunk_coord player_world_pos in
  let unchanged =
    Option.value_map t.last_player_chunk ~default:false ~f:(fun last_chunk ->
        ChunkCoord.compare last_chunk current_player_chunk = 0)
  in

  match unchanged with
  | true -> (t, em)
  | false ->
      let required_chunks =
        Set.filter (get_required_chunks current_player_chunk) ~f:(fun c ->
            Utils.in_chunk_bounds (c.x, c.y))
      in
      let loaded_chunks =
        Set.of_list (module ChunkCoord) (Hashtbl.keys t.active_chunks)
      in

      let chunks_to_load = Set.diff required_chunks loaded_chunks in
      let chunks_to_unload = Set.diff loaded_chunks required_chunks in

      let active_chunks = Hashtbl.copy t.active_chunks in
      Set.iter chunks_to_unload ~f:(fun coords ->
          Core_log.debug (fun m ->
              m "Unloading chunk (%d, %d)" coords.x coords.y);
          Hashtbl.remove active_chunks coords);

      let active_chunks, em =
        Set.fold chunks_to_load ~init:(active_chunks, em)
          ~f:(fun (active_chunks, em) coords ->
            Core_log.info (fun m ->
                m "[LOAD] Loading chunk (%d, %d) at depth %d" coords.x coords.y
                  depth);
            Core_log.debug (fun m ->
                m "Loading chunk (%d, %d)" coords.x coords.y);
            if not (Hashtbl.mem active_chunks coords) then
              match load_chunk_from_disk ~em ~level:t.level coords with
              | Some (chunk, em') ->
                  Hashtbl.set active_chunks ~key:coords ~data:chunk;
                  (active_chunks, em')
              | None -> (active_chunks, em)
            else (active_chunks, em))
      in

      ( { t with active_chunks; last_player_chunk = Some current_player_chunk },
        em )

(* Function to be called potentially every turn or after player move *)
let tick ~depth (em : Entity_manager.t) (player_world_pos : Chunk.world_pos)
    (t : t) : t * Entity_manager.t =
  update_loaded_chunks_around_player ~em t player_world_pos ~depth
