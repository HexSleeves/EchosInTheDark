open Base
open Entities

let get_entities_manager (state : State_types.t) : Entity_manager.t =
  state.entities

let set_entities_manager (state : State_types.t) (entities : Entity_manager.t) :
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
let add_entity_to_index (state : State_types.t) (entity : Types.Entity.t) : unit
    =
  let id = Types.Entity.get_id entity in
  match Components.Position.get id with
  | Some pos -> Base.Hashtbl.set state.position_index ~key:pos ~data:id
  | None -> ()

(* Helper: Remove an entity's position from the index if it has one *)
let remove_entity_from_index (state : State_types.t) (id : Types.Entity.id) :
    unit =
  match Components.Position.get id with
  | Some pos -> Base.Hashtbl.remove state.position_index pos
  | None -> ()

let move_entity (id : Types.Entity.id) (loc : Types.Loc.t)
    (state : State_types.t) =
  let old_pos = Components.Position.get id in
  Components.Position.set id loc |> fun _ ->
  (match old_pos with
  | Some pos -> Base.Hashtbl.remove state.position_index pos
  | None -> ());
  Base.Hashtbl.set state.position_index ~key:loc ~data:id;
  state

let remove_entity (id : Types.Entity.id) (state : State_types.t) : State_types.t
    =
  remove_entity_from_index state id;
  { state with entities = Entity_manager.remove id state.entities }

let spawn_entity (state : State_types.t) (entity : Types.Entity.t) :
    State_types.t =
  let new_entities = Entity_manager.add entity state.entities in
  add_entity_to_index state entity;
  set_entities_manager state new_entities

let spawn_creature_entity (state : State_types.t) ~pos ~direction ~species
    ~health ~glyph ~name ~description ~faction : State_types.t =
  let new_entities =
    Spawner.spawn_creature state.entities ~pos ~direction ~species ~health
      ~glyph ~name ~description ~faction
  in
  (* Find the new entity (assume it's the one at this pos and species) *)
  Entity_manager.to_list new_entities
  |> List.iter ~f:(add_entity_to_index state);
  set_entities_manager state new_entities

let spawn_player_entity (state : State_types.t) ~pos ~direction : State_types.t
    =
  let new_entities = Spawner.spawn_player ~pos ~direction state.entities in
  Entity_manager.to_list new_entities
  |> List.iter ~f:(add_entity_to_index state);
  set_entities_manager state new_entities

let spawn_item_entity (state : State_types.t) ~pos ~direction ~item_type
    ~quantity ~name ~glyph ?description () : State_types.t =
  let new_entities =
    Spawner.spawn_item ~pos ~direction ~item_type ~quantity ~name ~glyph
      ?description state.entities
  in
  Entity_manager.to_list new_entities
  |> List.iter ~f:(add_entity_to_index state);
  set_entities_manager state new_entities

let spawn_corpse_entity (state : State_types.t) ~pos : State_types.t =
  let new_entities = Spawner.spawn_corpse ~pos state.entities in
  Entity_manager.to_list new_entities
  |> List.iter ~f:(add_entity_to_index state);
  set_entities_manager state new_entities

let rebuild_position_index (state : State_types.t) : State_types.t =
  Base.Hashtbl.clear state.position_index;
  Entity_manager.to_list state.entities
  |> List.iter ~f:(fun entity ->
         let id = Types.Entity.get_id entity in
         match Components.Position.get id with
         | Some pos -> Base.Hashtbl.set state.position_index ~key:pos ~data:id
         | None -> ());
  state
