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

(* Calculate damage based on attacker and defender stats *)
let calculate_damage ~attacker_stats ~defender_stats =
  let base_damage =
    attacker_stats.Stats.attack - defender_stats.Stats.defense
  in
  let damage = max 1 base_damage in
  (* Ensure at least 1 damage *)
  damage

(* Get stats from an entity if it has them *)
let get_entity_stats (entity : Entity.entity) =
  match entity.data with
  | Some (Entity.PlayerData { stats; _ }) -> Some stats
  | Some (Entity.CreatureData { stats; _ }) -> Some stats
  | _ -> None

(* Handle an action for a given entity *)
let handle_action (ctx : action_context) (entity_id : Entity.entity_id)
    (action : Action.t) : action_result =
  match action with
  | Wait -> Ok 100
  | Move dir -> (
      match ctx.get_entity entity_id with
      | None -> Error (Failure "Entity not found")
      | Some entity -> (
          let delta = Direction.to_point dir in
          let new_pos = Types.Loc.(entity.pos + delta) in
          let within_bounds = ctx.in_bounds new_pos in
          let walkable = Map.Tile.is_walkable (ctx.get_tile_at new_pos) in

          (* Check if there's an entity at the target position *)
          match ctx.get_entity_at_pos new_pos with
          | Some target_entity -> (
              (* If there's an entity, check if it can be attacked *)
              match get_entity_stats target_entity with
              | Some _ ->
                  (* Convert to an Attack action *)
                  Error
                    (Failure
                       ("Entity at position: " ^ string_of_int target_entity.id))
              | None ->
                  (* Can't attack entities without stats *)
                  Error (Failure "Cannot move here: blocked by entity"))
          | None ->
              (* No entity, proceed with normal movement check *)
              if within_bounds && walkable then Ok 100
              else Error (Failure "Cannot move here: terrain blocked")))
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
  | Attack target_id -> (
      match (ctx.get_entity entity_id, ctx.get_entity target_id) with
      | Some attacker, Some defender -> (
          (* Check if both entities have stats *)
          match (get_entity_stats attacker, get_entity_stats defender) with
          | Some attacker_stats, Some defender_stats ->
              (* Calculate damage *)
              let damage = calculate_damage ~attacker_stats ~defender_stats in
              (* Return success with time cost *)
              Ok 100
          | _ -> Error (Failure "Cannot attack: missing stats"))
      | _ -> Error (Failure "Attacker or defender not found"))
  | Interact _ -> Error (Failure "Interact not implemented yet")
  | Pickup _ -> Error (Failure "Pickup not implemented yet")
  | Drop _ -> Error (Failure "Drop not implemented yet")
