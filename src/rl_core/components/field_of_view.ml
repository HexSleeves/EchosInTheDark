open Base
open Rl_utils

(* For now, assume a fixed map size; can refactor for chunks later *)
let map_width = 128
let map_height = 128

module TileIndex = struct
  type t = int * int

  let of_enum i =
    let x = i % map_width in
    let y = i / map_width in
    if x < map_width && y < map_height then Some (x, y) else None

  let to_enum (x, y) = (y * map_width) + x
  let last = (map_width - 1, map_height - 1)
end

module TileBitset = Bitset.Make (TileIndex)
(* Field of view component for entities *)
(* The bitset is used to store tile indices for visible and seen tiles *)

(* index = y * map_width + x *)
[@@deriving yojson]

type t = { visible : TileBitset.t; seen : TileBitset.t; radius : int }

let table : (int, t) Hashtbl.t = Hashtbl.create (module Int)
let set id data = Hashtbl.set table ~key:id ~data
let get id = Hashtbl.find table id
let get_exn id = Hashtbl.find_exn table id

let make ~radius =
  { visible = TileBitset.empty; seen = TileBitset.empty; radius }

let get_visible t = t.visible
let get_seen t = t.seen
let set_visible visible t = { t with visible }

let update_seen t =
  {
    t with
    seen = TileBitset.fold (fun acc x -> TileBitset.add acc x) t.seen t.visible;
  }

let clear_visible t = { t with visible = TileBitset.empty }
let set_radius radius t = { t with radius }

(* Helpers for working with (x, y) positions *)
let add_visible (x, y) t = { t with visible = TileBitset.add t.visible (x, y) }
let mem_visible (x, y) t = TileBitset.mem t.visible (x, y)
let mem_seen (x, y) t = TileBitset.mem t.seen (x, y)
