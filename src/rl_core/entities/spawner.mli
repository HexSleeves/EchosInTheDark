open Types

type t = Entity_manager.t

val spawn_player : pos:Loc.t -> direction:Direction.t -> t -> t

val spawn_creature :
  pos:Loc.t ->
  direction:Direction.t ->
  species:string ->
  health:int ->
  glyph:string ->
  name:string ->
  description:string option ->
  faction:faction ->
  t ->
  t

val spawn_item :
  pos:Loc.t ->
  direction:Direction.t ->
  item_type:Item.item_type ->
  quantity:int ->
  name:string ->
  glyph:string ->
  ?description:string option ->
  t ->
  t

val spawn_corpse : pos:Loc.t -> t -> t
