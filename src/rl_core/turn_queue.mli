type t

val create : unit -> t
val current_time : t -> int
val print_turn_queue : t -> unit
val schedule_turn : t -> Types.Entity.id -> int -> t
val schedule_now : t -> Types.Entity.id -> t
val remove_actor : t -> Types.Entity.id -> t
val get_next_actor : t -> (Types.Entity.id * int) option * t
val peek_next : t -> (Types.Entity.id * int) option
val is_scheduled : t -> Types.Entity.id -> bool
val time_until : t -> int -> int
val is_before : t -> int -> int -> bool
val to_list : t -> (int * Types.Entity.id) list
val copy : t -> t
