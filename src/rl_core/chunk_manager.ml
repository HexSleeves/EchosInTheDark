(***
  Chunk Manager: Handles loading/unloading and coordinate mapping for world chunks.
  Functional, idiomatic OCaml style.
***)

open Base
open Rl_types
open Utils

(* Constants *)
let load_radius = 2 (* 5x5 grid means radius of 2 from center *)

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
    (floor_div pos.x Constants.chunk_width)
    (floor_div pos.y Constants.chunk_height)

let world_to_local_coord (pos : Chunk.world_pos) : Chunk.local_pos =
  let lx = Int.rem pos.x Constants.chunk_width in
  let ly = Int.rem pos.y Constants.chunk_height in
  (* Ensure positive remainder for negative coordinates *)
  let lx = if lx < 0 then lx + Constants.chunk_width else lx in
  let ly = if ly < 0 then ly + Constants.chunk_height else ly in
  Loc.make lx ly (* Assuming Loc is defined in Types *)

let make_position (world : Rl_types.Loc.t) : Components.Position.t =
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
      if
        local_pos.x >= 0
        && local_pos.x < Constants.chunk_width
        && local_pos.y >= 0
        && local_pos.y < Constants.chunk_height
      then Some chunk.tiles.(local_pos.y).(local_pos.x)
        (* Assuming row-major y,x *)
      else None (* Should not happen *))

(* Helper to get chunk file path *)
let chunk_path ~level (coords : Chunk.chunk_coord) =
  Printf.sprintf "resources/chunks/%s/chunk_%d_%d.json" level coords.x coords.y

(* Load a chunk from disk, log error if missing *)
let load_chunk_from_disk ~level coords =
  let path = chunk_path ~level coords in
  if Stdlib.Sys.file_exists path then Some (Chunk.load_chunk path)
  else (
    Core_log.err (fun m -> m "Chunk file missing: %s" path);
    None)

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
let update_loaded_chunks_around_player (t : t)
    (player_world_pos : Chunk.world_pos) ~depth : t =
  let current_player_chunk = world_to_chunk_coord player_world_pos in
  let unchanged =
    Option.value_map t.last_player_chunk ~default:false ~f:(fun last_chunk ->
        ChunkCoord.compare last_chunk current_player_chunk = 0)
  in

  match unchanged with
  | true -> t
  | false ->
      let required_chunks = get_required_chunks current_player_chunk in
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

      Set.iter chunks_to_load ~f:(fun coords ->
          Core_log.info (fun m ->
              m "[LOAD] Loading chunk (%d, %d) at depth %d" coords.x coords.y
                depth);
          Core_log.debug (fun m -> m "Loading chunk (%d, %d)" coords.x coords.y);
          if not (Hashtbl.mem active_chunks coords) then
            match load_chunk_from_disk ~level:t.level coords with
            | Some chunk -> Hashtbl.set active_chunks ~key:coords ~data:chunk
            | None -> ());
      { t with active_chunks; last_player_chunk = Some current_player_chunk }

(* Function to be called potentially every turn or after player move *)
let tick (player_world_pos : Chunk.world_pos) (t : t) ~depth : t =
  update_loaded_chunks_around_player t player_world_pos ~depth

(* TODO:
   - Integrate entity management with chunk loading/unloading if needed
   - Consider async generation
*)
