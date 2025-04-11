type screen = Menu | Play | Exit
type t = { selected : int; screen : screen }

let init = { selected = 0; screen = Menu }
let versionString = "Version 1.0"
let copyrightString = "(C) 2023 Yendor"
let menu_items = [ "Play"; "Quit" ]

let render (state : t) =
  let open Raylib in
  match state.screen with
  | Menu ->
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
  | Play -> draw_text "Playing Game..." 10 10 20 Color.white
  | Exit -> draw_text "Exiting..." 10 10 20 Color.white

let handle_event s =
  let open Raylib in
  let key = get_key_pressed () in
  match key with
  | Key.Q -> (s, true)
  | Key.Up -> ({ s with selected = max 0 (s.selected - 1) }, false)
  | Key.Down -> ({ s with selected = min 1 (s.selected + 1) }, false)
  | Key.Enter ->
      if s.selected = 0 then ({ s with screen = Play }, false)
      else ({ s with screen = Exit }, true)
  | _ -> (s, false)

let handle_tick s =
  match s.screen with
  | Menu -> (s, false)
  | Play -> (s, true)
  | Exit -> (s, true)
