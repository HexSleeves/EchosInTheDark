module E = Entity
module T = Tile
module TM = Tilemap

(* Entity manager to keep track of all entities in the game *)
type t = { entities : E.t list; player : E.t option }

(* Create a new empty entity manager *)
let make () = { entities = []; player = None }

(* Add a player to the entity manager *)
let add_player manager player =
  { manager with entities = player :: manager.entities; player = Some player }

(* Add an entity to the entity manager *)
let add_entity manager entity =
  { manager with entities = manager.entities @ [ entity ] }

(* Add multiple entities *)
let add_entities manager entities =
  { manager with entities = manager.entities @ entities }

(* Remove an entity by ID *)
let remove_entity_by_id manager id =
  let new_entities = List.filter (fun e -> e.E.id <> id) manager.entities in
  let new_player =
    match manager.player with
    | Some p when p.E.id = id -> None
    | _ -> manager.player
  in
  { entities = new_entities; player = new_player }

(* Get entity by ID *)
let get_entity_by_id manager id =
  List.find_opt (fun e -> e.E.id = id) manager.entities

(* Get all entities at a specific position *)
let get_entities_at manager x y =
  List.filter (fun e -> E.is_at e x y) manager.entities

(* Get blocking entity at a position, if any *)
let get_blocking_entity_at manager x y =
  List.find_opt (fun e -> E.is_at e x y && e.E.blocks) manager.entities

(* Update an entity in the manager *)
let update_entity manager entity =
  let updated_entities =
    List.map
      (fun e -> if e.E.id = entity.E.id then entity else e)
      manager.entities
  in
  let updated_player =
    match manager.player with
    | Some p when p.E.id = entity.E.id -> Some entity
    | _ -> manager.player
  in
  { entities = updated_entities; player = updated_player }

(* Remove dead entities (returns updated manager) *)
let remove_dead_entities manager =
  let alive_entities =
    List.filter (fun e -> not (E.is_dead e)) manager.entities
  in
  let player =
    match manager.player with
    | Some p when E.is_dead p -> None
    | _ -> manager.player
  in
  { entities = alive_entities; player }

(* Get all enemies *)
let get_enemies manager =
  List.filter
    (fun e -> match e.E.entity_type with E.Enemy -> true | _ -> false)
    manager.entities

(* Get all items *)
let get_items manager =
  List.filter
    (fun e -> match e.E.entity_type with E.Item -> true | _ -> false)
    manager.entities

(* Move entity if destination is not blocked *)
let try_move_entity manager entity dx dy map =
  let target_x = entity.E.pos_x + dx in
  let target_y = entity.E.pos_y + dy in

  (* Check tilemap for walls *)
  let tile = TM.get_tile map target_x target_y in
  let tile_blocks = match tile with T.Wall -> true | _ -> false in

  (* Check for blocking entities *)
  let entity_blocks =
    match get_blocking_entity_at manager target_x target_y with
    | Some _ -> true
    | None -> false
  in

  if not (tile_blocks || entity_blocks) then
    let moved_entity = E.move entity dx dy in
    update_entity manager moved_entity
  else manager

(* Apply damage to an entity at position *)
let damage_entity_at manager x y amount =
  match get_blocking_entity_at manager x y with
  | None -> manager
  | Some target ->
      let damaged_entity = E.take_damage target amount in
      update_entity manager damaged_entity
