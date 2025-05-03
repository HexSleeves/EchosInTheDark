open Base
open Rl_types
open Dungeon
open Rl_loader
open Ppx_yojson_conv_lib.Yojson_conv

(* Absolute position in the infinite world *)
type world_pos = Loc.t [@@deriving yojson, show, eq, compare, hash, sexp]

(* Coordinates identifying a specific chunk *)
type chunk_coord = Loc.t [@@deriving yojson, show, eq, compare, hash, sexp]

(* Position within a chunk (0-31) *)
type local_pos = Loc.t [@@deriving yojson, show, eq, compare, hash, sexp]

(* Metadata associated with a chunk *)
type chunk_metadata = { seed : int; biome : BiomeType.biome_type }
[@@deriving yojson, show, eq, compare, hash, sexp]

type t = {
  coords : chunk_coord; (* (cx, cy) *)
  tiles : Tile.t array array;
  entity_ids : int list;
  metadata : chunk_metadata;
  mutable last_accessed_turn : int;
}
[@@deriving yojson, show]

let create ~coords ~metadata : t =
  {
    coords;
    metadata;
    entity_ids = [];
    last_accessed_turn = 0;
    tiles =
      Array.init Constants.chunk_h ~f:(fun _ ->
          Array.init Constants.chunk_w ~f:(fun _ -> Tile.Floor));
  }

let world_to_chunk_coord (pos : Loc.t) : Loc.t =
  Loc.make (pos.x / Constants.chunk_w) (pos.y / Constants.chunk_h)

let world_to_local_coord (pos : Loc.t) : Loc.t =
  let lx = pos.x % Constants.chunk_w in
  let ly = pos.y % Constants.chunk_h in
  let lx = if lx < 0 then lx + Constants.chunk_w else lx in
  let ly = if ly < 0 then ly + Constants.chunk_h else ly in
  Loc.make lx ly

(* let make_position (world : Loc.t) : Components.Position.t =
  let chunk = world_to_chunk_coord world in
  let local = world_to_local_coord world in
  { world_pos = world; chunk_pos = chunk; local_pos = local } *)

let get_tile (chunk : t) (pos : local_pos) : Tile.t option =
  if
    pos.x >= 0 && pos.x < Constants.chunk_w && pos.y >= 0
    && pos.y < Constants.chunk_h
  then Some chunk.tiles.(pos.y).(pos.x)
  else None

let set_tile (chunk : t) (pos : local_pos) (tile : Tile.t) : bool =
  if
    pos.x >= 0 && pos.x < Constants.chunk_w && pos.y >= 0
    && pos.y < Constants.chunk_h
  then (
    chunk.tiles.(pos.y).(pos.x) <- tile;
    true)
  else false

let add_entity (chunk : t) (id : int) : t =
  { chunk with entity_ids = id :: chunk.entity_ids }

let remove_entity (chunk : t) (id : int) : t =
  {
    chunk with
    entity_ids = List.filter chunk.entity_ids ~f:(fun eid -> eid <> id);
  }

(* Save a chunk to disk as JSON. Overwrites existing file. *)
let save_chunk (path : string) (chunk : t) : unit =
  let json = yojson_of_t chunk in
  let oc = Stdio.Out_channel.create path in
  Yojson.Safe.pretty_to_channel oc json;
  Stdio.Out_channel.close oc

(* Load a chunk from disk as JSON. Raises if file is missing or invalid. *)
let load_chunk (path : string) : t =
  let ic = Loader.open_file path in
  let json = Yojson.Safe.from_channel ic in
  Stdio.In_channel.close ic;
  t_of_yojson json
