open Base
open Types

type t = Entity.t Map.M(Int).t

let create () : t = Map.empty (module Int)
let length (mgr : t) : int = Map.length mgr
let copy (t : t) : t = t
let restore (_t : t) (src : t) : t = src
let to_list (mgr : t) : Entity.t list = Map.data mgr

let print_entity_manager (mgr : t) : unit =
  Map.iteri mgr ~f:(fun ~key ~data ->
      Core_log.info (fun m -> m "Entity %d: %s" key (Entity.show data)))

let print_entity_manager_ids (mgr : t) : unit =
  Map.iter mgr ~f:(fun data ->
      match data with
      | Entity.Player (base, _) ->
          Core_log.info (fun m -> m "Entity player id: %d" base.id)
      | Entity.Creature (base, _) ->
          Core_log.info (fun m -> m "Entity creature id: %d" base.id)
      | Entity.Item (base, _) ->
          Core_log.info (fun m -> m "Entity item id: %d" base.id)
      | Entity.Corpse base ->
          Core_log.info (fun m -> m "Entity corpse id: %d" base.id))

let find (id : int) (mgr : t) : Entity.t option = Map.find mgr id

let find_base (id : int) (mgr : t) : Entity.base_entity option =
  Map.find mgr id |> Option.map ~f:(fun ent -> Entity.get_base ent)

let find_id (id : int) (mgr : t) : int option =
  Map.find mgr id |> Option.map ~f:(fun ent -> Entity.get_id ent)

let find_unsafe (id : int) (mgr : t) : Entity.t =
  find id mgr |> Option.value_exn ~message:"Entity not found"

let find_by_pos (pos : Loc.t) (mgr : t) : Entity.t option =
  Map.fold mgr ~init:None ~f:(fun ~key:_ ~data acc ->
      Option.first_some acc
        (let id = Entity.get_id data in
         match Components.Position.get id with
         | Some p when Loc.equal pos p -> Some data
         | _ -> None))

let find_base_by_pos (pos : Loc.t) (mgr : t) : Entity.base_entity option =
  Map.fold mgr ~init:None ~f:(fun ~key:_ ~data acc ->
      Option.first_some acc
        (let id = Entity.get_id data in
         match Components.Position.get id with
         | Some p when Loc.equal pos p -> Some (Entity.get_base data)
         | _ -> None))

let find_player (mgr : t) : Entity.t option =
  Map.fold mgr ~init:None ~f:(fun ~key:_ ~data acc ->
      Option.first_some acc
        (match data with Entity.Player _ -> Some data | _ -> None))

let find_player_base (mgr : t) : Entity.base_entity option =
  find_player mgr |> Option.map ~f:(fun ent -> Entity.get_base ent)

let find_player_id (mgr : t) : int option =
  find_player mgr |> Option.map ~f:(fun ent -> Entity.get_id ent)

let update (id : int) (f : Entity.t -> Entity.t) (mgr : t) : t =
  Map.find mgr id
  |> Option.map ~f:(fun ent -> Map.set mgr ~key:id ~data:(f ent))
  |> Option.value ~default:mgr

let next_id (mgr : t) : int =
  Map.max_elt mgr
  |> Option.value_map ~default:0 ~f:(fun (max_id, _) -> max_id + 1)

let remove (id : int) (mgr : t) : t = Map.remove mgr id

let add (ent : Entity.t) (mgr : t) : t =
  Map.set mgr ~key:(Entity.get_id ent) ~data:ent

let add_entity (ent : Entity.t) (mgr : t) : t =
  let id = next_id mgr in
  let ent =
    match ent with
    | Entity.Player (base, data) -> Entity.Player ({ base with id }, data)
    | Entity.Creature (base, data) -> Entity.Creature ({ base with id }, data)
    | Entity.Item (base, data) -> Entity.Item ({ base with id }, data)
    | Entity.Corpse base -> Entity.Corpse { base with id }
  in
  Map.set mgr ~key:id ~data:ent

let update_entity_stats (mgr : t) (id : Entity.id) (f : Stats.t -> Stats.t) : t
    =
  update id
    (fun entity ->
      match entity with
      | Entity.Player (base, data) ->
          Entity.Player (base, { stats = f data.stats })
      | Entity.Creature (base, data) ->
          Entity.Creature (base, { data with stats = f data.stats })
      | _ -> entity)
    mgr
