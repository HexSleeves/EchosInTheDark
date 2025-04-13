open Base
open Rl2023
module Gui = Raygui

let panel_w = 400
let panel_h = 300
let y_step = 60
let field_w = 180
let field_h = 32
let panel_x screen_w = (screen_w - panel_w) / 2
let panel_y screen_h = (screen_h - panel_h) / 2

type focus_types = [ `Seed | `Width | `Height | `None ]
type action_types = [ `Continue | `Back ]

(* Removed global action ref; state is now passed explicitly *)

type t = {
  seed : int;
  width : int;
  height : int;
  seed_text : string;
  width_text : string;
  height_text : string;
  mutable focus : focus_types;
  action : action_types option;
}

let init =
  {
    seed = 0;
    width = 80;
    height = 50;
    seed_text = "0";
    width_text = "80";
    height_text = "50";
    focus = `Width;
    action = None;
  }

let parse_int s default = try Int.of_string s with _ -> default

let focused_text_box s (rect : Raylib.Rectangle.t) (text : string)
    (focus : focus_types) =
  let filter_numeric s = String.filter s ~f:(fun c -> Char.is_digit c) in

  match Raygui.text_box rect text (phys_equal focus s.focus) with
  | vl, true ->
      s.focus <- focus;
      filter_numeric vl
  | vl, false -> filter_numeric vl

(* handle_tick is now a no-op, as all state is passed via render *)
let handle_tick (s : t) = s

(*  Immediate mode rendering *)
let render (s : t) : t option =
  Printf.sprintf "RENDER: focused: %s\n"
    (match s.focus with
    | `Width -> "Width"
    | `Height -> "Height"
    | `Seed -> "Seed"
    | `None -> "None")
  |> Stdio.print_string;

  let open Raylib in
  let screen_w = Raylib.get_screen_width () in
  let screen_h = Raylib.get_screen_height () in
  let panel_x = panel_x screen_w in
  let panel_y = panel_y screen_h in
  let label_x = panel_x + 40 in
  let field_x = panel_x + 160 in
  let y0 = panel_y + 40 in

  (* Draw panel *)
  draw_rectangle panel_x panel_y panel_w panel_h Color.darkgray;

  (* Draw labels *)
  draw_text "Map Width:" label_x y0 20 Color.white;
  draw_text "Map Height:" label_x (y0 + y_step) 20 Color.white;
  draw_text "Seed:" label_x (y0 + (2 * y_step)) 20 Color.white;

  (* Draw input fields *)
  Raygui.(set_style (TextBox `Text_alignment) TextAlignment.(to_int Left));

  let width_text =
    focused_text_box s
      (Helpers.rectangle_of_tuple
         ( Float.of_int field_x,
           Float.of_int y0,
           Float.of_int field_w,
           Float.of_int field_h ))
      s.width_text `Width
  in

  let height_text =
    focused_text_box s
      (Helpers.rectangle_of_tuple
         ( Float.of_int field_x,
           Float.of_int (y0 + y_step),
           Float.of_int field_w,
           Float.of_int field_h ))
      s.height_text `Height
  in

  let seed_text =
    focused_text_box s
      (Helpers.rectangle_of_tuple
         ( Float.of_int field_x,
           Float.of_int (y0 + (2 * y_step)),
           Float.of_int field_w,
           Float.of_int field_h ))
      s.seed_text `Seed
  in

  (* Draw buttons *)
  let btn_w = 120 in
  let btn_h = 40 in
  let btn_y = panel_y + panel_h - btn_h - 30 in
  let btn_continue_x = panel_x + 40 in
  let btn_back_x = panel_x + panel_w - btn_w - 40 in

  let continue_pressed =
    Gui.button
      (Helpers.rectangle_of_tuple
         ( Float.of_int btn_continue_x,
           Float.of_int btn_y,
           Float.of_int btn_w,
           Float.of_int btn_h ))
      "Continue"
  in
  let back_pressed =
    Gui.button
      (Helpers.rectangle_of_tuple
         ( Float.of_int btn_back_x,
           Float.of_int btn_y,
           Float.of_int btn_w,
           Float.of_int btn_h ))
      "Back"
  in

  let action =
    if continue_pressed then Some `Continue
    else if back_pressed then Some `Back
    else None
  in

  Printf.sprintf "Action: %s\n"
    (match action with
    | Some `Continue -> "Continue"
    | Some `Back -> "Back"
    | None -> "None")
  |> Stdio.print_string;

  let new_state =
    {
      width_text;
      height_text;
      seed_text;
      width = parse_int width_text s.width;
      height = parse_int height_text s.height;
      seed = parse_int seed_text s.seed;
      focus = s.focus;
      action;
    }
  in

  Some new_state
