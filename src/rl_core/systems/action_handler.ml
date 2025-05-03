(* action_handler.ml
   This module interprets Actions as state transitions.
   All state queries/updates go through the State API.
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

let can_use_stairs_down state id =
  let pos = Position.get_exn id in
  match State.get_tile_at state pos.world_pos with
  | Some tile -> Dungeon.Tile.equal tile Dungeon.Tile.Stairs_down
  | None -> false

let can_use_stairs_up state id =
  let pos = Position.get_exn id in
  match State.get_tile_at state pos.world_pos with
  | Some tile -> Dungeon.Tile.equal tile Dungeon.Tile.Stairs_up
  | None -> false

(* ////////////////////////////// *)
(* ENTITY MANAGEMENT *)
(* ////////////////////////////// *)

(* let update_entity_stats (id : int) (state : State.t)
    (f : Stats.t -> Stats.t) : State.t =
  Entity_manager.update_entity_stats (State.get_entities_manager state) id f
  |> fun entities -> State.set_entities_manager entities state *)

(* let handle_entity_death (id : int) (state : State.t) : State.t =
  State.get_entity id state
  |> Option.bind ~f:(function
       | Types.Entity.Player _ ->
           Some
             (State.remove_entity id state
             |> State.remove_actor id
             |> State.set_turn_queue
                  (Turn_queue.remove_actor (State.get_turn_queue state) id))
       | Types.Entity.Creature (base, _) ->
           Logs.info (fun m -> m "Removing corpse for entity %d" id);

           Some
             (State.remove_entity id state
             |> State.spawn_corpse_entity
                  ~pos:(Position.get_exn base.id)
             |> State.remove_actor base.id
             |> State.set_turn_queue
                  (Turn_queue.remove_actor (State.get_turn_queue state) id))
       | _ -> None)
  |> Option.value ~default:state *)

let handle_move ~(state : State.t) ~(entity_id : int) ~(dir : Direction.t)
    ~handle_action : State.t * action_result =
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
    Logs.info (fun m ->
        m "old_chunk: %s, new_chunk: %s, crossed: %b"
          (Sexp.to_string (Chunk.sexp_of_chunk_coord old_chunk))
          (Sexp.to_string (Chunk.sexp_of_chunk_coord new_chunk))
          crossed);
    crossed
  in

  let old_local = world_to_local_coord pos.world_pos in
  Logs.info (fun m ->
      m "old_local: %s, new_pos: %s" (Loc.show old_local) (Loc.show new_pos));
  let wrapped_new_pos =
    if crossed_chunk_boundary then (
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
      Logs.info (fun m ->
          m "[WRAP] dir: %s, wrapped_new_pos: %s" (Direction.to_string dir)
            (Loc.show wrapped));
      wrapped)
    else new_pos
  in

  Logs.info (fun m -> m "Final move target: %s\n" (Loc.show wrapped_new_pos));

  match State.get_blocking_entity_at_pos wrapped_new_pos state with
  | Some target_entity -> (
      match Stats.get entity_id with
      | Some _ -> handle_action state entity_id (Action.Attack target_entity)
      | None -> (state, Error (Failure "Blocked by non-attackable entity")))
  | None -> (
      match State.get_tile_at state wrapped_new_pos with
      | Some tile when Dungeon.Tile.is_walkable tile ->
          ( Movement_system.move_entity ~entity_id ~go_to:wrapped_new_pos state,
            Ok 100 )
      | _ -> (state, Error (Failure "Cannot move here: terrain blocked")))

let rec handle_action (state : State.t) (entity_id : int) (action : Action.t) :
    State.t * action_result =
  match action with
  | Action.Wait -> (state, Ok 100)
  | Action.Move dir -> handle_move ~state ~entity_id ~dir ~handle_action
  | Action.StairsUp -> (
      let pos = Position.get_exn entity_id in
      match State.get_tile_at state pos.world_pos with
      | Some tile when Dungeon.Tile.equal tile Dungeon.Tile.Stairs_up ->
          (State.transition_to_previous_level state, Ok (-1))
      | _ -> (state, Error (Failure "Not on stairs up")))
  | Action.StairsDown -> (
      let pos = Position.get_exn entity_id in
      match State.get_tile_at state pos.world_pos with
      | Some tile when Dungeon.Tile.equal tile Dungeon.Tile.Stairs_down ->
          (State.transition_to_next_level state, Ok (-1))
      | _ -> (state, Error (Failure "Not on stairs down")))
  | Action.Attack target_id -> (
      let attacker_stats = Stats.get entity_id in
      let defender_stats = Stats.get target_id in
      match (attacker_stats, defender_stats) with
      | Some _, Some _ ->
          ( publish
              (EntityAttacked
                 { attacker_id = entity_id; defender_id = target_id })
              state,
            Ok 100 )
      | _ ->
          ( state,
            Error (Failure "Attacker or defender not found or missing stats") ))
  | Action.Interact _ -> (state, Error (Failure "Interact not implemented yet"))
  | Action.Pickup item_id -> (
      match Kind.get entity_id with
      | Some Kind.Player ->
          ( publish (ItemPickedUp { player_id = entity_id; item_id }) state,
            Ok 100 )
      | _ -> (state, Error (Failure "Pickup failed: invalid entity")))
  | Action.Drop item_id -> (
      match Kind.get entity_id with
      | Some Kind.Player ->
          ( publish (ItemDropped { player_id = entity_id; item_id }) state,
            Ok 100 )
      | _ -> (state, Error (Failure "Drop failed: invalid entity")))
