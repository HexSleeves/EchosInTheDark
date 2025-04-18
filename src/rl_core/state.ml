module MultiLevelState = struct
  type t = {
    current_level : int;
    total_levels : int;
    player_has_amulet : bool;
    maps : (Base.int, Map.Tilemap.t) Base.Hashtbl.t;
  }
end

type game_state = { backend : Backend.t; multi_level : MultiLevelState.t }
