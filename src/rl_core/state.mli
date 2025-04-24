type t

val make : debug:bool -> w:int -> h:int -> seed:int -> t
val get_debug : t -> bool

(* Entity *)
val get_entity : t -> Types.Entity.id -> Types.Entity.t option
val get_base_entity : t -> Types.Entity.id -> Types.Entity.base_entity
val get_entities : t -> Types.Entity.t list
val move_entity : t -> Types.Entity.id -> Types.Loc.t -> t
val remove_entity : Types.Entity.id -> t -> t

(* Player *)
val get_player_id : t -> Types.Entity.id
val get_player_entity : t -> Types.Entity.t

(* Actor *)
val get_actor :
  t -> Actor_manager.Actor.actor_id -> Actor_manager.Actor.t option

val add_actor : Actor_manager.Actor.t -> Actor_manager.Actor.actor_id -> t -> t
val remove_actor : Actor_manager.Actor.actor_id -> t -> t

val update_actor :
  t ->
  Actor_manager.Actor.actor_id ->
  (Actor_manager.Actor.t -> Actor_manager.Actor.t) ->
  t

val queue_actor_action :
  t -> Actor_manager.Actor.actor_id -> Types.Action.t -> t

(* Turn queue *)
val get_turn_queue : t -> Turn_queue.t
val set_turn_queue : Turn_queue.t -> t -> t
val schedule_turn_now : Types.Entity.id -> t -> t

(* Control mode *)
val get_mode : t -> Types.CtrlMode.t
val set_mode : t -> Types.CtrlMode.t -> t

(* Tilemap *)
val get_current_map : t -> Dungeon.Tilemap.t
val get_map_manager : t -> Map_manager.t
val set_map_manager : t -> Map_manager.t -> t

(* Actor manager *)
val get_actor_manager : t -> Actor_manager.t
val set_actor_manager : t -> Actor_manager.t -> t

(* Entity manager *)
val get_entities_manager : t -> Entity_manager.t
val set_entities_manager : t -> Entity_manager.t -> t
val get_entity_at_pos : t -> Types.Loc.t -> Types.Entity.t option

(* Level transitions *)
val transition_to_previous_level : t -> t * Map_manager.t
val transition_to_next_level : t -> t * Map_manager.t

(* Spawn *)
val spawn_player_entity :
  pos:Types.Loc.t -> direction:Types.Direction.t -> t -> t

val spawn_creature_entity :
  t ->
  pos:Types.Loc.t ->
  direction:Types.Direction.t ->
  species:string ->
  health:int ->
  glyph:string ->
  name:string ->
  description:string ->
  t * int
