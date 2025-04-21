module Actor = Actor
module Tilemap = Map.Tilemap
module Tile = Map.Tile
open Base
open Mode
open Types
open Entity

let src = Logs.Src.create "backend" ~doc:"Backend"

module Log = (val Logs.src_log src : Logs.LOG)

type t = {
  seed : int;
  debug : bool;
  map : Tilemap.t;
  mode : CtrlMode.t;
  random : Random.State.t;
  entities : EntityManager.t;
  actor_manager : Actor_manager.t;
  turn_queue : Turn_queue.t;
  player : player;
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
  let map = Generator.generate ~config ~level:1 ~total_levels:5 in

  {
    debug;
    seed;
    random;
    map;
    entities;
    actor_manager;
    turn_queue;
    mode = CtrlMode.Normal;
    player = { entity_id = 0 };
  }

(* Helper function to get all entities *)
let get_entities (backend : t) : entity list =
  EntityManager.to_list backend.entities

let get_entity_manager (backend : t) : EntityManager.t = backend.entities
let get_actor_manager (backend : t) : Actor_manager.t = backend.actor_manager

let get_entity (backend : t) (entity_id : entity_id) : entity option =
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

let get_entity_at_pos (entities : EntityManager.t) (pos : loc) : entity option =
  EntityManager.find_by_pos entities pos

(* Helper function to get player entity *)
let get_player (backend : t) : entity =
  EntityManager.find_unsafe backend.entities backend.player.entity_id

let get_player_actor (backend : t) : Actor.t =
  let player = get_player backend in
  match player.data with
  | PlayerData { actor_id; _ } ->
      Actor_manager.get_unsafe backend.actor_manager actor_id
  | _ -> failwith "Player actor not found"

let get_actor (backend : t) (entity_id : entity_id) : Actor.t =
  let entity = EntityManager.find_unsafe backend.entities entity_id in
  match entity.data with
  | PlayerData { actor_id; _ } | CreatureData { actor_id; _ } ->
      Actor_manager.get_unsafe backend.actor_manager actor_id
  | _ -> failwith "Actor not found"

let move_entity (backend : t) (entity_id : entity_id) (x : int) (y : int) : unit
    =
  EntityManager.update backend.entities entity_id (fun ent ->
      { ent with pos = (x, y) })

let handle_action (backend : t) (entity_id : Types.entity_id)
    (action : Action.action_type) : (int, exn) Result.t =
  match action with
  | Move dir -> (
      (* Example movement logic *)
      match get_entity backend entity_id with
      | None -> Error (Failure "Entity not found")
      | Some entity ->
          let x, y = entity.pos in
          let dx, dy =
            match dir with
            | Types.North -> (0, -1)
            | Types.South -> (0, 1)
            | Types.East -> (1, 0)
            | Types.West -> (-1, 0)
          in
          let new_x = x + dx in
          let new_y = y + dy in
          let within_bounds =
            new_x >= 0
            && new_x < Tilemap.get_width backend.map
            && new_y >= 0
            && new_y < Tilemap.get_height backend.map
          in
          let walkable =
            Tile.is_walkable (Tilemap.get_tile backend.map new_x new_y)
          in
          if within_bounds && walkable then (
            move_entity backend entity_id new_x new_y;
            Ok 100)
          else Error (Failure "Cannot move here"))
  | Wait -> Ok 100
  | StairsUp -> (
      match get_entity backend entity_id with
      | None -> Error (Failure "Entity not found")
      | Some entity ->
          let x, y = entity.pos in
          let tile = Tilemap.get_tile backend.map x y in
          if Tile.equal tile Tile.Stairs_up then Ok 100
          else Error (Failure "Not on stairs up"))
  | StairsDown -> (
      match get_entity backend entity_id with
      | None -> Error (Failure "Entity not found")
      | Some entity ->
          let x, y = entity.pos in
          let tile = Tilemap.get_tile backend.map x y in
          if Tile.equal tile Tile.Stairs_down then Ok 100
          else Error (Failure "Not on stairs down"))
  | Interact _ -> Error (Failure "Interact not implemented yet")
  | Pickup _ -> Error (Failure "Pickup not implemented yet")
  | Drop _ -> Error (Failure "Drop not implemented yet")
