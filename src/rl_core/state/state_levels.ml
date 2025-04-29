open Base
open Entities
open Actors
open State_types
open Types

let setup_entities_for_level ~entities ~actor_manager ~turn_queue =
  Entity_manager.to_list entities
  |> List.fold_left ~init:(actor_manager, turn_queue)
       ~f:(fun (am, tq) entity_id ->
         let actor =
           match Components.Kind.get entity_id with
           | Some Player -> Actor_manager.create_player_actor
           | Some Creature -> Actor_manager.create_rat_actor
           | _ -> failwith "Unknown entity kind"
         in

         match Turn_queue.is_scheduled tq entity_id with
         | true -> (Actor_manager.add entity_id actor am, tq)
         | false ->
             ( Actor_manager.add entity_id actor am,
               Turn_queue.schedule_at tq entity_id 0 ))

let transition_to_next_level (state : State_types.t) : State_types.t =
  let map_manager, entities, actor_manager, turn_queue =
    Map_manager.save_level_state state.map_manager ~entities:state.entities
      ~actor_manager:state.actor_manager ~turn_queue:state.turn_queue
    |> Map_manager.go_to_next_level |> Map_manager.load_level_state
  in

  let state' =
    { state with entities } |> State_entities.add_entity state.player_id
  in

  (* schedule all entities including the newly spawned player *)
  let actor_manager, turn_queue =
    setup_entities_for_level ~entities:state'.entities ~actor_manager
      ~turn_queue:(Turn_queue.schedule_now turn_queue state'.player_id)
  in

  let new_state =
    State_utils.rebuild_position_index
      {
        state' with
        map_manager;
        turn_queue;
        actor_manager;
        mode = CtrlMode.Normal;
      }
  in

  match Map_manager.get_current_map map_manager with
  | Some dungeon ->
      Option.value_map dungeon.stairs_up ~default:new_state
        ~f:(fun stairs_pos ->
          State_entities.move_entity new_state.player_id stairs_pos new_state)
  | None -> new_state

let transition_to_previous_level (state : State_types.t) : State_types.t =
  let map_manager, entities, actor_manager, turn_queue =
    Map_manager.save_level_state state.map_manager ~entities:state.entities
      ~actor_manager:state.actor_manager ~turn_queue:state.turn_queue
    |> Map_manager.go_to_previous_level |> Map_manager.load_level_state
  in

  let new_state =
    State_utils.rebuild_position_index
      {
        state with
        map_manager;
        entities;
        actor_manager;
        turn_queue;
        mode = CtrlMode.Normal;
      }
  in

  match Map_manager.get_current_map map_manager with
  | Some dungeon ->
      Option.value_map dungeon.stairs_down ~default:new_state
        ~f:(fun stairs_pos ->
          State_entities.move_entity new_state.player_id stairs_pos new_state)
  | None -> new_state
