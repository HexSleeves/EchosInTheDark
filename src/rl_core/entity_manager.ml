open Base
open Types

type t = Entity.t Map.M(Int).t

let create () : t = Map.empty (module Int)

let add (mgr : t) (ent : Entity.t) : t =
  Map.set mgr ~key:(Entity.get_id ent) ~data:ent

let remove (mgr : t) (id : int) : t = Map.remove mgr id
let find (mgr : t) (id : int) : Entity.t option = Map.find mgr id

let find_base (mgr : t) (id : int) : Entity.base_entity option =
  Map.find mgr id |> Option.map ~f:(fun ent -> Entity.get_base ent)

let find_id (mgr : t) (id : int) : int option =
  Map.find mgr id |> Option.map ~f:(fun ent -> Entity.get_id ent)

let find_unsafe (mgr : t) (id : int) : Entity.t =
  find mgr id |> Option.value_exn ~message:"Entity not found"

let find_by_pos (mgr : t) (pos : Loc.t) : Entity.t option =
  Map.fold mgr ~init:None ~f:(fun ~key:_ ~data acc ->
      Option.first_some acc
        (let base = Entity.get_base data in
         if Loc.equal pos base.pos then Some data else None))

let find_base_by_pos (mgr : t) (pos : Loc.t) : Entity.base_entity option =
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

let update (mgr : t) (id : int) (f : Entity.t -> Entity.t) : t =
  Map.find mgr id
  |> Option.map ~f:(fun ent -> Map.set mgr ~key:id ~data:(f ent))
  |> Option.value ~default:mgr

let to_list (mgr : t) : Entity.t list = Map.data mgr

let next_id (mgr : t) : int =
  Map.max_elt mgr
  |> Option.value_map ~default:0 ~f:(fun (max_id, _) -> max_id + 1)

let add_entity (ent : Entity.t) (mgr : t) : t * int * Entity.t =
  let id = next_id mgr in
  let ent =
    match ent with
    | Entity.Player (base, data) -> Entity.Player ({ base with id }, data)
    | Entity.Creature (base, data) -> Entity.Creature ({ base with id }, data)
    | Entity.Item (base, data) -> Entity.Item ({ base with id }, data)
    | Entity.Corpse base -> Entity.Corpse { base with id }
  in
  (Map.set mgr ~key:id ~data:ent, id, ent)

let copy (t : t) : t = t
let restore (_t : t) (src : t) : t = src

let generate_player (em : t) ~pos ~direction =
  let player_data : Entity.player_data = { stats = Types.Stats.default } in
  let base =
    Entity.make_base_entity ~id:(next_id em) ~pos ~name:"Player" ~glyph:"@"
      ~description:(Some "This is you!") ~direction ()
  in
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
        Types.Stats.create ~max_hp:health ~hp:health ~attack:10 ~defense:5
          ~speed:100;
      faction;
    }
  in
  add_entity (Entity.Creature (base, creature_data)) em

let spawn_item (em : t) ~pos ~direction ~item_type ~quantity ~name ~glyph
    ?(description = None) () =
  let id = next_id em in
  let base =
    Entity.make_base_entity ~id ~pos ~name ~glyph ~description ~direction ()
  in
  let item =
    Types.Item.create ~item_type ~quantity ~name ~description:None ()
  in
  add_entity (Entity.Item (base, { Entity.item })) em

let spawn_corpse (pos : Loc.t) (em : t) : t =
  let id = next_id em in
  let base =
    Entity.make_base_entity ~id ~pos ~name:"Corpse" ~glyph:"%"
      ~description:(Some "A dead creature") ~direction:Types.Direction.North
      ~blocking:false ()
  in
  add em (Entity.Corpse base)

let update_entity_stats (mgr : t) (id : Entity.id) (f : Stats.t -> Stats.t) : t
    =
  update mgr id (fun entity ->
      match entity with
      | Entity.Player (base, data) ->
          Entity.Player (base, { stats = f data.stats })
      | Entity.Creature (base, data) ->
          Entity.Creature (base, { data with stats = f data.stats })
      | _ -> entity)
