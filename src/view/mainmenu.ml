type t = { selected : int }

let init = { selected = 0 }
let versionString = "Version 1.0"
let copyrightString = "(C) 2023 Yendor"
let menu_items = [ "Play"; "Quit" ]

type result = Continue of t | Play | Quit

(* Handle events *)
(* Returns a tuple of the new state, should_quit, should_play *)
let handle_event s =
  let open Raylib in
  let key = get_key_pressed () in
  let should_quit = false in
  let should_play = false in
  match key with
  | Key.Q -> (s, true, should_play)
  | Key.Up -> ({ selected = max 0 (s.selected - 1) }, should_quit, should_play)
  | Key.Down -> ({ selected = min 1 (s.selected + 1) }, should_quit, should_play)
  | Key.Enter -> (s, s.selected = 1, s.selected = 0)
  | _ -> (s, should_quit, should_play)

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
