open Base
open Entities

let get_entities_manager (state : State_types.t) : Entity_manager.t =
  state.entities

let set_entities_manager (entities : Entity_manager.t) (state : State_types.t) :
    State_types.t =
  { state with entities }

let get_player_id (state : State_types.t) : int = state.player_id

(* Equipment helpers *)
let get_equipment (id : int) : Components.Equipment.t option =
  Components.Equipment.get id

let set_equipment (id : int) (eq : Components.Equipment.t) : unit =
  Components.Equipment.set id eq

(* Entity helpers *)

let move_entity (id : int) (position : Components.Position.t)
    (state : State_types.t) =
  let old_pos = Components.Position.get id in
  Components.Position.set id position |> fun _ ->
  (match old_pos with
  | Some pos -> Hashtbl.remove state.position_index pos.world_pos
  | None -> ());
  Hashtbl.set state.position_index ~key:position.world_pos ~data:(id, position);
  state

let get_entity_at_pos (pos : Rl_types.Loc.t) (state : State_types.t) :
    int option =
  Option.map (Hashtbl.find state.position_index pos) ~f:fst

let get_blocking_entity_at_pos (pos : Rl_types.Loc.t) (state : State_types.t) :
    int option =
  Entity_manager.to_list state.entities
  |> List.find ~f:(fun id ->
         match Components.Position.get id with
         | Some pos' when Poly.(pos = pos'.world_pos) ->
             Option.value ~default:false (Components.Blocking.get id)
         | _ -> false)

let get_entities (state : State_types.t) : int list =
  Entity_manager.to_list state.entities

let get_creatures (state : State_types.t) : int list =
  Entity_manager.to_list state.entities
  |> List.filter ~f:(fun id ->
         match Components.Kind.get id with
         | Some Components.Kind.Creature -> true
         | _ -> false)

(* Helper: Add an entity's position to the index if it has one *)
let add_entity_to_index (entity_id : int) (state : State_types.t) :
    State_types.t =
  match Components.Position.get entity_id with
  | Some pos ->
      Hashtbl.set state.position_index ~key:pos.world_pos ~data:(entity_id, pos);
      state
  | None -> state

(* Helper: Remove an entity's position from the index if it has one *)
let remove_entity_from_index (entity_id : int) (state : State_types.t) :
    State_types.t =
  match Components.Position.get entity_id with
  | Some pos ->
      Hashtbl.remove state.position_index pos.world_pos;
      state
  | None -> state

let rebuild_position_index (state : State_types.t) : State_types.t =
  Hashtbl.clear state.position_index;
  Entity_manager.to_list state.entities
  |> List.iter ~f:(fun entity_id ->
         match Components.Position.get entity_id with
         | Some pos ->
             Hashtbl.set state.position_index ~key:pos.world_pos
               ~data:(entity_id, pos)
         | None -> ());
  state

let spawn_corpse_entity ~pos (state : State_types.t) : State_types.t =
  let new_entities = Spawner.spawn_corpse ~pos state.entities in
  Entity_manager.to_list new_entities
  |> List.fold_left ~init:state ~f:(fun state e -> add_entity_to_index e state)
  |> set_entities_manager new_entities

let add_entity (entity_id : int) (state : State_types.t) : State_types.t =
  add_entity_to_index entity_id state
  |> set_entities_manager (Entity_manager.add entity_id state.entities)

let remove_entity (entity_id : int) (state : State_types.t) : State_types.t =
  remove_entity_from_index entity_id state |> fun state ->
  {
    state with
    entities = Entity_manager.remove entity_id state.entities;
    turn_queue = Turn_queue.remove_actor state.turn_queue entity_id;
  }
  |> fun state ->
  match Components.Position.get entity_id with
  | Some pos -> spawn_corpse_entity ~pos:pos.world_pos state
  | None -> state

let is_player (id : int) : bool =
  match Components.Kind.get id with
  | Some Components.Kind.Player -> true
  | _ -> false
