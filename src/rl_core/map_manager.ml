open Base
open Entities
open Actors

type t = {
  current_level : int;
  total_levels : int;
  player_has_amulet : bool;
  maps : (int, Dungeon.Tilemap.t) Hashtbl.t;
  entities_by_level : (int, Entity_manager.t) Hashtbl.t;
  actor_manager_by_level : (int, Actor_manager.t) Hashtbl.t;
  turn_queue_by_level : (int, Turn_queue.t) Hashtbl.t;
  config : Mapgen.Config.t;
}

let create ~(config : Mapgen.Config.t) ~current_level =
  let maps = Hashtbl.create (module Int) in
  let entities_by_level = Hashtbl.create (module Int) in
  let actor_manager_by_level = Hashtbl.create (module Int) in
  let turn_queue_by_level = Hashtbl.create (module Int) in

  (* Generate first level map *)
  let total_levels = config.max_levels in
  let first_map, first_entities, _ =
    Mapgen.Generator.generate ~config ~level:current_level
  in
  Hashtbl.set maps ~key:current_level ~data:first_map;
  Hashtbl.set entities_by_level ~key:current_level ~data:first_entities;

  {
    maps;
    config;
    total_levels;
    current_level;
    entities_by_level;
    turn_queue_by_level;
    actor_manager_by_level;
    player_has_amulet = false;
  }

let get_current_map t = Hashtbl.find t.maps t.current_level
let get_current_entities t = Hashtbl.find t.entities_by_level t.current_level
let can_go_to_previous_level t = t.current_level > 1
let can_go_to_next_level t = t.current_level < t.total_levels

let get_entities_by_level t level =
  Hashtbl.find t.entities_by_level level
  |> Option.value ~default:(Entity_manager.create ())

let get_current_level t = t.current_level

let ensure_level_exists t level =
  if not (Hashtbl.mem t.maps level) then (
    let new_map, new_entities, _ =
      Mapgen.Generator.generate ~config:t.config ~level
    in

    Hashtbl.set t.maps ~key:level ~data:new_map;
    Hashtbl.set t.entities_by_level ~key:level ~data:new_entities;
    Hashtbl.set t.actor_manager_by_level ~key:level
      ~data:(Actor_manager.create ());
    Hashtbl.set t.turn_queue_by_level ~key:level ~data:(Turn_queue.create ()))

let go_to_previous_level t =
  if can_go_to_previous_level t then (
    let prev_level = t.current_level - 1 in
    ensure_level_exists t prev_level;
    { t with current_level = prev_level })
  else t

let go_to_next_level t =
  if can_go_to_next_level t then (
    let next_level = t.current_level + 1 in
    ensure_level_exists t next_level;
    { t with current_level = next_level })
  else t

let save_level_state t ~entities ~actor_manager ~turn_queue =
  let current_level = get_current_level t in

  Hashtbl.set t.entities_by_level ~key:current_level
    ~data:(Entity_manager.copy entities);
  Hashtbl.set t.actor_manager_by_level ~key:current_level
    ~data:(Actor_manager.copy actor_manager);
  Hashtbl.set t.turn_queue_by_level ~key:current_level
    ~data:(Turn_queue.copy turn_queue);
  t

let load_level_state t =
  let open Option in
  let level = t.current_level in
  let default =
    (t, Entity_manager.create (), Actor_manager.create (), Turn_queue.create ())
  in
  value_map (Hashtbl.find t.entities_by_level level) ~default
    ~f:(fun saved_entities ->
      match
        ( Hashtbl.find t.actor_manager_by_level level,
          Hashtbl.find t.turn_queue_by_level level )
      with
      | Some actor_manager, Some turn_queue ->
          (t, saved_entities, actor_manager, turn_queue)
      | _ -> default)
