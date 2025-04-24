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

let make ~debug ~w ~h ~seed =
  Core_log.info (fun m -> m "Width: %d, Height: %d" w h);
  Core_log.info (fun m -> m "Creating state with seed: %d" seed);

  let entities = EntityManager.create () in
  let actor_manager = Actor_manager.create () in
  let turn_queue = Turn_queue.create () in

  let config = Mapgen.Config.make ~seed ~w ~h () in
  let map_manager = Map_manager.create ~config in
  {
    debug;
    entities;
    actor_manager;
    turn_queue;
    map_manager;
    mode = Types.CtrlMode.Normal;
    player_id = 0;
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
  EntityManager.find_unsafe (get_entities_manager state) state.player_id

let get_entity (id : Types.Entity.id) (state : t) : Types.Entity.t option =
  EntityManager.find (get_entities_manager state) id

let get_base_entity (id : Types.Entity.id) (state : t) :
    Types.Entity.base_entity =
  EntityManager.find_unsafe (get_entities_manager state) id |> Entity.get_base

let get_entity_at_pos (pos : Types.Loc.t) (state : t) : Types.Entity.t option =
  EntityManager.find_by_pos (get_entities_manager state) pos

let get_blocking_entity_at_pos (pos : Types.Loc.t) (state : t) :
    Types.Entity.t option =
  EntityManager.find_by_pos (get_entities_manager state) pos
  |> Option.bind ~f:(fun entity ->
         match Entity.get_blocking entity with
         | true -> Some entity
         | false -> None)

let get_entities (state : t) : Types.Entity.t list =
  EntityManager.to_list (get_entities_manager state)

let move_entity (id : Types.Entity.id) (loc : Types.Loc.t) (state : t) : t =
  let open Types.Entity in
  let new_entities =
    EntityManager.update (get_entities_manager state) id (fun ent ->
        match ent with
        | Player (base, data) -> Player ({ base with pos = loc }, data)
        | Creature (base, data) -> Creature ({ base with pos = loc }, data)
        | Item (base, data) -> Item ({ base with pos = loc }, data)
        | Corpse base -> Corpse { base with pos = loc })
  in
  set_entities_manager state new_entities

let remove_entity (id : Types.Entity.id) (state : t) : t =
  { state with entities = EntityManager.remove state.entities id }

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

let transition_to_next_level (state : t) : t =
  (* Save current level state *)
  let map_manager =
    Map_manager.save_level_state state.map_manager
      state.map_manager.current_level
      ~entities:(get_entities_manager state)
      ~actor_manager:state.actor_manager ~turn_queue:(get_turn_queue state)
  in

  (* Go to next level *)
  let map_manager = Map_manager.go_to_next_level map_manager in

  (* Get new map *)
  let new_dungeon = Map_manager.get_current_map map_manager in

  (* Either load existing level state or initialize new level *)
  let map_manager, _, _, _ =
    Map_manager.load_level_state map_manager state.map_manager.current_level
      ~entities:(get_entities_manager state)
      ~actor_manager:state.actor_manager ~turn_queue:(get_turn_queue state)
  in

  (* Position player at stairs_up in new level *)
  match new_dungeon.Tilemap.stairs_up with
  | Some stairs_pos ->
      let state = move_entity (get_player_id state) stairs_pos state in
      { state with map_manager }
  | None -> { state with map_manager }

let transition_to_previous_level (state : t) : t =
  (* Save current level state *)
  let map_manager =
    Map_manager.save_level_state state.map_manager
      state.map_manager.current_level
      ~entities:(get_entities_manager state)
      ~actor_manager:state.actor_manager ~turn_queue:state.turn_queue
  in

  (* Go to previous level *)
  let map_manager = Map_manager.go_to_previous_level map_manager in

  (* Get new map *)
  let new_dungeon = Map_manager.get_current_map map_manager in

  (* Either load existing level state or initialize new level *)
  let map_manager, _, _, _ =
    Map_manager.load_level_state map_manager state.map_manager.current_level
      ~entities:state.entities ~actor_manager:state.actor_manager
      ~turn_queue:state.turn_queue
  in

  (* Position player at stairs_down in previous level *)
  match new_dungeon.Tilemap.stairs_down with
  | Some stairs_pos ->
      let player_id = Entity.get_id (get_player_entity state) in
      let state = move_entity player_id stairs_pos state in
      { state with map_manager }
  | None -> { state with map_manager }

(* ////////////////////////////// *)
(* ACTION HANDLING *)
(* ////////////////////////////// *)

let spawn_player_entity ~pos ~direction (state : t) : t =
  let entities, _, _ =
    EntityManager.spawn_player state.entities ~pos ~direction
  in
  set_entities_manager state entities

let spawn_creature_entity (state : t) ~pos ~direction ~species ~health ~glyph
    ~name ~description : t * int =
  let entities, creature_actor_id, _new_entity =
    EntityManager.spawn_creature
      (get_entities_manager state)
      ~pos ~direction ~species ~health ~glyph ~name ~description
  in
  (set_entities_manager state entities, creature_actor_id)

let schedule_turn_now (id : Types.Entity.id) (state : t) : t =
  let turn_queue = Turn_queue.schedule_now (get_turn_queue state) id in
  set_turn_queue turn_queue state
