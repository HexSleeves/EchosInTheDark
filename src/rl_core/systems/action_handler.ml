(* action_handler.ml
   This module interprets Actions as state transitions.
   All state queries/updates go through the State API.

   SIMPLIFIED: Direct handling of actions without event bus for simple cases
*)

open Base
open Rl_types
open Events.Event_bus
open Components
module Log = (val Core_log.make_logger "action_handler" : Logs.LOG)

type action_result = (int, exn) Result.t

let is_entity_dead (id : int) : bool =
  Stats.get id
  |> Base.Option.value_map ~default:false ~f:(fun stats ->
         Stats.Stats_data.get_hp stats <= 0)

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
      (* Combat still uses event bus as it may need to notify multiple systems *)
      ( publish
          (EntityAttacked { attacker_id = entity_id; defender_id = target_id })
          state,
        Ok 100 )
  | _ ->
      (state, Error (Failure "Attacker or defender not found or missing stats"))

let handle_move (state : State.t) (entity_id : int) (dir : Direction.t)
    handle_action : State.t * action_result =
  let new_state, move_result =
    Movement_system.try_move_entity ~state ~entity_id ~dir
  in
  match move_result with
  | Moved -> (new_state, Ok 100)
  | Blocked_by_entity { target_id } ->
      handle_action new_state entity_id (Action.Attack target_id)
  | Blocked_by_terrain ->
      (new_state, Error (Failure "Cannot move here: terrain blocked"))

let handle_teleport (state : State.t) (entity_id : int) (pos : Loc.t) :
    State.t * action_result =
  let to_pos = Position.make pos in
  let new_state = State.move_entity entity_id to_pos state in
  (new_state, Ok 100)

let rec handle_action (state : State.t) (entity_id : int) (action : Action.t) :
    State.t * action_result =
  match action with
  | Action.Wait -> (state, Ok 100)
  (* Stairs *)
  | Action.StairsUp -> (handle_stairs_up state entity_id, Ok 0)
  | Action.StairsDown -> (handle_stairs_down state entity_id, Ok 0)
  (* Movement *)
  | Action.Move dir -> handle_move state entity_id dir handle_action
  (* Combat *)
  | Action.Attack target_id -> handle_combat state entity_id target_id
  (* Item Pickup and Drop *)
  | Action.Pickup item_id -> (
      match Kind.get entity_id with
      | Some Kind.Player -> (handle_pickup state entity_id item_id, Ok 100)
      | _ -> (state, Error (Failure "Pickup failed: invalid entity")))
  | Action.Drop item_id -> (
      match Kind.get entity_id with
      | Some Kind.Player -> (handle_drop state entity_id item_id, Ok 100)
      | _ -> (state, Error (Failure "Drop failed: invalid entity")))
  (* Not Implemented *)
  | Action.Interact _ -> (state, Error (Failure "Interact not implemented yet"))
  | Action.Teleport pos -> (
      match Kind.get entity_id with
      | Some Kind.Player -> handle_teleport state entity_id pos
      | _ -> (state, Error (Failure "Teleport failed: invalid entity")))
