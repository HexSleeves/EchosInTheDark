(* Simple backend interface to avoid circular dependencies *)
type backend =
  < get_player_id : int
  ; get_map_width : int
  ; get_map_height : int
  ; is_tile_walkable : int -> int -> bool
  ; move_entity : int -> int -> int -> unit >

(* Game action interface *)
class type game_action = object
  method execute : backend -> (int, exn) Base.Result.t
  method to_string : string
end
