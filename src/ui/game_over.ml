open Base

(* Render the game over screen *)
let render (_state : State.t) : unit =
  let open Raylib in
  (* Create a semi-transparent overlay *)
  let screen_width = get_screen_width () in
  let screen_height = get_screen_height () in
  draw_rectangle 0 0 screen_width screen_height (fade Color.black 0.7);

  (* Draw the game over message *)
  let title = "GAME OVER" in
  let title_size = 40 in
  let title_width = measure_text title title_size in
  let title_x = (screen_width - title_width) / 2 in
  let title_y = screen_height / 3 in
  draw_text title title_x title_y title_size Color.red;

  (* Draw the death message *)
  let death_msg = "You have been slain!" in
  let msg_size = 20 in
  let msg_width = measure_text death_msg msg_size in
  let msg_x = (screen_width - msg_width) / 2 in
  let msg_y = title_y + 60 in
  draw_text death_msg msg_x msg_y msg_size Color.white;

  (* Draw the restart instructions *)
  let restart_msg = "Press ENTER to restart" in
  let restart_size = 20 in
  let restart_width = measure_text restart_msg restart_size in
  let restart_x = (screen_width - restart_width) / 2 in
  let restart_y = msg_y + 60 in
  draw_text restart_msg restart_x restart_y restart_size Color.white;

  (* Draw the quit instructions *)
  let quit_msg = "Press ESC to quit" in
  let quit_size = 20 in
  let quit_width = measure_text quit_msg quit_size in
  let quit_x = (screen_width - quit_width) / 2 in
  let quit_y = restart_y + 30 in
  draw_text quit_msg quit_x quit_y quit_size Color.white;

  (* Calculate time since death *)
  let death_time = 100. in
  let time_elapsed = get_time () -. death_time in
  let time_msg = Printf.sprintf "Time survived: %.1f seconds" time_elapsed in
  let time_size = 16 in
  let time_width = measure_text time_msg time_size in
  let time_x = (screen_width - time_width) / 2 in
  let time_y = quit_y + 60 in
  draw_text time_msg time_x time_y time_size Color.gray

(* Handle game over screen input *)
let handle_tick (state : State.t) : State.t =
  let open Raylib in
  if is_key_pressed Key.Escape then { state with quitting = true } else state
