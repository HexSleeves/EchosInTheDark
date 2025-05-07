open Base
open Types
open Events.Event_bus
open Components
module Event_effects = Effect_event_system_integration

module Log =
  (val Logger.make_logger "action_handler" ~doc:"Action handler logs" ())

type action_result = (int, exn) Result.t

let default_action_result = Ok 100

(* Movement functions moved from movement_system.ml *)
let move_entity ~(entity_id : int) ~(go_to : Loc.t) (state : State_types.t) :
    State_types.t =
  let from_pos = Position.get_exn entity_id in
  let to_pos = Chunk_manager.make_position go_to in

  (* Update the Position component table *)
  State.move_entity entity_id to_pos state
  |> publish (EntityMoved { entity_id; from_pos; to_pos })

type move_result =
  | Moved
  | Blocked_by_entity of { target_id : entity }
  | Blocked_by_terrain

let try_move_entity ~(state : State.t) ~(entity_id : int) ~(dir : Direction.t) :
    State.t * move_result =
  let open Chunk_manager in
  let chunk_width = Constants.chunk_w in
  let chunk_height = Constants.chunk_h in

  let delta = Direction.to_point dir in
  let pos = Position.get_exn entity_id in
  let new_pos = Loc.(pos.world_pos + delta) in

  let crossed_chunk_boundary =
    let old_chunk = world_to_chunk_coord pos.world_pos in
    let new_chunk = world_to_chunk_coord new_pos in
    let crossed = not Poly.(old_chunk = new_chunk) in
    crossed
  in

  let old_local = world_to_local_coord pos.world_pos in
  let wrapped_new_pos =
    if crossed_chunk_boundary then
      let cx, cy = Loc.to_tuple (world_to_chunk_coord pos.world_pos) in

      let wrapped =
        match dir with
        | Direction.North ->
            let wrapped_cy = cy - 1 in
            Logs.info (fun m ->
                m "height: %d, cx: %d, cy: %d (wrapped_cy: %d)" chunk_height cx
                  cy wrapped_cy);
            Loc.make
              ((cx * chunk_width) + old_local.x)
              ((wrapped_cy * chunk_height) + (chunk_height - 1))
        | Direction.South ->
            let wrapped_cy = cy + 1 in
            Loc.make
              ((cx * chunk_width) + old_local.x)
              (wrapped_cy * chunk_height)
        | Direction.West ->
            let wrapped_cx = cx - 1 in
            Loc.make
              ((wrapped_cx * chunk_width) + (chunk_width - 1))
              ((cy * chunk_height) + old_local.y)
        | Direction.East ->
            let wrapped_cx = cx + 1 in
            Loc.make (wrapped_cx * chunk_width)
              ((cy * chunk_height) + old_local.y)
      in

      wrapped
    else new_pos
  in

  match State.get_blocking_entity_at_pos wrapped_new_pos state with
  | Some target_entity ->
      (state, Blocked_by_entity { target_id = target_entity })
  | None -> (
      match State.get_tile_at state wrapped_new_pos with
      | Some tile when Dungeon.Tile.is_walkable tile ->
          (move_entity ~entity_id ~go_to:wrapped_new_pos state, Moved)
      | _ -> (state, Blocked_by_terrain))

(* Direct implementation of item pickup without using event bus *)
let handle_pickup (state : State.t) (player_id : int) (item_id : int) : State.t
    =
  match Inventory.get player_id with
  | None -> state
  | Some inv -> (
      match Inventory.can_add_item inv with
      | false -> state
      | true ->
          let inv' =
            match Inventory.add_item inv item_id with
            | Ok inv' -> inv'
            | Error _ -> inv
          in
          Components.Inventory.set player_id inv';
          state)

(* Direct implementation of item drop without using event bus *)
let handle_drop (state : State.t) (player_id : int) (item_id : int) : State.t =
  match Inventory.get player_id with
  | None -> state
  | Some inv -> (
      match Inventory.remove_item inv item_id with
      | Error _ -> state
      | Ok inv' -> (
          Components.Inventory.set player_id inv';
          match Item.get item_id with
          | Some item ->
              State.move_entity item.id
                (Components.Position.get_exn player_id)
                state
          | None -> state))

(* Direct implementation of stairs usage without using event bus *)
let handle_stairs_up (state : State.t) (entity_id : int) : State.t =
  let pos = Position.get_exn entity_id in
  match State.get_tile_at state pos.world_pos with
  | Some tile when Dungeon.Tile.equal tile Dungeon.Tile.Stairs_up ->
      State.transition_to_previous_level state
  | _ -> state

(* Direct implementation of stairs usage without using event bus *)
let handle_stairs_down (state : State.t) (entity_id : int) : State.t =
  let pos = Position.get_exn entity_id in
  match State.get_tile_at state pos.world_pos with
  | Some tile when Dungeon.Tile.equal tile Dungeon.Tile.Stairs_down ->
      State.transition_to_next_level state
  | _ -> state

let handle_combat (state : State.t) (entity_id : int) (target_id : int) :
    State.t * action_result =
  let attacker_stats = Stats.get entity_id in
  let defender_stats = Stats.get target_id in
  match (attacker_stats, defender_stats) with
  | Some _, Some _ ->
      Event_effects.publish_event
        (EntityAttacked { attacker_id = entity_id; defender_id = target_id });

      (* Combat still uses event bus as it may need to notify multiple systems *)
      (state, default_action_result)
  | _ ->
      (state, Error (Failure "Attacker or defender not found or missing stats"))

let handle_move (state : State.t) (entity_id : int) (dir : Direction.t)
    handle_action : State.t * action_result =
  let new_state, move_result = try_move_entity ~state ~entity_id ~dir in
  match move_result with
  | Moved -> (new_state, default_action_result)
  | Blocked_by_entity { target_id } ->
      handle_action new_state entity_id (Action.Attack target_id)
  | Blocked_by_terrain ->
      (new_state, Error (Failure "Cannot move here: terrain blocked"))

let handle_teleport (state : State.t) (entity_id : int) (pos : Loc.t) :
    State.t * action_result =
  let to_pos = Position.make pos in
  let new_state = State.move_entity entity_id to_pos state in
  (new_state, default_action_result)

let rec handle_action (state : State.t) (entity_id : int) (action : Action.t) :
    State.t * action_result =
  match action with
  | Action.Wait -> (state, default_action_result)
  (* Stairs *)
  | Action.StairsUp -> (handle_stairs_up state entity_id, default_action_result)
  | Action.StairsDown ->
      (handle_stairs_down state entity_id, default_action_result)
  (* Movement *)
  | Action.Move dir -> handle_move state entity_id dir handle_action
  (* Combat *)
  | Action.Attack target_id -> handle_combat state entity_id target_id
  (* Item Pickup and Drop *)
  | Action.Pickup item_id -> (
      match Kind.get entity_id with
      | Some Kind.Player ->
          (handle_pickup state entity_id item_id, default_action_result)
      | _ -> (state, Error (Failure "Pickup failed: invalid entity")))
  | Action.Drop item_id -> (
      match Kind.get entity_id with
      | Some Kind.Player ->
          (handle_drop state entity_id item_id, default_action_result)
      | _ -> (state, Error (Failure "Drop failed: invalid entity")))
  (* Not Implemented *)
  | Action.Interact _ -> (state, Error (Failure "Interact not implemented yet"))
  | Action.Teleport pos -> (
      match Kind.get entity_id with
      | Some Kind.Player -> handle_teleport state entity_id pos
      | _ -> (state, Error (Failure "Teleport failed: invalid entity")))
