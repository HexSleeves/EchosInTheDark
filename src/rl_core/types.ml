open Base
open Ppx_yojson_conv_lib.Yojson_conv

(* Entity is now just an ID *)
type entity_id = int [@@deriving yojson, show]

module CtrlMode = struct
  type t = Normal | WaitInput | AI | Died of float [@@deriving yojson, show]
end

module Loc = struct
  type t = { x : int; y : int }
  [@@deriving yojson, show, eq, compare, hash, sexp]

  let to_string t = Printf.sprintf "(%d, %d)" t.x t.y

  (* Create a new location *)
  let make x y = { x; y }
  let to_tuple t = (t.x, t.y)

  (* Add two locations *)
  let add a b = { x = a.x + b.x; y = a.y + b.y }
  let ( + ) = add

  (* Subtract two locations *)
  let sub a b = { x = a.x - b.x; y = a.y - b.y }
  let ( - ) = sub

  (* Get the x coordinate *)
  let x t = t.x

  (* Get the y coordinate *)
  let y t = t.y
end

module Direction = struct
  type t = North | East | South | West [@@deriving yojson, show, enumerate]

  let to_point = function
    | North -> Loc.make 0 (-1)
    | East -> Loc.make 1 0
    | South -> Loc.make 0 1
    | West -> Loc.make (-1) 0

  let to_string = function
    | North -> "North"
    | East -> "East"
    | South -> "South"
    | West -> "West"
end

module Action = struct
  (*
  Enum type for all possible actions an actor can take.

  Action semantics:
  | Variant         | Description                                      | Parameters         |
  |-----------------|--------------------------------------------------|--------------------|
  | Move            | Move the actor in a direction if possible         | direction          |
  | Interact        | Interact with an entity (door, lever, etc.)       | id          |
  | Pickup          | Pick up an item from the ground                   | id          |
  | Drop            | Drop an item from inventory                       | id          |
  | Attack          | Attack another entity (combat)                    | id          |
  | StairsUp        | Use stairs to go up a level                       | -                  |
  | StairsDown      | Use stairs to go down a level                     | -                  |
  | Wait            | Do nothing for a turn                             | -                  |
*)

  type t =
    | Move of Direction.t
    | Interact of entity_id
    | Pickup of entity_id
    | Drop of entity_id
    | Attack of entity_id
    | StairsUp
    | StairsDown
    | Wait
  [@@deriving yojson, show]

  let to_string = function
    | Move dir -> "Move " ^ Direction.to_string dir
    | Interact id -> "Interact " ^ Int.to_string id
    | Pickup id -> "Pickup " ^ Int.to_string id
    | Drop id -> "Drop " ^ Int.to_string id
    | Attack id -> "Attack " ^ Int.to_string id
    | StairsUp -> "StairsUp"
    | StairsDown -> "StairsDown"
    | Wait -> "Wait"
end

(* --- Chunking System Types --- *)

(* Absolute position in the infinite world *)
type world_pos = Loc.t [@@deriving yojson, show, eq, compare, hash, sexp]

(* Coordinates identifying a specific chunk *)
type chunk_coord = Loc.t [@@deriving yojson, show, eq, compare, hash, sexp]

(* Position within a chunk (0-31) *)
type local_pos = Loc.t [@@deriving yojson, show, eq, compare, hash, sexp]

(* Biome types for chunk generation *)
type biome_type =
  | Plains
  | Forest
  | Mountain
  | Water_Body
  | Desert
  | Mine
  | Enchanted_Mine
  | Cursed
  | Frigid
  | Hot
[@@deriving yojson, show, eq, compare, hash, sexp]

(* Metadata associated with a chunk *)
type chunk_metadata = {
  seed : int;
  biome : biome_type;
      (* Add other flags as needed, e.g., has_feature_x : bool; *)
}
[@@deriving yojson, show, eq, compare, hash, sexp]

(* Represents a single 32x32 map chunk *)
