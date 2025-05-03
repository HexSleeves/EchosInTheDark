open Base
open Entities

let get_em (state : State_types.t) : Entity_manager.t = state.em

let set_em (em : Entity_manager.t) (state : State_types.t) : State_types.t =
  { state with em }

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
  Entity_manager.all_entities state.em
  |> List.find ~f:(fun id ->
         match Components.Position.get id with
         | Some pos' when Poly.(pos = pos'.world_pos) ->
             Option.value ~default:false (Components.Blocking.get id)
         | _ -> false)

let get_entities (state : State_types.t) : int list =
  Entity_manager.all_entities state.em

let get_creatures (state : State_types.t) : int list =
  Entity_manager.all_entities state.em
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
  Entity_manager.all_entities state.em
  |> List.iter ~f:(fun entity_id ->
         match Components.Position.get entity_id with
         | Some pos ->
             Hashtbl.set state.position_index ~key:pos.world_pos
               ~data:(entity_id, pos)
         | None -> ());
  state

let spawn_corpse_entity ~pos (state : State_types.t) : State_types.t =
  Spawner.spawn_corpse ~pos state.em |> fun (id, em) ->
  add_entity_to_index id (set_em em state)

let add_entity (entity_id : int) (state : State_types.t) : State_types.t =
  add_entity_to_index entity_id state

let remove_entity (entity_id : int) (state : State_types.t) : State_types.t =
  remove_entity_from_index entity_id state |> fun state ->
  { state with turn_queue = Turn_queue.remove_actor state.turn_queue entity_id }
  |> fun state ->
  match Components.Position.get entity_id with
  | Some pos -> spawn_corpse_entity ~pos:pos.world_pos state
  | None -> state

let get_player_id (state : State_types.t) : int =
  match Entity_manager.get_player_id state.em with
  | Some id -> id
  | None -> failwith "Player ID not found"

let is_player (id : int) : bool =
  match Components.Kind.get id with
  | Some Components.Kind.Player -> true
  | _ -> false
