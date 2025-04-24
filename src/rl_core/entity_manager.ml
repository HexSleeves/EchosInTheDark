open Base
open Types
open Types.Entity

type t = Entity.t Map.M(Int).t

let create () : t = Map.empty (module Int)

let add (mgr : t) (ent : Entity.t) : t =
  let id =
    match ent with
    | Entity.Player (base, _)
    | Entity.Creature (base, _)
    | Entity.Item (base, _)
    | Entity.Corpse base ->
        base.id
  in
  Map.set mgr ~key:id ~data:ent

let remove (mgr : t) (id : int) : t = Map.remove mgr id
let find (mgr : t) (id : int) : Entity.t option = Map.find mgr id

let find_unsafe (mgr : t) (id : int) : Entity.t =
  match find mgr id with
  | Some ent -> ent
  | None -> failwith (Printf.sprintf "Entity not found: %d" id)

let find_by_pos (mgr : t) (pos : Loc.t) : Entity.t option =
  Map.fold mgr ~init:None ~f:(fun ~key:_ ~data acc ->
      match acc with
      | Some _ -> acc
      | None ->
          let base =
            match data with
            | Entity.Player (base, _)
            | Entity.Creature (base, _)
            | Entity.Item (base, _)
            | Entity.Corpse base ->
                base
          in
          if Loc.equal pos base.pos then Some data else None)

let update (mgr : t) (id : int) (f : Entity.t -> Entity.t) : t =
  Map.find mgr id
  |> Option.value_map ~default:mgr ~f:(fun ent ->
         Map.set mgr ~key:id ~data:(f ent))

let to_list (mgr : t) : Entity.t list = Map.data mgr

let next_id (mgr : t) : int =
  match Map.max_elt mgr with Some (max_id, _) -> max_id + 1 | None -> 0

let add_entity (mgr : t) (ent : Entity.t) : t * int * Entity.t =
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

let spawn_player (em : t) ~pos ~direction =
  let id = next_id em in
  let base =
    Entity.make_base_entity ~id ~pos ~name:"Player" ~glyph:"@"
      ~description:(Some "This is you!") ~direction ()
  in
  let player_data : Entity.player_data = { stats = Types.Stats.default } in
  add_entity em (Entity.Player (base, player_data))

let spawn_creature (em : t) ~pos ~direction ~species ~health ~glyph ~name
    ~description =
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
    }
  in
  add_entity em (Entity.Creature (base, creature_data))

let spawn_item (em : t) ~pos ~direction ~item_type ~quantity ~name ~glyph
    ?(description = None) () =
  let id = next_id em in
  let base =
    Entity.make_base_entity ~id ~pos ~name ~glyph ~description ~direction ()
  in
  let item =
    Types.Item.create ~item_type ~quantity ~name ~description:None ()
  in
  add_entity em (Entity.Item (base, { Entity.item }))

let spawn_corpse (em : t) (pos : Loc.t) : t =
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
