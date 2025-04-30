open Base
open Rl_types
open Dungeon
open Ppx_yojson_conv_lib.Yojson_conv

let chunk_width = 50
let chunk_height = 24

(* Absolute position in the infinite world *)
type world_pos = Loc.t [@@deriving yojson, show, eq, compare, hash, sexp]

(* Coordinates identifying a specific chunk *)
type chunk_coord = Loc.t [@@deriving yojson, show, eq, compare, hash, sexp]

(* Position within a chunk (0-31) *)
type local_pos = Loc.t [@@deriving yojson, show, eq, compare, hash, sexp]

(* Metadata associated with a chunk *)
type chunk_metadata = {
  seed : int;
  biome : Biome.biome_type;
      (* Add other flags as needed, e.g., has_feature_x : bool; *)
}
[@@deriving yojson, show, eq, compare, hash, sexp]

type t = {
  coords : chunk_coord; (* (cx, cy) *)
  tiles : Tile.t array array; (* 2D array [32][32] *)
  entity_ids : entity_id list;
      (* IDs of entities physically within this chunk's bounds *)
  metadata : chunk_metadata;
  mutable last_accessed_turn : int;
      (* For potential LRU cache eviction optimization *)
}

let create ~coords ~metadata : t =
  {
    coords;
    metadata;
    entity_ids = [];
    last_accessed_turn = 0;
    tiles =
      Array.init chunk_height ~f:(fun _ ->
          Array.init chunk_width ~f:(fun _ -> Tile.Floor));
  }

let world_to_chunk_coord (pos : Loc.t) : Loc.t =
  Loc.make (pos.x / chunk_width) (pos.y / chunk_height)

let world_to_local_coord (pos : Loc.t) : Loc.t =
  let lx = pos.x % chunk_width in
  let ly = pos.y % chunk_height in
  let lx = if lx < 0 then lx + chunk_width else lx in
  let ly = if ly < 0 then ly + chunk_height else ly in
  Loc.make lx ly

(* let make_position (world : Loc.t) : Components.Position.t =
  let chunk = world_to_chunk_coord world in
  let local = world_to_local_coord world in
  { world_pos = world; chunk_pos = chunk; local_pos = local } *)

let get_tile (chunk : t) (pos : local_pos) : Tile.t option =
  if pos.x >= 0 && pos.x < chunk_width && pos.y >= 0 && pos.y < chunk_height
  then Some chunk.tiles.(pos.y).(pos.x)
  else None

let set_tile (chunk : t) (pos : local_pos) (tile : Tile.t) : bool =
  if pos.x >= 0 && pos.x < chunk_width && pos.y >= 0 && pos.y < chunk_height
  then (
    chunk.tiles.(pos.y).(pos.x) <- tile;
    true)
  else false

let add_entity (chunk : t) (id : entity_id) : t =
  { chunk with entity_ids = id :: chunk.entity_ids }

let remove_entity (chunk : t) (id : entity_id) : t =
  {
    chunk with
    entity_ids = List.filter chunk.entity_ids ~f:(fun eid -> eid <> id);
  }
