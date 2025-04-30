open Base
open Ppx_yojson_conv_lib.Yojson_conv

module Loc = struct
  type t = { x : int; y : int }
  [@@deriving yojson, show, eq, compare, hash, sexp]

  let to_string t = Printf.sprintf "(%d, %d)" t.x t.y

  (* Create a new location *)
  let make (x : int) (y : int) : t = { x; y }
  let to_tuple t : int * int = (t.x, t.y)

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
