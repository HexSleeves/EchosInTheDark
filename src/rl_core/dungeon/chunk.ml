open Base
open Types

type t = {
  coords : chunk_coord; (* (cx, cy) *)
  tiles : Tile.t array array; (* 2D array [32][32] *)
  entity_ids : entity_id list;
      (* IDs of entities physically within this chunk's bounds *)
  metadata : chunk_metadata;
  mutable last_accessed_turn : int;
      (* For potential LRU cache eviction optimization *)
}
(* Deriving yojson might be complex due to the 2D array and Tile.t. Handle manually if needed. *)
(* [@@deriving show] could also be large. Add if debugging requires it. *)

let chunk_width = 32
let chunk_height = 32

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
