open Types
open Ppx_yojson_conv_lib.Yojson_conv

type actor_id = int [@@deriving yojson, show]

(* TurnActor type *)
type t = {
  speed : int;
  alive : bool;
  next_turn_time : int;
  next_action : Action.action_type option;
}
[@@deriving yojson, show]

(* Constructor *)
let create ~next_turn_time ~speed =
  { speed; alive = true; next_turn_time; next_action = None }

(* Queue an action and return new actor *)
let queue_action t (action : Action.action_type) =
  { t with next_action = Some action }

(* Pop the next action, return (action option * new actor) *)
let next_action t : Action.action_type option * t =
  match t.next_action with
  | None -> (None, t)
  | Some a -> (Some a, { t with next_action = None })

(* Peek at the next action *)
let peek_next_action t : Action.action_type option = t.next_action

(* Is alive? *)
let is_alive t = t.alive
