type t

val create : unit -> t
val add : Entities.Types.Entity.t -> t -> t
val remove : int -> t -> t
val copy : t -> t

val find :
  int -> Entities.Types.Entity.t option -> t -> Entities.Types.Entity.t option

val find_unsafe : int -> t -> Entities.Types.Entity.t
val find_by_pos : Entities.Types.Loc.t -> t -> Entities.Types.Entity.t option
val find_player : t -> Entities.Types.Entity.t option
val find_player_id : t -> int option

val update :
  int -> (Entities.Types.Entity.t -> Entities.Types.Entity.t) -> t -> t

val to_list : t -> Entities.Types.Entity.t list
val add_entity : Entities.Types.Entity.t -> t -> t

val spawn_player :
  t -> pos:Entities.Types.Loc.t -> direction:Entities.Types.Direction.t -> t

val spawn_creature :
  t ->
  pos:Entities.Types.Loc.t ->
  direction:Entities.Types.Direction.t ->
  species:string ->
  health:int ->
  glyph:string ->
  name:string ->
  description:string ->
  faction:Entities.Types.faction ->
  t

val spawn_item :
  t ->
  pos:Entities.Types.Loc.t ->
  direction:Entities.Types.Direction.t ->
  item_type:Entities.Types.Item.item_type ->
  quantity:int ->
  name:string ->
  glyph:string ->
  ?description:string option ->
  unit ->
  t

val spawn_corpse : Entities.Types.Loc.t -> t -> t

val update_entity_stats :
  t ->
  Entities.Types.Entity.id ->
  (Entities.Types.Stats.t -> Entities.Types.Stats.t) ->
  t
