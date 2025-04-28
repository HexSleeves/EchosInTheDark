open Base
module Actor = Actor_manager.Actor
module EntityManager = Entity_manager
module Tile = Dungeon.Tile
module Tilemap = Dungeon.Tilemap
module Entity = Types.Entity

type t = {
  debug : bool;
  player_id : Entity.id;
  mode : Types.CtrlMode.t;
  entities : EntityManager.t;
  actor_manager : Actor_manager.t;
  turn_queue : Turn_queue.t;
  map_manager : Map_manager.t;
}

let make ~debug ~w ~h ~seed ~current_level =
  Core_log.info (fun m -> m "Width: %d, Height: %d" w h);
  Core_log.info (fun m -> m "Creating state with seed: %d" seed);

  let actor_manager = Actor_manager.create () in
  let turn_queue = Turn_queue.create () in

  let config = Mapgen.Config.make ~seed ~w ~h () in
  let map_manager = Map_manager.create ~config ~current_level in

  (* Extract player_id from the first level's entity manager *)
  let entities = Hashtbl.find_exn map_manager.entities_by_level current_level in
  let player_id =
    EntityManager.to_list entities
    |> List.find_map ~f:(function
         | Entity.Player (base, _) -> Some base.id
         | _ -> None)
    |> Option.value_exn
         ~message:"No player entity found in first level entity manager"
  in

  let actor_manager, turn_queue =
    EntityManager.to_list entities
    |> List.fold_left ~init:(actor_manager, turn_queue)
         ~f:(fun (am, tq) entity ->
           let base = Entity.get_base entity in
           let actor =
             match entity with
             | Entity.Player _ -> Actor_manager.create_player_actor
             | Entity.Creature _ -> Actor_manager.create_rat_actor
             | _ -> Actor_manager.create_player_actor
           in
           let am = Actor_manager.add base.id actor am in
           let tq = Turn_queue.schedule_now tq base.id in
           (am, tq))
  in

  {
    debug;
    entities;
    actor_manager;
    turn_queue;
    map_manager;
    player_id;
    mode = Types.CtrlMode.Normal;
  }

let get_debug (state : t) : bool = state.debug
let get_mode (state : t) : Types.CtrlMode.t = state.mode
let set_mode (mode : Types.CtrlMode.t) (state : t) : t = { state with mode }

(* Entity manager *)
let get_entities_manager (state : t) : EntityManager.t = state.entities

let set_entities_manager (state : t) (entities : EntityManager.t) : t =
  { state with entities }

(* Actor manager *)

let set_actor_manager (state : t) (actor_manager : Actor_manager.t) : t =
  { state with actor_manager }

(* Turn queue *)
let get_turn_queue (state : t) : Turn_queue.t = state.turn_queue

let set_turn_queue (turn_queue : Turn_queue.t) (state : t) : t =
  { state with turn_queue }

(* Entity *)

let get_player_id (state : t) : Types.Entity.id = state.player_id

let get_player_entity (state : t) : Types.Entity.t =
  EntityManager.find_unsafe state.player_id state.entities

let get_entity (id : Types.Entity.id) (state : t) : Types.Entity.t option =
  EntityManager.find id state.entities

let get_base_entity (id : Types.Entity.id) (state : t) :
    Types.Entity.base_entity =
  EntityManager.find_unsafe id state.entities |> Entity.get_base

let get_entity_at_pos (pos : Types.Loc.t) (state : t) : Types.Entity.t option =
  EntityManager.find_by_pos pos state.entities

let get_blocking_entity_at_pos (pos : Types.Loc.t) (state : t) :
    Types.Entity.t option =
  EntityManager.find_by_pos pos state.entities
  |> Option.filter ~f:Entity.get_blocking

let get_entities (state : t) : Types.Entity.t list =
  EntityManager.to_list state.entities

let get_creatures (state : t) :
    (Types.Entity.base_entity * Types.Entity.creature_data) list =
  EntityManager.to_list state.entities
  |> List.filter_map ~f:(function
       | Entity.Creature (base, data) -> Some (base, data)
       | _ -> None)

let move_entity (id : Types.Entity.id) (loc : Types.Loc.t) (state : t) : t =
  let open Types.Entity in
  let new_entities =
    EntityManager.update id
      (fun ent ->
        match ent with
        | Player (base, data) -> Player ({ base with pos = loc }, data)
        | Creature (base, data) -> Creature ({ base with pos = loc }, data)
        | Item (base, data) -> Item ({ base with pos = loc }, data)
        | Corpse base -> Corpse { base with pos = loc })
      state.entities
  in
  set_entities_manager state new_entities

let remove_entity (id : Types.Entity.id) (state : t) : t =
  { state with entities = EntityManager.remove id state.entities }

(* Actor manager *)
let get_actor (state : t) (actor_id : Actor.actor_id) : Actor.t option =
  Actor_manager.get actor_id state.actor_manager

let add_actor (actor : Actor.t) (actor_id : Actor.actor_id) (state : t) : t =
  Actor_manager.add actor_id actor state.actor_manager
  |> set_actor_manager state

let remove_actor (actor_id : Actor.actor_id) (state : t) : t =
  {
    state with
    actor_manager = Actor_manager.remove actor_id state.actor_manager;
  }

let update_actor (state : t) (actor_id : Actor.actor_id)
    (f : Actor.t -> Actor.t) : t =
  Actor_manager.update actor_id f state.actor_manager |> set_actor_manager state

let queue_actor_action (state : t) (actor_id : Actor.actor_id)
    (action : Types.Action.t) : t =
  update_actor state actor_id (fun actor -> Actor.queue_action actor action)

(* ////////////////////////////// *)
(* LEVEL TRANSITION HELPERS *)
(* ////////////////////////////// *)
let get_current_map (state : t) : Tilemap.t =
  Map_manager.get_current_map state.map_manager

let setup_entities_for_level ~entities ~actor_manager ~turn_queue =
  EntityManager.to_list entities
  |> List.fold_left ~init:(actor_manager, turn_queue) ~f:(fun (am, tq) entity ->
         let base = Entity.get_base entity in
         let actor =
           match entity with
           | Entity.Player _ -> Actor_manager.create_player_actor
           | Entity.Creature _ -> Actor_manager.create_rat_actor
           | _ -> Actor_manager.create_player_actor
         in
         (Actor_manager.add base.id actor am, Turn_queue.schedule_now tq base.id))

let transition_to_next_level (state : t) : t =
  let current_player =
    Option.value_exn
      (Entity_manager.find_player state.entities)
      ~message:"Player not found (should not happen)"
  in

  Core_log.info (fun m ->
      m "Transitioning to next level from %d" state.map_manager.current_level);

  (* Save current level state *)
  let map_manager, entities, actor_manager, turn_queue =
    Map_manager.save_level_state state.map_manager
      state.map_manager.current_level ~entities:state.entities
      ~actor_manager:state.actor_manager ~turn_queue:state.turn_queue
    |> Map_manager.go_to_next_level |> Map_manager.load_level_state
  in

  Entity_manager.print_entity_manager_ids entities;

  let entities = Entity_manager.add current_player entities in
  let player_id =
    Option.value_exn
      (Entity_manager.find_player_id entities)
      ~message:"Player not found (should not happen)"
  in

  let actor_manager, turn_queue =
    setup_entities_for_level ~entities ~actor_manager ~turn_queue
  in

  Turn_queue.print_turn_queue turn_queue;

  let new_state =
    {
      state with
      entities;
      player_id;
      map_manager;
      turn_queue;
      actor_manager;
      mode = Types.CtrlMode.Normal;
    }
  in

  (* Get new map *)
  let new_dungeon = Map_manager.get_current_map map_manager in

  Option.value_map new_dungeon.stairs_up ~default:new_state
    ~f:(fun stairs_pos -> move_entity new_state.player_id stairs_pos new_state)

let transition_to_previous_level (state : t) : t =
  (* Save current level state *)
  let map_manager =
    Map_manager.save_level_state state.map_manager
      state.map_manager.current_level ~entities:state.entities
      ~actor_manager:state.actor_manager ~turn_queue:state.turn_queue
  in

  (* Go to previous level *)
  let map_manager = Map_manager.go_to_previous_level map_manager in

  (* Get new map *)
  let new_dungeon = Map_manager.get_current_map map_manager in

  (* Either load existing level state or initialize new level *)
  let map_manager, entities, actor_manager, turn_queue =
    Map_manager.load_level_state map_manager
  in

  let new_state =
    {
      state with
      map_manager;
      entities;
      actor_manager;
      turn_queue;
      mode = Types.CtrlMode.Normal;
    }
  in

  Option.value_map new_dungeon.stairs_down ~default:new_state
    ~f:(fun stairs_pos -> move_entity new_state.player_id stairs_pos new_state)

(* ////////////////////////////// *)
(* ACTION HANDLING *)
(* ////////////////////////////// *)

(* let schedule_turn_now (id : Types.Entity.id) (state : t) : t =
  let turn_queue = Turn_queue.schedule_now (get_turn_queue state) id in
  set_turn_queue turn_queue state *)

let spawn_creature_entity (state : t) ~pos ~direction ~species ~health ~glyph
    ~name ~description ~faction : t =
  EntityManager.spawn_creature state.entities ~pos ~direction ~species ~health
    ~glyph ~name ~description ~faction
  |> set_entities_manager state
