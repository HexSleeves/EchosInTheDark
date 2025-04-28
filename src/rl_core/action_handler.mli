type action_result = (int, exn) Result.t

val get_entity_stats : Types.Entity.t -> Types.Stats.t option

val calculate_damage :
  attacker_stats:Types.Stats.t -> defender_stats:Types.Stats.t -> int

val is_entity_dead : Types.Entity.id -> State.t -> bool
val can_use_stairs_down : State.t -> Types.Entity.id -> bool
val can_use_stairs_up : State.t -> Types.Entity.id -> bool

val update_entity_stats :
  Types.Entity.id -> State.t -> (Types.Stats.t -> Types.Stats.t) -> State.t

val handle_entity_death : Types.Entity.id -> State.t -> State.t

val handle_move :
  state:State.t ->
  id:Types.Entity.id ->
  dir:Types.Direction.t ->
  handle_action:
    (State.t -> Types.Entity.id -> Types.Action.t -> State.t * action_result) ->
  State.t * action_result

val handle_action :
  State.t -> Types.Entity.id -> Types.Action.t -> State.t * action_result
