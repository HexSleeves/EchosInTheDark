open Base
open Types
open Ppx_yojson_conv_lib.Yojson_conv

type t = Entity.t Map.M(Int).t

let create () : t = Map.empty (module Int)
let length (mgr : t) : int = Map.length mgr
let copy (t : t) : t = t
let restore (_t : t) (src : t) : t = src

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

let add (ent : Entity.t) (mgr : t) : t =
  Map.set mgr ~key:(Entity.get_id ent) ~data:ent

let remove (id : int) (mgr : t) : t = Map.remove mgr id
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
        (let base = Entity.get_base data in
         if Loc.equal pos base.pos then Some data else None))

let find_base_by_pos (pos : Loc.t) (mgr : t) : Entity.base_entity option =
  Map.fold mgr ~init:None ~f:(fun ~key:_ ~data acc ->
      Option.first_some acc
        (let base = Entity.get_base data in
         if Loc.equal pos base.pos then Some base else None))

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

let to_list (mgr : t) : Entity.t list = Map.data mgr

let next_id (mgr : t) : int =
  Map.max_elt mgr
  |> Option.value_map ~default:0 ~f:(fun (max_id, _) -> max_id + 1)

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

let spawn_player (em : t) ~pos ~direction =
  let current_player = find_player em in
  match current_player with
  | Some player -> add_entity player em
  | None ->
      let base =
        Entity.make_base_entity ~id:0 ~pos ~name:"Player" ~glyph:"@"
          ~description:(Some "This is you!") ~direction ()
      in
      let player_data : Entity.player_data = { stats = Stats.default } in
      add_entity (Entity.Player (base, player_data)) em

let spawn_creature (em : t) ~pos ~direction ~species ~health ~glyph ~name
    ~description ~faction =
  let id = next_id em in
  let base =
    Entity.make_base_entity ~id ~pos ~name ~glyph
      ~description:(Some description) ~direction ()
  in
  let creature_data : Entity.creature_data =
    {
      species;
      stats =
        Stats.create ~max_hp:health ~hp:health ~attack:10 ~defense:5 ~speed:100;
      faction;
    }
  in

  Core_log.info (fun m -> m "Spawning creature %s at %s" name (Loc.show pos));

  add_entity (Entity.Creature (base, creature_data)) em

let spawn_item (em : t) ~pos ~direction ~item_type ~quantity ~name ~glyph
    ?(description = None) () =
  let id = next_id em in
  let base =
    Entity.make_base_entity ~id ~pos ~name ~glyph ~description ~direction ()
  in
  let item = Item.create ~item_type ~quantity ~name ~description:None () in
  add_entity (Entity.Item (base, { item })) em

let spawn_corpse (pos : Loc.t) (em : t) : t =
  let id = next_id em in
  let base =
    Entity.make_base_entity ~id ~pos ~name:"Corpse" ~glyph:"%"
      ~description:(Some "A dead creature") ~direction:Direction.North
      ~blocking:false ()
  in
  add (Entity.Corpse base) em

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
