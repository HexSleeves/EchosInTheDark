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
             | Entity.Player _ ->
                 Actor_manager.create_player_actor ~next_turn_time:0
             | Entity.Creature _ ->
                 Actor_manager.create_rat_actor ~next_turn_time:0
             | _ -> Actor_manager.create_player_actor ~next_turn_time:0
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
  EntityManager.find_unsafe state.entities state.player_id

let get_entity (id : Types.Entity.id) (state : t) : Types.Entity.t option =
  EntityManager.find state.entities id

let get_base_entity (id : Types.Entity.id) (state : t) :
    Types.Entity.base_entity =
  EntityManager.find_unsafe state.entities id |> Entity.get_base

let get_entity_at_pos (pos : Types.Loc.t) (state : t) : Types.Entity.t option =
  EntityManager.find_by_pos state.entities pos

let get_blocking_entity_at_pos (pos : Types.Loc.t) (state : t) :
    Types.Entity.t option =
  EntityManager.find_by_pos state.entities pos
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
    EntityManager.update state.entities id (fun ent ->
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
  let map_manager, new_dungeon =
    let mm =
      Map_manager.save_level_state state.map_manager
        state.map_manager.current_level ~entities:state.entities
        ~actor_manager:state.actor_manager ~turn_queue:state.turn_queue
    in

    (* Go to next level and get the new map *)
    (Map_manager.go_to_next_level mm, Map_manager.get_current_map mm)
  in

  (* Either load existing level state or initialize new level *)
  (* let map_manager, entities, actor_manager, turn_queue =
    Map_manager.load_level_state map_manager map_manager.current_level
      ~entities:state.entities ~actor_manager:state.actor_manager
      ~turn_queue:state.turn_queue
  in *)

  (* Find entities and insert player at 0 *)
  let entities =
    Hashtbl.find_exn map_manager.entities_by_level map_manager.current_level
  in
  let player = get_player_entity state in
  let entities = EntityManager.add entities player in

  let actor_manager =
    Actor_manager.restore state.actor_manager
      (Hashtbl.find_exn map_manager.actor_manager_by_level
         (map_manager.current_level - 1))
  in
  let turn_queue =
    Turn_queue.restore state.turn_queue
      (Hashtbl.find_exn map_manager.turn_queue_by_level
         (map_manager.current_level - 1))
  in

  EntityManager.print_entity_manager entities;
  Actor_manager.print_actor_manager actor_manager;
  Turn_queue.print_queue turn_queue;

  let new_state =
    {
      state with
      map_manager;
      entities;
      actor_manager;
      turn_queue;
      mode = Types.CtrlMode.WaitInput;
    }
  in

  match new_dungeon.Tilemap.stairs_up with
  | Some stairs_pos ->
      let state = move_entity state.player_id stairs_pos new_state in
      { state with map_manager; entities; actor_manager; turn_queue }
  | None -> new_state

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
  new_dungeon.Tilemap.stairs_down
  |> Option.value_map ~default:{ state with map_manager } ~f:(fun stairs_pos ->
         let player_id = Entity.get_id (get_player_entity state) in
         let state = move_entity player_id stairs_pos state in
         { state with map_manager })

(* ////////////////////////////// *)
(* ACTION HANDLING *)
(* ////////////////////////////// *)

let schedule_turn_now (id : Types.Entity.id) (state : t) : t =
  let turn_queue = Turn_queue.schedule_now (get_turn_queue state) id in
  set_turn_queue turn_queue state

let spawn_creature_entity (state : t) ~pos ~direction ~species ~health ~glyph
    ~name ~description ~faction : t * int =
  let entities, creature_actor_id, _new_entity =
    EntityManager.spawn_creature
      (get_entities_manager state)
      ~pos ~direction ~species ~health ~glyph ~name ~description ~faction
  in
  (set_entities_manager state entities, creature_actor_id)
