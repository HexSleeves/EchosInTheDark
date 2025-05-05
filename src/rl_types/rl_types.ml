open Ppx_yojson_conv_lib.Yojson_conv

(* Entity type alias *)
type entity = int [@@deriving yojson, show]

(* Export the Loc and Direction modules *)
module Direction = Loc.Direction
module Loc = Loc.Loc
module BiomeType = Biome

module CtrlMode = struct
  type t = Normal | WaitInput | AI | Died of float [@@deriving yojson, show]
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
    | Interact of int
    | Pickup of int
    | Drop of int
    | Attack of int
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

module Actor = struct
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
end
