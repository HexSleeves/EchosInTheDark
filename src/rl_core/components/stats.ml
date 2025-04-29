open Base
open Item

module Stats_data = struct
  type t = { max_hp : int; hp : int; attack : int; defense : int; speed : int }
  [@@deriving yojson, show]

  let default () =
    { max_hp = 30; hp = 30; attack = 10; defense = 5; speed = 100 }

  let create ~max_hp ~hp ~attack ~defense ~speed =
    { max_hp; hp; attack; defense; speed }

  let get_hp t = t.hp
  let get_max_hp t = t.max_hp
  let get_attack t = t.attack
  let get_defense t = t.defense
  let get_speed t = t.speed
end

type t = Stats_data.t

let table : (int, t) Hashtbl.t = Hashtbl.Poly.create ()
let get id = Hashtbl.find table id

let get_exn id =
  Option.value_exn (Hashtbl.find table id)
    ~message:(Printf.sprintf "No stats for entity id %d" id)

let set id stats = Hashtbl.set table ~key:id ~data:stats
let remove id = Hashtbl.remove table id
let create_default () = Stats_data.default ()

let create ~max_hp ~hp ~attack ~defense ~speed =
  Stats_data.create ~max_hp ~hp ~attack ~defense ~speed

let apply_equipment_modifiers (base : t) (items : Item.t list) : t =
  let total_mods =
    List.fold items ~init:StatModifiers.empty ~f:(fun acc item ->
        let m = item.stat_modifiers in
        {
          StatModifiers.attack = acc.attack + m.attack;
          defense = acc.defense + m.defense;
          speed = acc.speed + m.speed;
          max_hp = acc.max_hp + m.max_hp;
        })
  in
  {
    Stats_data.max_hp = base.max_hp + total_mods.max_hp;
    hp = base.hp;
    (* HP is not modified directly by equipment *)
    attack = base.attack + total_mods.attack;
    defense = base.defense + total_mods.defense;
    speed = base.speed + total_mods.speed;
  }
