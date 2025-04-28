open Base

let get_entities_manager (state : State_types.t) : Entity_manager.t =
  state.entities

let set_entities_manager (state : State_types.t) (entities : Entity_manager.t) :
    State_types.t =
  { state with entities }

let get_player_id (state : State_types.t) : Types.Entity.id = state.player_id

let get_player_entity (state : State_types.t) : Types.Entity.t =
  Entity_manager.find_unsafe state.player_id state.entities

let get_entity (id : Types.Entity.id) (state : State_types.t) :
    Types.Entity.t option =
  Entity_manager.find id state.entities

let get_base_entity (id : Types.Entity.id) (state : State_types.t) :
    Types.Entity.base_entity =
  Entity_manager.find_unsafe id state.entities |> Types.Entity.get_base

let get_entity_at_pos (pos : Types.Loc.t) (state : State_types.t) :
    Types.Entity.t option =
  Entity_manager.find_by_pos pos state.entities

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

let move_entity (id : Types.Entity.id) (loc : Types.Loc.t)
    (state : State_types.t) : State_types.t =
  let open Types.Entity in
  let new_entities =
    Entity_manager.update id
      (fun ent ->
        match ent with
        | Player (base, data) -> Player ({ base with pos = loc }, data)
        | Creature (base, data) -> Creature ({ base with pos = loc }, data)
        | Item (base, data) -> Item ({ base with pos = loc }, data)
        | Corpse base -> Corpse { base with pos = loc })
      state.entities
  in
  set_entities_manager state new_entities

let remove_entity (id : Types.Entity.id) (state : State_types.t) : State_types.t
    =
  { state with entities = Entity_manager.remove id state.entities }

let spawn_creature_entity (state : State_types.t) ~pos ~direction ~species
    ~health ~glyph ~name ~description ~faction : State_types.t =
  Entity_manager.spawn_creature state.entities ~pos ~direction ~species ~health
    ~glyph ~name ~description ~faction
  |> set_entities_manager state
