open Base
open Types
open Ppx_yojson_conv_lib.Yojson_conv

(* --- BEGIN MERGED FROM actor.ml --- *)
type actor_id = int [@@deriving yojson, show]

(* TurnActor type *)
type t = { speed : int; alive : bool; next_action : Action.t option }
[@@deriving yojson, show]

(* Constructor *)
let create ~speed = { speed; alive = true; next_action = None }

(* Queue an action and return new actor *)
let queue_action t (action : Action.t) = { t with next_action = Some action }

(* Pop the next action, return (action option * new actor) *)
let next_action t : Action.t option * t =
  match t.next_action with
  | None -> (None, t)
  | Some a -> (Some a, { t with next_action = None })

(* Peek at the next action *)
let peek_next_action t : Action.t option = t.next_action

(* Is alive? *)
let is_alive t = t.alive
(* --- END MERGED FROM actor.ml --- *)
