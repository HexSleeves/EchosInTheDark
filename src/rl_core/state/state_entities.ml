open Base
open Entities
open Types

let get_entities_manager (state : State_types.t) : Entity_manager.t =
  state.entities

let set_entities_manager (entities : Entity_manager.t) (state : State_types.t) :
    State_types.t =
  { state with entities }

let get_player_id (state : State_types.t) : entity_id = state.player_id

(* Equipment helpers *)
let get_equipment (id : entity_id) : Components.Equipment.t option =
  Components.Equipment.get id

let set_equipment (id : entity_id) (eq : Components.Equipment.t) : unit =
  Components.Equipment.set id eq

(* Entity helpers *)

let move_entity (id : entity_id) (loc : Types.Loc.t) (state : State_types.t) =
  let old_pos = Components.Position.get id in
  Components.Position.set id loc |> fun _ ->
  (match old_pos with
  | Some pos -> Hashtbl.remove state.position_index pos
  | None -> ());
  Hashtbl.set state.position_index ~key:loc ~data:id;
  state

let get_entity_at_pos (pos : Types.Loc.t) (state : State_types.t) :
    entity_id option =
  match Hashtbl.find state.position_index pos with
  | Some id -> Some id
  | None -> None

let get_blocking_entity_at_pos (pos : Types.Loc.t) (state : State_types.t) :
    entity_id option =
  Entity_manager.to_list state.entities
  |> List.find ~f:(fun id ->
         match Components.Position.get id with
         | Some pos' when Poly.(pos = pos') ->
             Option.value ~default:false (Components.Blocking.get id)
         | _ -> false)

let get_entities (state : State_types.t) : entity_id list =
  Entity_manager.to_list state.entities

let get_creatures (state : State_types.t) : entity_id list =
  Entity_manager.to_list state.entities
  |> List.filter ~f:(fun id ->
         match Components.Kind.get id with
         | Some Components.Kind.Creature -> true
         | _ -> false)

(* Helper: Add an entity's position to the index if it has one *)
let add_entity_to_index (entity_id : entity_id) (state : State_types.t) :
    State_types.t =
  match Components.Position.get entity_id with
  | Some pos ->
      Hashtbl.set state.position_index ~key:pos ~data:entity_id;
      state
  | None -> state

(* Helper: Remove an entity's position from the index if it has one *)
let remove_entity_from_index (entity_id : entity_id) (state : State_types.t) :
    State_types.t =
  match Components.Position.get entity_id with
  | Some pos ->
      Hashtbl.remove state.position_index pos;
      state
  | None -> state

let rebuild_position_index (state : State_types.t) : State_types.t =
  Hashtbl.clear state.position_index;
  Entity_manager.to_list state.entities
  |> List.iter ~f:(fun entity_id ->
         match Components.Position.get entity_id with
         | Some pos -> Hashtbl.set state.position_index ~key:pos ~data:entity_id
         | None -> ());
  state

let spawn_corpse_entity ~pos (state : State_types.t) : State_types.t =
  let new_entities = Spawner.spawn_corpse ~pos state.entities in
  Entity_manager.to_list new_entities
  |> List.fold_left ~init:state ~f:(fun state e -> add_entity_to_index e state)
  |> set_entities_manager new_entities

let add_entity (entity_id : entity_id) (state : State_types.t) : State_types.t =
  add_entity_to_index entity_id state
  |> set_entities_manager (Entity_manager.add entity_id state.entities)

let remove_entity (id : entity_id) (state : State_types.t) : State_types.t =
  remove_entity_from_index id state |> fun state ->
  {
    state with
    entities = Entity_manager.remove id state.entities;
    turn_queue = Turn_queue.remove_actor state.turn_queue id;
  }
  |> fun state ->
  match Components.Position.get id with
  | Some pos -> spawn_corpse_entity ~pos state
  | None -> state
