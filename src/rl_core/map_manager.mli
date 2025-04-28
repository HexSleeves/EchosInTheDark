type t

val create : config:Mapgen.Config.t -> current_level:int -> t
val get_current_map : t -> Dungeon.Tilemap.t
val get_current_level : t -> int
val get_current_entities : t -> Entity_manager.t option
val get_entities_by_level : t -> int -> Entity_manager.t
val can_go_to_previous_level : t -> bool
val can_go_to_next_level : t -> bool
val go_to_previous_level : t -> t
val go_to_next_level : t -> t

val save_level_state :
  t ->
  int ->
  entities:Entity_manager.t ->
  actor_manager:Actor_manager.t ->
  turn_queue:Turn_queue.t ->
  t

val load_level_state :
  t -> t * Entity_manager.t * Actor_manager.t * Turn_queue.t
