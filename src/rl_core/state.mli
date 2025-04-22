type t

val make : debug:bool -> w:int -> h:int -> seed:int -> t
val get_entity : t -> Types.Entity.entity_id -> Types.Entity.entity option
val get_player : t -> Types.Entity.entity
val move_entity : t -> Types.Entity.entity_id -> Types.Loc.t -> t
val get_entities : t -> Types.Entity.entity list

val get_actor :
  t -> Actor_manager.Actor.actor_id -> Actor_manager.Actor.t option

val add_actor : t -> Actor_manager.Actor.t -> Actor_manager.Actor.actor_id -> t
val remove_actor : t -> Actor_manager.Actor.actor_id -> t

val update_actor :
  t ->
  Actor_manager.Actor.actor_id ->
  (Actor_manager.Actor.t -> Actor_manager.Actor.t) ->
  t

val queue_actor_action :
  t -> Actor_manager.Actor.actor_id -> Types.Action.t -> t

val spawn_player_entity :
  t -> pos:Types.Loc.t -> direction:Types.Direction.t -> actor_id:int -> t

val spawn_creature_entity :
  t ->
  pos:Types.Loc.t ->
  direction:Types.Direction.t ->
  species:string ->
  health:int ->
  glyph:string ->
  name:string ->
  actor_id:int ->
  description:string ->
  t * int

val get_debug : t -> bool

(* Turn queue *)
val get_turn_queue : t -> Turn_queue.t
val set_turn_queue : t -> Turn_queue.t -> t
val schedule_turn_now : t -> Types.Entity.entity_id -> t

(* Control mode *)
val get_mode : t -> Types.CtrlMode.t
val set_mode : t -> Types.CtrlMode.t -> t

(* Tilemap *)
val get_current_map : t -> Map.Tilemap.t
val get_map_manager : t -> Map_manager.t
val set_map_manager : t -> Map_manager.t -> t

(* Actor manager *)
val get_actor_manager : t -> Actor_manager.t
val set_actor_manager : t -> Actor_manager.t -> t

(* Entity manager *)
val get_entities_manager : t -> Entity_manager.t
val set_entities_manager : t -> Entity_manager.t -> t
val get_entity_at_pos : t -> Types.Loc.t -> Types.Entity.entity option

(* Level transitions *)
val transition_to_previous_level : t -> t * Map_manager.t
val transition_to_next_level : t -> t * Map_manager.t

val update_entity_stats :
  t -> Types.Entity.entity_id -> (Types.Stats.t -> Types.Stats.t) -> t

val handle_entity_death : t -> Types.Entity.entity_id -> t
