open Base

(* Delegate to split modules *)
let get_entities_manager = State_entities.get_entities_manager
let set_entities_manager = State_entities.set_entities_manager
let get_player_id = State_entities.get_player_id
let get_player_entity = State_entities.get_player_entity
let get_entity = State_entities.get_entity
let get_base_entity = State_entities.get_base_entity
let get_entity_at_pos = State_entities.get_entity_at_pos
let get_blocking_entity_at_pos = State_entities.get_blocking_entity_at_pos
let get_entities = State_entities.get_entities
let get_creatures = State_entities.get_creatures
let move_entity = State_entities.move_entity
let remove_entity = State_entities.remove_entity
let spawn_creature_entity = State_entities.spawn_creature_entity
let get_actor = State_actors.get_actor
let add_actor = State_actors.add_actor
let remove_actor = State_actors.remove_actor
let update_actor = State_actors.update_actor
let queue_actor_action = State_actors.queue_actor_action
let setup_entities_for_level = State_levels.setup_entities_for_level
let transition_to_next_level = State_levels.transition_to_next_level
let transition_to_previous_level = State_levels.transition_to_previous_level

let make ~debug ~w ~h ~seed ~current_level =
  Core_log.info (fun m -> m "Width: %d, Height: %d" w h);
  Core_log.info (fun m -> m "Creating state with seed: %d" seed);

  let actor_manager = Actors.Actor_manager.create () in
  let turn_queue = Turn_queue.create () in

  let config = Mapgen.Config.make ~seed ~w ~h () in
  let map_manager = Map_manager.create ~config ~current_level in

  (* Extract player_id from the first level's entity manager *)
  let entities = Map_manager.get_entities_by_level map_manager current_level in
  let player_id =
    Entities.Entity_manager.to_list entities
    |> List.find_map ~f:(function
         | Types.Entity.Player base -> Some base.id
         | _ -> None)
    |> Option.value_exn
         ~message:"No player entity found in first level entity manager"
  in

  let actor_manager, turn_queue =
    Entities.Entity_manager.to_list entities
    |> List.fold_left ~init:(actor_manager, turn_queue)
         ~f:(fun (am, tq) entity ->
           let base = Types.Entity.get_base entity in
           let actor =
             match entity with
             | Types.Entity.Player _ -> Actors.Actor_manager.create_player_actor
             | Types.Entity.Creature _ -> Actors.Actor_manager.create_rat_actor
             | _ -> Actors.Actor_manager.create_player_actor
           in
           let am = Actors.Actor_manager.add base.id actor am in
           let tq = Turn_queue.schedule_now tq base.id in
           (am, tq))
  in

  let state : State_types.t =
    {
      debug;
      entities;
      actor_manager;
      turn_queue;
      map_manager;
      player_id;
      mode = Types.CtrlMode.Normal;
    }
  in
  state

type t = State_types.t

let get_debug (state : t) : bool = (state : State_types.t).debug
let get_mode (state : t) : Types.CtrlMode.t = (state : State_types.t).mode

let set_mode (mode : Types.CtrlMode.t) (state : t) : t =
  { (state : State_types.t) with mode }

let get_turn_queue (state : t) : Turn_queue.t =
  (state : State_types.t).turn_queue

let set_turn_queue (turn_queue : Turn_queue.t) (state : t) : t =
  { (state : State_types.t) with turn_queue }

let get_current_map (state : t) : Dungeon.Tilemap.t =
  Map_manager.get_current_map (state : State_types.t).map_manager
