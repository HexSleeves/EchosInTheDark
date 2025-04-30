type t = Entity_manager.t

val spawn_player : pos:Rl_types.Loc.t -> t -> Entity_manager.t

val spawn_creature :
  pos:Rl_types.Loc.t ->
  species:Components.Species.t ->
  health:int ->
  glyph:char ->
  name:string ->
  description:string option ->
  faction:Components.Faction.t ->
  t ->
  Entity_manager.t

val spawn_item :
  pos:Rl_types.Loc.t ->
  item_type:Components.Item.Item_data.item_type ->
  quantity:int ->
  name:string ->
  glyph:char ->
  ?description:string option ->
  t ->
  Entity_manager.t

val spawn_corpse : pos:Rl_types.Loc.t -> t -> Entity_manager.t
