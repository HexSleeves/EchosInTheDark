open Base
open Types

type t = Entity.entity Map.M(Int).t

type partial_entity = {
  pos : Loc.t;
  name : string;
  glyph : string;
  description : string option;
  direction : Direction.t;
  kind : Entity.entity_kind;
  data : Entity.entity_data option;
}

let create () : t = Map.empty (module Int)
let add (mgr : t) (ent : Entity.entity) : t = Map.set mgr ~key:ent.id ~data:ent
let remove (mgr : t) (id : int) : t = Map.remove mgr id
let find (mgr : t) (id : int) : Entity.entity option = Map.find mgr id

let find_unsafe (mgr : t) (id : int) : Entity.entity =
  match find mgr id with
  | Some ent -> ent
  | None -> failwith (Printf.sprintf "Entity not found: %d" id)

let find_by_pos (mgr : t) (pos : Loc.t) : Entity.entity option =
  Map.fold mgr ~init:None ~f:(fun ~key:_ ~data acc ->
      match acc with
      | Some _ -> acc
      | None -> if Loc.equal pos data.pos then Some data else None)

let update (mgr : t) (id : int) (f : Entity.entity -> Entity.entity) : t =
  match Map.find mgr id with
  | Some ent -> Map.set mgr ~key:id ~data:(f ent)
  | None -> mgr

let to_list (mgr : t) : Entity.entity list = Map.data mgr

let add_entity (mgr : t) (p : partial_entity) : t * int * Entity.entity =
  let id : Entity.entity_id =
    match Map.max_elt mgr with Some (max_id, _) -> max_id + 1 | None -> 0
  in
  let entity : Entity.entity =
    {
      id;
      name = p.name;
      glyph = p.glyph;
      description = p.description;
      kind = p.kind;
      pos = p.pos;
      direction = p.direction;
      data = p.data;
    }
  in
  (Map.set mgr ~key:id ~data:entity, id, entity)

let copy (t : t) : t = t (* Map is persistent, so this is just identity *)
let restore (_t : t) (src : t) : t = src (* Just return the source *)

(* --- spawner.ml --- *)
let spawn_player (em : t) ~pos ~direction ~actor_id =
  {
    pos;
    direction;
    id = 0;
    glyph = "@";
    name = "Player";
    kind = Player;
    description = Some "This is you!";
    data = Some (PlayerData { stats = Types.Stats.default; actor_id });
  }
  |> add em

let spawn_creature (em : t) ~pos ~direction ~species ~health ~glyph ~name
    ~actor_id ~description =
  let entity : partial_entity =
    {
      pos;
      direction;
      glyph;
      name;
      description = Some description;
      kind = Creature;
      data =
        Some
          (CreatureData
             {
               species;
               actor_id;
               stats =
                 Types.Stats.create ~max_hp:health ~hp:health ~attack:10
                   ~defense:5 ~speed:100;
             });
    }
  in
  add_entity em entity

let spawn_item (em : t) ~pos ~direction ~item_type ~quantity ~name ~glyph
    ?(description = None) () =
  {
    pos;
    glyph;
    name;
    direction;
    description;
    kind = Item;
    data =
      Some
        (ItemData
           {
             item =
               Types.Item.create ~item_type ~quantity ~name ~description:None ();
           });
  }
  |> add_entity em
(* --- spawner.ml --- *)

(** [update_entity_stats mgr entity_id f] applies [f] to the stats of the entity
    with [entity_id], if it is a Player or Creature. Returns the updated entity
    manager. *)
let update_entity_stats (mgr : t) (entity_id : Entity.entity_id)
    (f : Stats.t -> Stats.t) : t =
  update mgr entity_id (fun entity ->
      let update_stats data =
        match data with
        | Types.Entity.PlayerData { stats; actor_id } ->
            Some (Types.Entity.PlayerData { stats = f stats; actor_id })
        | Types.Entity.CreatureData { stats; actor_id; species } ->
            Some
              (Types.Entity.CreatureData { stats = f stats; actor_id; species })
        | _ -> Some data
      in
      match entity.data with
      | Some data -> { entity with data = update_stats data }
      | None -> entity)
