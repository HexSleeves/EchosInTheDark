(* Actions module for handling game actions independently of backend state *)

open Types

(* Result type for action processing *)
type action_result = (int, exn) Result.t

(* Data required to process actions, abstracted from backend *)
type action_context = {
  get_entity : Entity.entity_id -> Entity.entity option;
  get_tile_at : Loc.t -> Map.Tile.t;
  in_bounds : Loc.t -> bool;
  get_entity_at_pos : Loc.t -> Entity.entity option;
}

(* Handle an action for a given entity *)
let handle_action (ctx : action_context) (entity_id : Entity.entity_id)
    (action : Action.action_type) : action_result =
  match action with
  | Move dir -> (
      match ctx.get_entity entity_id with
      | None -> Error (Failure "Entity not found")
      | Some entity ->
          let delta = Direction.to_point dir in
          let new_pos = Types.Loc.(entity.pos + delta) in
          let within_bounds = ctx.in_bounds new_pos in
          let walkable = Map.Tile.is_walkable (ctx.get_tile_at new_pos) in
          let no_entity = Option.is_none (ctx.get_entity_at_pos new_pos) in
          if within_bounds && walkable && no_entity then Ok 100
          else Error (Failure "Cannot move here"))
  | Wait -> Ok 100
  | StairsUp -> (
      match ctx.get_entity entity_id with
      | None -> Error (Failure "Entity not found")
      | Some entity ->
          let tile = ctx.get_tile_at entity.pos in
          if Map.Tile.equal tile Map.Tile.Stairs_up then Ok 0
          else Error (Failure "Not on stairs up"))
  | StairsDown -> (
      match ctx.get_entity entity_id with
      | None -> Error (Failure "Entity not found")
      | Some entity ->
          let tile = ctx.get_tile_at entity.pos in
          if Map.Tile.equal tile Map.Tile.Stairs_down then Ok 0
          else Error (Failure "Not on stairs down"))
  | Interact _ -> Error (Failure "Interact not implemented yet")
  | Pickup _ -> Error (Failure "Pickup not implemented yet")
  | Drop _ -> Error (Failure "Drop not implemented yet")
  | Attack _ -> Error (Failure "Attack not implemented yet")
