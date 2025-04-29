open Base
open Ppx_yojson_conv_lib.Yojson_conv

(* Entity is now just an ID *)
type entity_id = int

module CtrlMode = struct
  type t = Normal | WaitInput | AI | Died of float [@@deriving yojson]
end

module Loc = struct
  type t = { x : int; y : int }
  [@@deriving yojson, show, eq, compare, hash, sexp]

  let make x y = { x; y }
  let add a b = { x = a.x + b.x; y = a.y + b.y }
  let ( + ) = add
end

module Direction = struct
  type t = North | East | South | West [@@deriving yojson, show]

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

(* //////////////////////// *)
(* STATS AND ITEMS *)
