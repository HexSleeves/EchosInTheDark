(* Enum type for all possible actions an actor can take *)
type action_type =
  | Move of Types.direction
  | Interact of Types.entity_id
  | Pickup of Types.entity_id
  | Drop of Types.entity_id
  | StairsUp
  | StairsDown
  | Wait
