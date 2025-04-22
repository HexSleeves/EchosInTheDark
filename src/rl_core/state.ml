module Actor = Actor_manager.Actor
module EntityManager = Entity_manager
module Tile = Map.Tile
module Tilemap = Map.Tilemap

type t = {
  seed : int;
  debug : bool;
  mode : Types.CtrlMode.t;
  random : Random.State.t;
  entities : EntityManager.t;
  actor_manager : Actor_manager.t;
  turn_queue : Turn_queue.t;
  player : Types.Entity.player;
  map_manager : Map_manager.t;
}

let make ~debug ~w ~h ~seed =
  Core_log.info (fun m -> m "Creating backend with seed: %d" seed);
  Core_log.info (fun m -> m "Width: %d, Height: %d" w h);

  let random = Random.State.make [| seed |] in

  let entities = EntityManager.create () in
  let actor_manager = Actor_manager.create () in
  let turn_queue = Turn_queue.create () in

  let open Mapgen in
  let config = Config.default ~seed in
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
    player = { entity_id = 0 };
  }

let is_player (backend : t) (entity_id : Types.Entity.entity_id) : bool =
  match EntityManager.find backend.entities entity_id with
  | Some entity -> (
      match entity.data with
      | Some (Types.Entity.PlayerData _) -> true
      | _ -> false)
  | None -> false

(* Helper function to get player entity *)
let get_player (backend : t) : Types.Entity.entity =
  EntityManager.find_unsafe backend.entities backend.player.entity_id

let get_entity (backend : t) (entity_id : Types.Entity.entity_id) :
    Types.Entity.entity option =
  EntityManager.find backend.entities entity_id

let get_entity_at_pos (entities : EntityManager.t) (pos : Types.Loc.t) :
    Types.Entity.entity option =
  EntityManager.find_by_pos entities pos

let move_entity (backend : t) (entity_id : Types.Entity.entity_id)
    (loc : Types.Loc.t) : t =
  let new_entities =
    EntityManager.update backend.entities entity_id (fun ent ->
        { ent with pos = loc })
  in
  { backend with entities = new_entities }

(* Helper function to get all entities *)
let get_entities (backend : t) : Types.Entity.entity list =
  EntityManager.to_list backend.entities

let get_entity_at_pos (entities : EntityManager.t) (pos : Types.Loc.t) :
    Types.Entity.entity option =
  EntityManager.find_by_pos entities pos

let get_actor (backend : t) (actor_id : Actor.actor_id) : Actor.t option =
  Actor_manager.get backend.actor_manager actor_id

let add_actor (backend : t) (actor : Actor.t) (actor_id : Actor.actor_id) : t =
  let actor_manager = Actor_manager.add backend.actor_manager actor_id actor in
  { backend with actor_manager }

let remove_actor (backend : t) (actor_id : Actor.actor_id) : t =
  let actor_manager = Actor_manager.remove backend.actor_manager actor_id in
  { backend with actor_manager }

let update_actor (backend : t) (actor_id : Actor.actor_id)
    (f : Actor.t -> Actor.t) : t =
  let actor_manager = Actor_manager.update backend.actor_manager actor_id f in
  { backend with actor_manager }

let queue_actor_action (backend : t) (actor_id : Actor.actor_id)
    (action : Types.Action.t) : t =
  update_actor backend actor_id (fun actor -> Actor.queue_action actor action)

(* ////////////////////////////// *)
(* LEVEL TRANSITION HELPERS *)
(* ////////////////////////////// *)
let get_current_map (backend : t) : Tilemap.t =
  Map_manager.get_current_map backend.map_manager

let transition_to_next_level (backend : t) =
  (* Save current level state *)
  let map_manager =
    Map_manager.save_level_state backend.map_manager
      backend.map_manager.current_level ~entities:backend.entities
      ~actor_manager:backend.actor_manager ~turn_queue:backend.turn_queue
  in

  (* Go to next level *)
  let map_manager = Map_manager.go_to_next_level map_manager in

  (* Get new map *)
  let new_map = Map_manager.get_current_map map_manager in

  (* Either load existing level state or initialize new level *)
  let map_manager, _, _, _ =
    Map_manager.load_level_state map_manager map_manager.current_level
      ~entities:backend.entities ~actor_manager:backend.actor_manager
      ~turn_queue:backend.turn_queue
  in

  (* Position player at stairs_up in new level *)
  let player = get_player backend in
  match new_map.Tilemap.stairs_up with
  | Some stairs_pos ->
      let backend = move_entity backend player.id stairs_pos in
      ({ backend with map_manager }, map_manager)
  | None ->
      (* Shouldn't happen since we always have stairs up except on level 1 *)
      ({ backend with map_manager }, map_manager)

let transition_to_previous_level backend =
  (* Save current level state *)
  let map_manager =
    Map_manager.save_level_state backend.map_manager
      backend.map_manager.current_level ~entities:backend.entities
      ~actor_manager:backend.actor_manager ~turn_queue:backend.turn_queue
  in

  (* Go to previous level *)
  let map_manager = Map_manager.go_to_previous_level map_manager in

  (* Get new map *)
  let new_map = Map_manager.get_current_map map_manager in

  (* Either load existing level state or initialize new level *)
  let map_manager, _, _, _ =
    Map_manager.load_level_state map_manager map_manager.current_level
      ~entities:backend.entities ~actor_manager:backend.actor_manager
      ~turn_queue:backend.turn_queue
  in

  (* Position player at stairs_down in previous level *)
  let player = get_player backend in
  match new_map.Tilemap.stairs_down with
  | Some stairs_pos ->
      let backend = move_entity backend player.id stairs_pos in
      ({ backend with map_manager }, map_manager)
  | None ->
      (* Shouldn't happen since we always have stairs down except on last level *)
      ({ backend with map_manager }, map_manager)

let can_use_stairs_down backend entity_id =
  match get_entity backend entity_id with
  | None -> false
  | Some entity ->
      let tile =
        Tilemap.get_tile
          (Map_manager.get_current_map backend.map_manager)
          entity.pos
      in
      Map.Tile.equal tile Map.Tile.Stairs_down

let can_use_stairs_up backend entity_id =
  match get_entity backend entity_id with
  | None -> false
  | Some entity ->
      let tile =
        Tilemap.get_tile
          (Map_manager.get_current_map backend.map_manager)
          entity.pos
      in
      Map.Tile.equal tile Map.Tile.Stairs_up

(* ////////////////////////////// *)
(* SPAWN HELPERS *)
(* ////////////////////////////// *)

(* Spawn player: handles entity creation, actor management, and turn scheduling *)
let spawn_player (backend : t) ~pos ~direction : t =
  let player_id = backend.player.entity_id in
  (* 1. Spawn entity *)
  let entities =
    EntityManager.spawn_player backend.entities ~pos ~direction
      ~actor_id:player_id
  in
  (* 2. Create actor *)
  let player_actor = Actor.create ~speed:100 ~next_turn_time:0 in
  let actor_manager =
    Actor_manager.add backend.actor_manager player_id player_actor
  in
  (* 3. Schedule turn *)
  let turn_queue = Turn_queue.schedule_now backend.turn_queue player_id in
  (* 4. Return updated backend state *)
  { backend with entities; actor_manager; turn_queue }

(* Spawn creature: handles entity creation and actor management *)
let spawn_creature (backend : t) ~pos ~direction ~species ~health ~glyph ~name
    ~actor_id ~description : t =
  (* 1. Spawn entity and get its ID and associated actor_id *)
  (* Spawner returns (EntityManager.t * actor_id * Types.Entity.entity) *)
  let entities, creature_actor_id, _new_entity =
    EntityManager.spawn_creature backend.entities ~pos ~direction ~species
      ~health ~glyph ~name ~actor_id ~description
  in
  (* 2. Create a default actor for the creature *)
  (* TODO: Configure speed/next_turn based on creature type? *)
  let creature_actor = Actor.create ~speed:100 ~next_turn_time:0 in
  (* Use the creature_actor_id returned by the spawner *)
  let actor_manager =
    Actor_manager.add backend.actor_manager creature_actor_id creature_actor
  in
  (* 3. Don't schedule turn immediately, let Turn_system handle it *)
  let turn_queue = backend.turn_queue in
  { backend with entities; actor_manager; turn_queue }

(* ////////////////////////////// *)
(* ACTION HANDLING *)
(* ////////////////////////////// *)

let build_action_context (backend : t) : Actions.action_context =
  {
    get_tile_at =
      Tilemap.get_tile (Map_manager.get_current_map backend.map_manager);
    in_bounds =
      Tilemap.in_bounds (Map_manager.get_current_map backend.map_manager);
    get_entity = get_entity backend;
    get_entity_at_pos = get_entity_at_pos backend.entities;
  }

(* Update entity stats, particularly for damage handling *)
let update_entity_stats (backend : t) (entity_id : Types.Entity.entity_id)
    (f : Types.Stats.t -> Types.Stats.t) : t =
  {
    backend with
    entities = EntityManager.update_entity_stats backend.entities entity_id f;
  }

(* Check if an entity is dead based on its stats *)
let is_entity_dead (backend : t) (entity_id : Types.Entity.entity_id) : bool =
  match get_entity backend entity_id with
  | None -> true (* No entity means it's effectively "dead" *)
  | Some entity -> (
      match entity.data with
      | Some (Types.Entity.PlayerData { stats; _ }) -> stats.hp <= 0
      | Some (Types.Entity.CreatureData { stats; _ }) -> stats.hp <= 0
      | _ -> false (* Non-actor/item entities can't die *))

(* Helper to create a placeholder corpse item *)
let create_corpse_item name =
  Types.Item.create ~item_type:Types.Item.Scroll ~quantity:1
    ~name:("corpse of " ^ name)
    ~description:(Some ("The remains of a " ^ name))
    ()

(* Handle entity death *)
let handle_entity_death (backend : t) (entity_id : Types.Entity.entity_id) : t =
  match get_entity backend entity_id with
  | None -> backend (* Entity doesn't exist, nothing to do *)
  | Some entity ->
      let actor_id =
        match entity.data with
        | Some (Types.Entity.PlayerData { actor_id; _ }) -> actor_id
        | Some (Types.Entity.CreatureData { actor_id; _ }) -> actor_id
        | _ -> failwith "Entity has no actor_id"
      in

      if is_player backend entity_id then (
        Core_log.info (fun m -> m "Player has died!");
        {
          backend with
          mode = Types.CtrlMode.Died (Sys.time ());
          actor_manager = Actor_manager.remove backend.actor_manager actor_id;
        })
      else (
        Core_log.info (fun m ->
            m "Creature %d (%s) has died!" entity_id entity.name);
        let actor_manager =
          Actor_manager.remove backend.actor_manager actor_id
        in
        let entities =
          EntityManager.update backend.entities entity_id (fun old_entity ->
              {
                old_entity with
                glyph = "%";
                kind = Types.Entity.Corpse;
                name = "corpse of " ^ old_entity.name;
                description = Some ("The remains of " ^ old_entity.name);
              })
        in
        { backend with actor_manager; entities })

(* Legacy action handling - will be deprecated *)
let rec handle_action_legacy (backend : t) (entity_id : Types.Entity.entity_id)
    (action : Types.Action.t) : t * (int, exn) Result.t =
  let ctx = build_action_context backend in
  match action with
  | Types.Action.Move dir -> (
      (* Special case for Move: check if there's an entity at the target position *)
      match get_entity backend entity_id with
      | None -> (backend, Error (Failure "Entity not found"))
      | Some entity -> (
          let delta = Types.Direction.to_point dir in
          let new_pos = Types.Loc.(entity.pos + delta) in

          (* Check if there's an entity at the target position *)
          match get_entity_at_pos backend.entities new_pos with
          | Some target_entity -> (
              (* If there's an entity, check if it can be attacked *)
              match Actions.get_entity_stats target_entity with
              | Some _ ->
                  (* Convert to an Attack action and handle it recursively *)
                  Core_log.info (fun m ->
                      m "Converting Move to Attack for entity %d -> %d"
                        entity_id target_entity.id);
                  handle_action_legacy backend entity_id
                    (Types.Action.Attack target_entity.id)
              | None ->
                  (* Can't attack entities without stats *)
                  ( backend,
                    Error (Failure "Cannot move here: blocked by entity") ))
          | None -> (
              (* No entity, proceed with normal movement check *)
              match Actions.handle_action ctx entity_id action with
              | Ok _ as ok ->
                  Core_log.info (fun m -> m "Moving entity: %d" entity_id);
                  let backend = move_entity backend entity_id new_pos in
                  (backend, ok)
              | Error _ as err -> (backend, err))))
  | _ -> (
      (* Handle all other actions normally *)
      match Actions.handle_action ctx entity_id action with
      | Ok _ as ok ->
          let backend =
            match action with
            | Types.Action.StairsUp ->
                Core_log.info (fun m -> m "Transitioning to previous level");
                let backend, map_manager =
                  transition_to_previous_level backend
                in
                { backend with map_manager }
            | Types.Action.StairsDown ->
                Core_log.info (fun m -> m "Transitioning to next level");
                let backend, map_manager = transition_to_next_level backend in
                { backend with map_manager }
            | Types.Action.Attack target_id -> (
                Core_log.info (fun m ->
                    m "Entity %d attacking %d" entity_id target_id);
                match
                  (get_entity backend entity_id, get_entity backend target_id)
                with
                | Some attacker, Some defender -> (
                    match
                      ( Actions.get_entity_stats attacker,
                        Actions.get_entity_stats defender )
                    with
                    | Some attacker_stats, Some defender_stats ->
                        (* Calculate damage *)
                        let damage =
                          Actions.calculate_damage ~attacker_stats
                            ~defender_stats
                        in

                        Core_log.info (fun m ->
                            m "%s attacks %s for %d damage!" attacker.name
                              defender.name damage);

                        (* Apply damage to defender *)
                        let backend =
                          update_entity_stats backend target_id (fun stats ->
                              { stats with hp = stats.hp - damage })
                        in

                        (* Check if defender is dead and handle death if needed *)
                        if is_entity_dead backend target_id then
                          handle_entity_death backend target_id
                        else backend
                    | _ -> backend)
                | _ -> backend)
            | _ -> backend
          in
          (backend, ok)
      | Error _ as err -> (backend, err))

(* New functional action handling *)
let handle_action (backend : t) (entity_id : Types.Entity.entity_id)
    (action : Types.Action.t) : t * (int, exn) Result.t =
  (* Use the legacy action handling for now *)
  handle_action_legacy backend entity_id action
