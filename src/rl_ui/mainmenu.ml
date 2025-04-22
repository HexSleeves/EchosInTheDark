open Raylib
open Base

type result = Play | Quit
type t = { selected : int }

let versionString = "Version 1.0"
let copyrightString = "(C) 2025 Yendor"
let menu_items = [ "Play"; "Quit" ]
let menu_length = List.length menu_items

let handle_keyboard () =
  if is_key_pressed Key.Q then Some `Quit
  else if is_key_pressed Key.Enter then Some `Enter
  else if is_key_pressed Key.Up then Some `Up
  else if is_key_pressed Key.Down then Some `Down
  else None

let handle_tick state =
  match handle_keyboard () with
  | Some `Quit -> (state, Some Quit)
  | Some `Enter -> (
      match state.selected with
      | 0 -> (state, Some Play)
      | 1 -> (state, Some Quit)
      | _ -> (state, None))
  | Some `Up ->
      let selected =
        if state.selected = 0 then menu_length - 1 else state.selected - 1
      in
      ({ selected }, None)
  | Some `Down ->
      let selected =
        if state.selected = menu_length - 1 then 0 else state.selected + 1
      in
      ({ selected }, None)
  | None -> (state, None)

let render (state : t) : t option =
  let open Raylib in
  (* Draw the version and copyright strings *)
  Raylib.draw_text versionString 2 (get_screen_height () - 25) 20 Color.gray;
  Raylib.draw_text copyrightString
    (get_screen_width () - 10 - measure_text copyrightString 20)
    (get_screen_height () - 25)
    20 Color.gray;

  (* Centered "Main Menu" title *)
  let title = "Main Menu" in
  let title_font_size = 20 in
  let title_width = measure_text title title_font_size in
  let title_x = (get_screen_width () - title_width) / 2 in
  draw_text title title_x 10 title_font_size Color.white;

  let selection = state.selected in
  let menu_font_size = 20 in
  let menu_start_y = 40 in
  let menu_spacing = 30 in

  List.iteri
    ~f:(fun i item ->
      let color = if selection = i then Color.red else Color.white in
      let txt_width = measure_text item menu_font_size in
      let txt_x = (get_screen_width () - txt_width) / 2 in
      let txt_y = menu_start_y + (i * menu_spacing) in
      (* Draw the '>' icon if this is the selected item *)
      (if selection = i then
         let icon = ">" in
         let icon_width = measure_text icon menu_font_size in
         let icon_x = txt_x - icon_width - 10 in
         (* 10px padding *)
         draw_text icon icon_x txt_y menu_font_size color);
      draw_text item txt_x txt_y menu_font_size color)
    menu_items;

  None
