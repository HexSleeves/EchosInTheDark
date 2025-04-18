type t = Wall | Floor | Stairs_up | Stairs_down
[@@deriving eq, yojson, enum, show]

let is_wall = function Wall -> true | _ -> false
let is_floor = function Floor -> true | _ -> false
let is_walkable = function Wall -> false | _ -> true
