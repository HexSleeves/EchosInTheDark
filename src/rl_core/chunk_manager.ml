open Base
open Types (* Provides chunk_coord, world_pos, local_pos, entity_id *)
open Dungeon (* Provides Chunk module and Tile type *)

(* Module for chunk coordinate sets *)
module ChunkCoord = struct
  (* Need sexp_of_t for Hashtbl.create *)
  type t = chunk_coord [@@deriving compare, hash, sexp]

  include Comparator.Make (struct
    type t = chunk_coord [@@deriving compare, sexp_of]
  end)
end

(* Type alias for the hash table storing active chunks *)
type active_chunks = (chunk_coord, Chunk.t) Hashtbl.t

(* The state managed by the Chunk Manager *)
type t = {
  active_chunks : active_chunks;
  world_seed : int; (* Needed for deterministic generation *)
  mutable last_player_chunk : chunk_coord option;
      (* Track player chunk changes *)
}

(* Constants *)
let chunk_width = 32
let chunk_height = 32
let load_radius = 2 (* 5x5 grid means radius of 2 from center *)

(* --- Coordinate Conversion Helpers --- *)

let floor_div x y = if x >= 0 then x / y else ((x + 1) / y) - 1

let world_to_chunk_coord (pos : world_pos) : chunk_coord =
  let cx = floor_div pos.x chunk_width in
  let cy = floor_div pos.y chunk_height in
  (cx, cy)

let world_to_local_coord (pos : world_pos) : local_pos =
  let lx = Int.rem pos.x chunk_width in
  let ly = Int.rem pos.y chunk_height in
  (* Ensure positive remainder for negative coordinates *)
  let lx = if lx < 0 then lx + chunk_width else lx in
  let ly = if ly < 0 then ly + chunk_height else ly in
  Loc.make lx ly (* Assuming Loc is defined in Types *)

(* --- Manager Functions --- *)

let create ~world_seed =
  {
    world_seed;
    last_player_chunk = None;
    active_chunks = Hashtbl.create (module ChunkCoord);
  }

(* Gets a chunk if it's currently loaded *)
let get_loaded_chunk t coords = Hashtbl.find t.active_chunks coords

let set_loaded_chunk t coords chunk =
  Hashtbl.set t.active_chunks ~key:coords ~data:chunk

(* Gets the tile at a specific world position, if the chunk is loaded *)
let get_tile_at t world_pos =
  let chunk_coords = world_to_chunk_coord world_pos in
  match get_loaded_chunk t chunk_coords with
  | None -> None (* Chunk not loaded *)
  | Some chunk ->
      let local_pos = world_to_local_coord world_pos in
      if
        local_pos.x >= 0 && local_pos.x < chunk_width && local_pos.y >= 0
        && local_pos.y < chunk_height
      then Some chunk.tiles.(local_pos.y).(local_pos.x)
        (* Assuming row-major y,x *)
      else None (* Should not happen *)

(* Calculate the set of chunk coordinates required around a central chunk *)
let get_required_chunks center_cx center_cy =
  let required = ref (Set.empty (module ChunkCoord)) in
  for dx = -load_radius to load_radius do
    for dy = -load_radius to load_radius do
      required := Set.add !required (center_cx + dx, center_cy + dy)
    done
  done;
  !required

(* Ensures required chunks around the player are loaded, unloading others *)
let update_loaded_chunks_around_player t player_world_pos =
  let player_cx, player_cy = world_to_chunk_coord player_world_pos in
  let current_player_chunk = (player_cx, player_cy) in
  match t.last_player_chunk with
  | Some last_chunk when ChunkCoord.compare last_chunk current_player_chunk = 0
    ->
      t
  | _ ->
      Core_log.info (fun m ->
          m "Player entered new chunk (%d, %d), updating loaded chunks."
            player_cx player_cy);
      t.last_player_chunk <- Some current_player_chunk;
      let required_chunks = get_required_chunks player_cx player_cy in
      let loaded_chunks =
        Set.of_list (module ChunkCoord) (Hashtbl.keys t.active_chunks)
      in

      let chunks_to_load = Set.diff required_chunks loaded_chunks in
      let chunks_to_unload = Set.diff loaded_chunks required_chunks in
      Set.iter chunks_to_unload ~f:(fun coords ->
          Core_log.debug (fun m ->
              m "Unloading chunk (%d, %d)" (fst coords) (snd coords));
          Hashtbl.remove t.active_chunks coords);
      Set.iter chunks_to_load ~f:(fun coords ->
          Core_log.debug (fun m ->
              m "Loading chunk (%d, %d)" (fst coords) (snd coords));
          if not (Hashtbl.mem t.active_chunks coords) then
            let new_chunk =
              Mapgen.Chunk_generator.generate coords ~world_seed:t.world_seed
            in
            Hashtbl.set t.active_chunks ~key:coords ~data:new_chunk);
      t

(* Function to be called potentially every turn or after player move *)
let tick t player_world_pos =
  update_loaded_chunks_around_player t player_world_pos

(* TODO:
   - Integrate entity management with chunk loading/unloading if needed
   - Consider async generation
*)
