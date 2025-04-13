(* Helper to update the state's screen field based on an optional screen update *)

let rectangle_of_tuple (x, y, w, h) = Raylib.Rectangle.create x y w h
