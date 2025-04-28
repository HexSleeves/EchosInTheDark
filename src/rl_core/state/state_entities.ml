open Base
open Entities

let get_entities_manager (state : State_types.t) : Entity_manager.t =
  state.entities

let set_entities_manager (entities : Entity_manager.t) (state : State_types.t) :
    State_types.t =
  { state with entities }

let get_player_id (state : State_types.t) : Types.Entity.id = state.player_id

let get_player_entity (state : State_types.t) : Types.Entity.t option =
  Entity_manager.find state.player_id state.entities

let get_entity (id : Types.Entity.id) (state : State_types.t) :
    Types.Entity.t option =
  Entity_manager.find id state.entities

let get_base_entity (id : Types.Entity.id) (state : State_types.t) :
    Types.Entity.base_entity option =
  Entity_manager.find id state.entities |> Option.map ~f:Types.Entity.get_base

let get_entity_at_pos (pos : Types.Loc.t) (state : State_types.t) :
    Types.Entity.t option =
  match Base.Hashtbl.find state.position_index pos with
  | Some id -> Entity_manager.find id state.entities
  | None -> None

let get_blocking_entity_at_pos (pos : Types.Loc.t) (state : State_types.t) :
    Types.Entity.t option =
  Entity_manager.find_by_pos pos state.entities
  |> Option.filter ~f:Types.Entity.get_blocking

let get_entities (state : State_types.t) : Types.Entity.t list =
  Entity_manager.to_list state.entities

let get_creatures (state : State_types.t) :
    (Types.Entity.base_entity * Types.Entity.creature_data) list =
  Entity_manager.to_list state.entities
  |> List.filter_map ~f:(function
       | Types.Entity.Creature (base, data) -> Some (base, data)
       | _ -> None)

(* Helper: Add an entity's position to the index if it has one *)
let add_entity_to_index (entity : Types.Entity.t) (state : State_types.t) :
    State_types.t =
  let id = Types.Entity.get_id entity in
  match Components.Position.get id with
  | Some pos ->
      Base.Hashtbl.set state.position_index ~key:pos ~data:id;
      state
  | None -> state

(* Helper: Remove an entity's position from the index if it has one *)
let remove_entity_from_index (id : Types.Entity.id) (state : State_types.t) :
    State_types.t =
  match Components.Position.get id with
  | Some pos ->
      Base.Hashtbl.remove state.position_index pos;
      state
  | None -> state

let rebuild_position_index (state : State_types.t) : State_types.t =
  Base.Hashtbl.clear state.position_index;
  Entity_manager.to_list state.entities
  |> List.iter ~f:(fun entity ->
         let id = Types.Entity.get_id entity in
         match Components.Position.get id with
         | Some pos -> Base.Hashtbl.set state.position_index ~key:pos ~data:id
         | None -> ());
  state

let move_entity (id : Types.Entity.id) (loc : Types.Loc.t)
    (state : State_types.t) =
  let old_pos = Components.Position.get id in
  Components.Position.set id loc |> fun _ ->
  (match old_pos with
  | Some pos -> Base.Hashtbl.remove state.position_index pos
  | None -> ());
  Base.Hashtbl.set state.position_index ~key:loc ~data:id;
  state

let spawn_corpse_entity ~pos (state : State_types.t) : State_types.t =
  let new_entities = Spawner.spawn_corpse ~pos state.entities in
  Entity_manager.to_list new_entities
  |> List.fold_left ~init:state ~f:(fun state e -> add_entity_to_index e state)
  |> set_entities_manager new_entities

let remove_entity (id : Types.Entity.id) (state : State_types.t) : State_types.t
    =
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

let spawn_entity (state : State_types.t) (entity : Types.Entity.t) :
    State_types.t =
  add_entity_to_index entity state
  |> set_entities_manager (Entity_manager.add entity state.entities)
