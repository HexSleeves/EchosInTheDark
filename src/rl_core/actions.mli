(* Actions module interface for handling game actions independently of backend state *)

open Types

type action_result = (int, exn) Result.t
(** Result type for action processing, returning a time cost or an error *)

type action_context = {
  get_entity : entity_id -> entity option;
  get_tile_at : Loc.t -> Map.Tile.t;
  in_bounds : Loc.t -> bool;
  get_entity_at_pos : Loc.t -> entity option;
}
(** Data required to process actions, abstracted from backend *)

val handle_action :
  action_context -> entity_id -> Action.action_type -> action_result
(** Function to handle an action for a given entity *)
