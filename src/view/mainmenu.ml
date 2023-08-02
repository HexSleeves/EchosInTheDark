type t = { selected : int }

let init = { selected = 0 }
let versionString = "Version 1.0"
let copyrightString = "(C) 2023 Yendor"
let menu_items = [ "Play"; "Quit" ]

let render (state : t) =
  let open Raylib in
  (* Draw the version and copyright strings *)
  Raylib.draw_text versionString 2 (get_screen_height () - 25) 20 Color.gray;
  Raylib.draw_text copyrightString
    (get_screen_width () - 10 - measure_text copyrightString 20)
    (get_screen_height () - 25)
    20 Color.gray;

  (* Menu *)
  draw_text "Main Menu" 10 10 20 Color.white;

  let selection = state.selected in

  (* let draw_text text x y size color =
       let color = if selection = y / 30 then Color.red else color in
       draw_text text x y size color
     in *)
  List.iteri
    (fun i item ->
      let color = if selection = i then Color.red else Color.white in
      let txt = if selection = i then "> " ^ item else "  " ^ item in
      draw_text txt 10 (40 + (i * 30)) 20 color)
    menu_items

let handle_event s = ()
let handle_tick s = ()
