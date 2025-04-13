(* Entity types *)
type entity_type = Player | Enemy | Item

(* Entity stats for creatures *)
type stats = {
  max_hp : int;
  hp : int;
  defense : int;
  power : int;
}

(* Item types and effects *)
type buff_type = Power | Defense

type item_effect =
  | Heal of int
  | Damage of int
  | Buff of buff_type * int

type item_type = Potion | Scroll | Weapon | Armor

type item = {
  item_type : item_type;
  consumable : bool;
  item_effect : item_effect;
}

(* Entity data *)
type t = {
  id : int;
  name : string;
  entity_type : entity_type;
  pos_x : int;
  pos_y : int;
  blocks : bool;
  visible : bool;
  stats : stats option;
  item_data : item option;
}

(* Create a new empty stats with default values *)
val make_stats : ?max_hp:int -> ?hp:int -> ?defense:int -> ?power:int -> unit -> stats

(* Create a new entity with given parameters *)
val make : ?id:int -> name:string -> entity_type:entity_type -> pos_x:int -> pos_y:int ->
           ?blocks:bool -> ?visible:bool -> ?stats:stats -> ?item_data:item -> unit -> t

(* Create a player entity *)
val make_player : pos_x:int -> pos_y:int -> name:string -> t

(* Create a basic enemy *)
val make_enemy : pos_x:int -> pos_y:int -> name:string -> ?hp:int -> ?defense:int -> ?power:int -> unit -> t

(* Create an item entity *)
val make_item : pos_x:int -> pos_y:int -> name:string -> item_type:item_type ->
                item_effect:item_effect -> ?consumable:bool -> unit -> t

(* Move an entity by a delta *)
val move : t -> int -> int -> t

(* Set entity position *)
val set_position : t -> int -> int -> t

(* Check if entity is at position *)
val is_at : t -> int -> int -> bool

(* Take damage (returns updated entity) *)
val take_damage : t -> int -> t

(* Check if entity is dead *)
val is_dead : t -> bool

(* Heal entity (returns updated entity) *)
val heal : t -> int -> t

(* Get entity attack power *)
val get_power : t -> int

(* Get entity defense *)
val get_defense : t -> int
