open Containers

(* Entity types *)
type entity_type = Player | Enemy | Item

let show_entity_type = function
  | Player -> "Player"
  | Enemy -> "Enemy"
  | Item -> "Item"

(* Entity stats for creatures *)
type stats = { max_hp : int; hp : int; defense : int; power : int }
type buff_type = Power | Defense
type item_effect = Heal of int | Damage of int | Buff of buff_type * int
type item_type = Potion | Scroll | Weapon | Armor

type item = {
  item_type : item_type;
  consumable : bool;
  item_effect : item_effect;
}

(* Helper function to display stats *)
let show_stats s =
  Printf.sprintf "{ max_hp = %d; hp = %d; defense = %d; power = %d }" s.max_hp
    s.hp s.defense s.power

(* Helper function to show item effect *)
let show_item_effect = function
  | Heal amount -> Printf.sprintf "Heal %d" amount
  | Damage amount -> Printf.sprintf "Damage %d" amount
  | Buff (Power, amount) -> Printf.sprintf "Buff Power %d" amount
  | Buff (Defense, amount) -> Printf.sprintf "Buff Defense %d" amount

(* Helper function to show item type *)
let show_item_type = function
  | Potion -> "Potion"
  | Scroll -> "Scroll"
  | Weapon -> "Weapon"
  | Armor -> "Armor"

(* Helper function to display item *)
let show_item i =
  Printf.sprintf "{ item_type = %s; consumable = %b; item_effect = %s }"
    (show_item_type i.item_type)
    i.consumable
    (show_item_effect i.item_effect)

(* Entity data *)
type t = {
  id : int;
  name : string;
  entity_type : entity_type;
  pos_x : int;
  pos_y : int;
  blocks : bool; (* Whether the entity blocks movement *)
  visible : bool; (* Whether the entity is currently visible *)
  stats : stats option; (* Stats for creatures, None for items *)
  item_data : item option; (* Item data, None for non-items *)
}

let show t =
  Printf.sprintf
    "{ id = %d; name = %s; entity_type = %s; pos_x = %d; pos_y = %d; blocks = \
     %b; visible = %b; stats = %s; item_data = %s }"
    t.id t.name
    (show_entity_type t.entity_type)
    t.pos_x t.pos_y t.blocks t.visible
    (match t.stats with None -> "None" | Some s -> "Some " ^ show_stats s)
    (match t.item_data with None -> "None" | Some i -> "Some " ^ show_item i)

(* Counter for generating unique entity IDs *)
let next_entity_id = ref 0

(* Create a new empty stats with default values *)
let make_stats ?(max_hp = 10) ?(hp = 10) ?(defense = 0) ?(power = 2) () =
  { max_hp; hp; defense; power }

(* Create a new entity with given parameters *)
let make ?(id = -1) ~name ~entity_type ~pos_x ~pos_y ?(blocks = true)
    ?(visible = true) ?stats ?item_data () =
  let entity_id =
    if id >= 0 then id
    else
      let id = !next_entity_id in
      next_entity_id := !next_entity_id + 1;
      id
  in
  {
    id = entity_id;
    name;
    entity_type;
    pos_x;
    pos_y;
    blocks;
    visible;
    stats;
    item_data;
  }

(* Create a player entity *)
let make_player ~pos_x ~pos_y ~name =
  let stats = make_stats ~max_hp:30 ~hp:30 ~defense:2 ~power:5 () in
  let player_type = Player in
  make ~name ~entity_type:player_type ~pos_x ~pos_y ~stats ()

(* Create a basic enemy *)
let make_enemy ~pos_x ~pos_y ~name ?(hp = 10) ?(defense = 0) ?(power = 3) () =
  let stats = make_stats ~max_hp:hp ~hp ~defense ~power () in
  let enemy_type = Enemy in
  make ~name ~entity_type:enemy_type ~pos_x ~pos_y ~stats ()

(* Create an item entity *)
let make_item ~pos_x ~pos_y ~name ~item_type ~item_effect ?(consumable = true)
    () =
  let item_data = { item_type; consumable; item_effect } in
  let item_type_entity = Item in
  make ~name ~entity_type:item_type_entity ~pos_x ~pos_y ~blocks:false
    ~item_data ()

(* Move an entity by a delta *)
let move entity dx dy =
  { entity with pos_x = entity.pos_x + dx; pos_y = entity.pos_y + dy }

(* Set entity position *)
let set_position entity x y = { entity with pos_x = x; pos_y = y }

(* Check if entity is at position *)
let is_at entity x y = entity.pos_x = x && entity.pos_y = y

(* Take damage (returns updated entity) *)
let take_damage entity amount =
  match entity.stats with
  | None -> entity
  | Some stats ->
      let new_hp = max 0 (stats.hp - amount) in
      let new_stats = { stats with hp = new_hp } in
      { entity with stats = Some new_stats }

(* Check if entity is dead *)
let is_dead entity =
  match entity.stats with None -> false | Some stats -> stats.hp <= 0

(* Heal entity (returns updated entity) *)
let heal entity amount =
  match entity.stats with
  | None -> entity
  | Some stats ->
      let new_hp = min stats.max_hp (stats.hp + amount) in
      let new_stats = { stats with hp = new_hp } in
      { entity with stats = Some new_stats }

(* Get entity attack power *)
let get_power entity =
  match entity.stats with None -> 0 | Some stats -> stats.power

(* Get entity defense *)
let get_defense entity =
  match entity.stats with None -> 0 | Some stats -> stats.defense
