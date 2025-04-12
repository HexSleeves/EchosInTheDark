type t = { selected : int }

let init = { selected = 0 }
let versionString = "Version 1.0"
let copyrightString = "(C) 2023 Yendor"
let menu_items = [ "Play"; "Quit" ]

let handle_event s =
  let open Raylib in
  let key = get_key_pressed () in
  let enter_pressed = key = Key.Enter in
  match key with
  | Key.Q -> (s, true, false)
  | Key.Up -> ({ selected = max 0 (s.selected - 1) }, false, enter_pressed)
  | Key.Down -> ({ selected = min 1 (s.selected + 1) }, false, enter_pressed)
  | _ -> (s, false, enter_pressed)

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
  List.iteri
    (fun i item ->
      let color = if selection = i then Color.red else Color.white in
      let txt = if selection = i then "> " ^ item else "  " ^ item in
      draw_text txt 10 (40 + (i * 30)) 20 color)
    menu_items
