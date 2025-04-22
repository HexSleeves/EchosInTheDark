(*
  Enum type for all possible actions an actor can take.

  Action semantics:
  | Variant         | Description                                      | Parameters         |
  |-----------------|--------------------------------------------------|--------------------|
  | Move            | Move the actor in a direction if possible         | direction          |
  | Interact        | Interact with an entity (door, lever, etc.)       | entity_id          |
  | Pickup          | Pick up an item from the ground                   | entity_id          |
  | Drop            | Drop an item from inventory                       | entity_id          |
  | Attack          | Attack another entity (combat)                    | entity_id          |
  | StairsUp        | Use stairs to go up a level                       | -                  |
  | StairsDown      | Use stairs to go down a level                     | -                  |
  | Wait            | Do nothing for a turn                             | -                  |
*)

type action_type =
  | Move of Types.direction
  | Interact of Types.entity_id
  | Pickup of Types.entity_id
  | Drop of Types.entity_id
  | StairsUp
  | StairsDown
  | Wait
  | Attack of Types.entity_id

let to_string = function
  | Move dir -> "Move " ^ Types.Direction.to_string dir
  | Interact id -> "Interact " ^ string_of_int id
  | Pickup id -> "Pickup " ^ string_of_int id
  | Drop id -> "Drop " ^ string_of_int id
  | StairsUp -> "StairsUp"
  | StairsDown -> "StairsDown"
  | Wait -> "Wait"
  | Attack id -> "Attack " ^ string_of_int id
