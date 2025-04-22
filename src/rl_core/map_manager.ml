type t = {
  current_level : int;
  total_levels : int;
  player_has_amulet : bool;
  maps : (Base.int, Map.Tilemap.t) Base.Hashtbl.t;
  entities_by_level : (Base.int, Entity_manager.t) Base.Hashtbl.t;
  actor_manager_by_level : (Base.int, Actor_manager.t) Base.Hashtbl.t;
  turn_queue_by_level : (Base.int, Turn_queue.t) Base.Hashtbl.t;
  config : Mapgen.Config.t;
}

let create ~(config : Mapgen.Config.t) =
  let maps = Base.Hashtbl.create (module Base.Int) in
  let entities_by_level = Base.Hashtbl.create (module Base.Int) in
  let actor_manager_by_level = Base.Hashtbl.create (module Base.Int) in
  let turn_queue_by_level = Base.Hashtbl.create (module Base.Int) in

  (* Generate first level map *)
  let total_levels = config.max_levels in
  let first_map = Mapgen.Generator.generate ~config ~level:1 in
  Base.Hashtbl.set maps ~key:1 ~data:first_map;

  {
    maps;
    current_level = 1;
    total_levels;
    player_has_amulet = false;
    entities_by_level;
    actor_manager_by_level;
    turn_queue_by_level;
    config;
  }

let get_current_map t = Base.Hashtbl.find_exn t.maps t.current_level
let can_go_to_previous_level t = t.current_level > 1
let can_go_to_next_level t = t.current_level < t.total_levels

let ensure_level_exists t level =
  if not (Base.Hashtbl.mem t.maps level) then
    let new_map = Mapgen.Generator.generate ~config:t.config ~level in
    Base.Hashtbl.set t.maps ~key:level ~data:new_map

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

let save_level_state t level ~entities ~actor_manager ~turn_queue =
  Base.Hashtbl.set t.entities_by_level ~key:level
    ~data:(Entity_manager.copy entities);
  Base.Hashtbl.set t.actor_manager_by_level ~key:level
    ~data:(Actor_manager.copy actor_manager);
  Base.Hashtbl.set t.turn_queue_by_level ~key:level
    ~data:(Turn_queue.copy turn_queue);
  t

let load_level_state t level ~entities ~actor_manager ~turn_queue =
  match Base.Hashtbl.find t.entities_by_level level with
  | Some saved_entities ->
      let entities = Entity_manager.restore entities saved_entities in
      Actor_manager.restore actor_manager
        (Base.Hashtbl.find_exn t.actor_manager_by_level level);
      Turn_queue.restore turn_queue
        (Base.Hashtbl.find_exn t.turn_queue_by_level level);
      (t, entities, actor_manager, turn_queue)
  | None ->
      (* New level, nothing to restore *)
      (t, entities, actor_manager, turn_queue)
