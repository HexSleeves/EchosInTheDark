type t = Entity_manager.t

val spawn_player : pos:Types.Loc.t -> t -> Entity_manager.t

val spawn_creature :
  pos:Types.Loc.t ->
  species:Components.Species.t ->
  health:int ->
  glyph:char ->
  name:string ->
  description:string option ->
  faction:Components.Faction.t ->
  t ->
  Entity_manager.t

val spawn_item :
  pos:Types.Loc.t ->
  item_type:Components.Item.Item_data.item_type ->
  quantity:int ->
  name:string ->
  glyph:char ->
  ?description:string option ->
  t ->
  Entity_manager.t

val spawn_corpse : pos:Types.Loc.t -> t -> Entity_manager.t
