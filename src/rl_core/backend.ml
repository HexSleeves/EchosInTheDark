module Actions = Actions
module Actor = Actor
module EntityManager = Entity_manager
module Tile = Map.Tile
module Tilemap = Map.Tilemap

let src = Logs.Src.create "backend" ~doc:"Backend"

module Log = (val Logs.src_log src : Logs.LOG)

type t = {
  seed : int;
  debug : bool;
  map : Tilemap.t;
  mode : Types.CtrlMode.t;
  random : Random.State.t;
  entities : EntityManager.t;
  actor_manager : Actor_manager.t;
  turn_queue : Turn_queue.t;
  player : Types.player;
  multilevel : State.t;
}

let make ~debug ~w ~h ~seed =
  Logs.info (fun m -> m "Creating backend with seed: %d" seed);
  Logs.info (fun m -> m "Width: %d, Height: %d" w h);

  let random = Random.State.make [| seed |] in

  let entities = EntityManager.create () in
  let actor_manager = Actor_manager.create () in
  let turn_queue = Turn_queue.create () in

  let open Mapgen in
  let config = Config.default ~seed in
  let map = Generator.generate ~config ~level:1 in
  let multilevel = State.create ~config in
  {
    debug;
    seed;
    random;
    map;
    entities;
    actor_manager;
    turn_queue;
    multilevel;
    mode = Types.CtrlMode.Normal;
    player = { entity_id = 0 };
  }

(* Helper function to get all entities *)
let get_entities (backend : t) : Types.entity list =
  EntityManager.to_list backend.entities

let get_entity_manager (backend : t) : EntityManager.t = backend.entities
let get_actor_manager (backend : t) : Actor_manager.t = backend.actor_manager

let get_entity (backend : t) (entity_id : Types.entity_id) : Types.entity option
    =
  EntityManager.find backend.entities entity_id

let get_actor (backend : t) (actor_id : Actor_manager.actor_id) : Actor.t option
    =
  Actor_manager.get backend.actor_manager actor_id

let add_actor (backend : t) (actor : Actor.t)
    (actor_id : Actor_manager.actor_id) : t =
  Actor_manager.add backend.actor_manager actor_id actor;
  backend

let remove_actor (backend : t) (actor_id : Actor_manager.actor_id) : t =
  Actor_manager.remove backend.actor_manager actor_id;
  backend

let get_entity_at_pos (entities : EntityManager.t) (pos : Types.Loc.t) :
    Types.entity option =
  EntityManager.find_by_pos entities pos

(* Helper function to get player entity *)
let get_player (backend : t) : Types.entity =
  EntityManager.find_unsafe backend.entities backend.player.entity_id

let get_player_actor (backend : t) : Actor.t =
  let player = get_player backend in
  match player.data with
  | PlayerData { actor_id; _ } ->
      Actor_manager.get_unsafe backend.actor_manager actor_id
  | _ -> failwith "Player actor not found"

let direction_to_point (dir : Types.direction) : Types.Loc.t =
  let open Types in
  match dir with
  | North -> Loc.make 0 (-1)
  | South -> Loc.make 0 1
  | East -> Loc.make 1 0
  | West -> Loc.make (-1) 0

let move_entity (backend : t) (entity_id : Types.entity_id) (loc : Types.Loc.t)
    : unit =
  EntityManager.update backend.entities entity_id (fun ent ->
      { ent with pos = loc })

let transition_to_next_level backend multi_level ~config =
  (* Save current level state *)
  let multi_level =
    State.save_level_state multi_level multi_level.State.current_level
      ~entities:backend.entities ~actor_manager:backend.actor_manager
      ~turn_queue:backend.turn_queue
  in

  (* Go to next level *)
  let multi_level = State.go_to_next_level multi_level ~config in

  (* Get new map *)
  let new_map = State.get_current_map multi_level in

  (* Either load existing level state or initialize new level *)
  let multi_level =
    State.load_level_state multi_level multi_level.State.current_level
      ~entities:backend.entities ~actor_manager:backend.actor_manager
      ~turn_queue:backend.turn_queue
  in

  (* Position player at stairs_up in new level *)
  let player = get_player backend in
  match new_map.Tilemap.stairs_up with
  | Some stairs_pos ->
      move_entity backend player.id stairs_pos;
      ({ backend with map = new_map }, multi_level)
  | None ->
      (* Shouldn't happen since we always have stairs up except on level 1 *)
      ({ backend with map = new_map }, multi_level)

let transition_to_previous_level backend multi_level ~config =
  (* Save current level state *)
  let multi_level =
    State.save_level_state multi_level multi_level.State.current_level
      ~entities:backend.entities ~actor_manager:backend.actor_manager
      ~turn_queue:backend.turn_queue
  in

  (* Go to previous level *)
  let multi_level = State.go_to_previous_level multi_level ~config in

  (* Get new map *)
  let new_map = State.get_current_map multi_level in

  (* Either load existing level state or initialize new level *)
  let multi_level =
    State.load_level_state multi_level multi_level.State.current_level
      ~entities:backend.entities ~actor_manager:backend.actor_manager
      ~turn_queue:backend.turn_queue
  in

  (* Position player at stairs_down in previous level *)
  let player = get_player backend in
  match new_map.Tilemap.stairs_down with
  | Some stairs_pos ->
      move_entity backend player.id stairs_pos;
      ({ backend with map = new_map }, multi_level)
  | None ->
      (* Shouldn't happen since we always have stairs down except on last level *)
      ({ backend with map = new_map }, multi_level)

let can_use_stairs_down backend entity_id =
  match get_entity backend entity_id with
  | None -> false
  | Some entity ->
      let tile = Tilemap.get_tile backend.map entity.pos in
      Map.Tile.equal tile Map.Tile.Stairs_down

let can_use_stairs_up backend entity_id =
  match get_entity backend entity_id with
  | None -> false
  | Some entity ->
      let tile = Tilemap.get_tile backend.map entity.pos in
      Map.Tile.equal tile Map.Tile.Stairs_up

let handle_action (backend : t) (entity_id : Types.entity_id)
    (action : Action.action_type) : (int, exn) Result.t =
  let ctx =
    {
      Actions.get_entity = (fun id -> get_entity backend id);
      get_tile_at = (fun pos -> Tilemap.get_tile backend.map pos);
      in_bounds = (fun pos -> Tilemap.in_bounds backend.map pos);
      get_entity_at_pos = (fun pos -> get_entity_at_pos backend.entities pos);
    }
  in
  match Actions.handle_action ctx entity_id action with
  | Ok _ as ok ->
      (match action with
      | Move dir -> (
          match get_entity backend entity_id with
          | Some entity ->
              let delta = Utils.direction_to_point dir in
              let new_pos = Types.Loc.(entity.pos + delta) in
              move_entity backend entity_id new_pos
          | None -> ())
      | StairsUp -> (
          match get_entity backend entity_id with
          | Some entity ->
              let new_pos = Types.Loc.(entity.pos + Types.Loc.make 0 (-1)) in
              move_entity backend entity_id new_pos
          | None -> ())
      | StairsDown -> (
          match get_entity backend entity_id with
          | Some entity ->
              let new_pos = Types.Loc.(entity.pos + Types.Loc.make 0 1) in
              move_entity backend entity_id new_pos
          | None -> ())
      | _ -> ());
      ok
  | Error _ as err -> err
