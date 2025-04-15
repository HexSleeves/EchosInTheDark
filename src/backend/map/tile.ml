type t = Wall | Floor [@@deriving eq, yojson, enum, show]

let walkable = function Wall -> false | _ -> true
