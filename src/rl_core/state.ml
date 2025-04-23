module Actor = Actor_manager.Actor
module EntityManager = Entity_manager
module Tile = Map.Tile
module Tilemap = Map.Tilemap
module Entity = Types.Entity

type t = {
  seed : int;
  debug : bool;
  player_id : Entity.id;
  mode : Types.CtrlMode.t;
  random : Random.State.t;
  entities : EntityManager.t;
  actor_manager : Actor_manager.t;
  turn_queue : Turn_queue.t;
  map_manager : Map_manager.t;
}

let make ~debug ~w ~h ~seed =
  Core_log.info (fun m -> m "Creating state with seed: %d" seed);
  Core_log.info (fun m -> m "Width: %d, Height: %d" w h);

  let random = Random.State.make [| seed |] in

  let entities = EntityManager.create () in
  let actor_manager = Actor_manager.create () in
  let turn_queue = Turn_queue.create () in

  let config = Mapgen.Config.make ~seed ~w ~h () in
  let map_manager = Map_manager.create ~config in
  {
    debug;
    seed;
    random;
    entities;
    actor_manager;
    turn_queue;
    map_manager;
    mode = Types.CtrlMode.Normal;
    player_id = 0;
  }

let get_debug (state : t) : bool = state.debug
let get_mode (state : t) : Types.CtrlMode.t = state.mode
let set_mode (state : t) (mode : Types.CtrlMode.t) : t = { state with mode }

(* Entity manager *)
let get_entities_manager (state : t) : EntityManager.t = state.entities

let set_entities_manager (state : t) (entities : EntityManager.t) : t =
  { state with entities }

(* Actor manager *)
let get_actor_manager (state : t) : Actor_manager.t = state.actor_manager

let set_actor_manager (state : t) (actor_manager : Actor_manager.t) : t =
  { state with actor_manager }

(* Turn queue *)
let get_turn_queue (state : t) : Turn_queue.t = state.turn_queue

let set_turn_queue (state : t) (turn_queue : Turn_queue.t) : t =
  { state with turn_queue }

(* Map *)
let get_map_manager (state : t) : Map_manager.t = state.map_manager

let set_map_manager (state : t) (map_manager : Map_manager.t) : t =
  { state with map_manager }

(* Entity *)
let get_player_id (state : t) : Types.Entity.id = state.player_id

let get_player_entity (state : t) : Types.Entity.t =
  EntityManager.find_unsafe (get_entities_manager state) state.player_id

let get_entity (state : t) (id : Types.Entity.id) : Types.Entity.t option =
  EntityManager.find (get_entities_manager state) id

let get_base_entity (state : t) (id : Types.Entity.id) :
    Types.Entity.base_entity =
  EntityManager.find_unsafe (get_entities_manager state) id |> Entity.get_base

let get_entity_at_pos (state : t) (pos : Types.Loc.t) : Types.Entity.t option =
  EntityManager.find_by_pos (get_entities_manager state) pos

let get_entities (state : t) : Types.Entity.t list =
  EntityManager.to_list (get_entities_manager state)

let move_entity (state : t) (id : Types.Entity.id) (loc : Types.Loc.t) : t =
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

let remove_entity (state : t) (id : Types.Entity.id) : t =
  let entities = EntityManager.remove (get_entities_manager state) id in
  set_entities_manager state entities

(* Actor manager *)
let get_actor (state : t) (actor_id : Actor.actor_id) : Actor.t option =
  Actor_manager.get (get_actor_manager state) actor_id

let add_actor (state : t) (actor : Actor.t) (actor_id : Actor.actor_id) : t =
  let actor_manager =
    Actor_manager.add (get_actor_manager state) actor_id actor
  in
  set_actor_manager state actor_manager

let remove_actor (state : t) (actor_id : Actor.actor_id) : t =
  let actor_manager = Actor_manager.remove (get_actor_manager state) actor_id in
  set_actor_manager state actor_manager

let update_actor (state : t) (actor_id : Actor.actor_id)
    (f : Actor.t -> Actor.t) : t =
  let actor_manager =
    Actor_manager.update (get_actor_manager state) actor_id f
  in
  set_actor_manager state actor_manager

let queue_actor_action (state : t) (actor_id : Actor.actor_id)
    (action : Types.Action.t) : t =
  update_actor state actor_id (fun actor -> Actor.queue_action actor action)

(* ////////////////////////////// *)
(* LEVEL TRANSITION HELPERS *)
(* ////////////////////////////// *)
let get_current_map (state : t) : Tilemap.t =
  Map_manager.get_current_map state.map_manager

let transition_to_next_level (state : t) =
  (* Save current level state *)
  let map_manager =
    Map_manager.save_level_state state.map_manager
      state.map_manager.current_level
      ~entities:(get_entities_manager state)
      ~actor_manager:(get_actor_manager state)
      ~turn_queue:(get_turn_queue state)
  in

  (* Go to next level *)
  let map_manager = Map_manager.go_to_next_level map_manager in

  (* Get new map *)
  let new_map = Map_manager.get_current_map map_manager in

  (* Either load existing level state or initialize new level *)
  let map_manager, _, _, _ =
    Map_manager.load_level_state map_manager state.map_manager.current_level
      ~entities:(get_entities_manager state)
      ~actor_manager:(get_actor_manager state)
      ~turn_queue:(get_turn_queue state)
  in

  (* Position player at stairs_up in new level *)
  let player = get_player_entity state in
  match new_map.Tilemap.stairs_up with
  | Some stairs_pos ->
      let state = move_entity state (Entity.get_base player).id stairs_pos in
      ({ state with map_manager }, map_manager)
  | None -> ({ state with map_manager }, map_manager)

let transition_to_previous_level state =
  (* Save current level state *)
  let map_manager =
    Map_manager.save_level_state state.map_manager
      state.map_manager.current_level
      ~entities:(get_entities_manager state)
      ~actor_manager:(get_actor_manager state)
      ~turn_queue:(get_turn_queue state)
  in

  (* Go to previous level *)
  let map_manager = Map_manager.go_to_previous_level map_manager in

  (* Get new map *)
  let new_map = Map_manager.get_current_map map_manager in

  (* Either load existing level state or initialize new level *)
  let map_manager, _, _, _ =
    Map_manager.load_level_state map_manager state.map_manager.current_level
      ~entities:(get_entities_manager state)
      ~actor_manager:(get_actor_manager state)
      ~turn_queue:(get_turn_queue state)
  in

  (* Position player at stairs_down in previous level *)
  let player = get_player_entity state in
  match new_map.Tilemap.stairs_down with
  | Some stairs_pos ->
      let state = move_entity state (Entity.get_base player).id stairs_pos in
      ({ state with map_manager }, map_manager)
  | None -> ({ state with map_manager }, map_manager)

(* ////////////////////////////// *)
(* ACTION HANDLING *)
(* ////////////////////////////// *)

let spawn_player_entity (state : t) ~pos ~direction : t =
  let entities =
    EntityManager.spawn_player (get_entities_manager state) ~pos ~direction
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

let schedule_turn_now (state : t) (id : Types.Entity.id) : t =
  let turn_queue = Turn_queue.schedule_now (get_turn_queue state) id in
  set_turn_queue state turn_queue
