open Base
open Stdio
open Config

let menu header options width =
  let open Raylib in

  let header_height = (measure_text header tile_height) / (width * tile_width) in
  let header_height =
    if String.length header = 0 then
      0
    else
      max header_height 1
  in
  let height = (List.length options) + header_height in

  let x = (screen_width / 2) - (width / 2) in
  let y = (screen_height / 2) - (height / 2) in
  let x = x * tile_width in
  let y = y * tile_height in
  draw_text header x y tile_height Color.white;

  let options = List.mapi options ~f:(fun i option -> (i, option)) in

  let rec draw_options options =
    match options with
    | [] -> ()
    | (i, option) :: rest ->
      let menu_letter = Char.to_int 'a' + i in
      let menu_letter = Char.of_int_exn menu_letter in
      let text = Printf.sprintf "(%c) %s" menu_letter option in

      draw_text 
        text
        x (y + (header_height + i) * tile_height)
        tile_height Color.white;
      draw_options rest
  in

  draw_options options;
;;

let main_menu () =
  let image = Raylib.load_image "static/menu_background.png" in
  let texture = Raylib.load_texture_from_image image in
  Raylib.unload_image image;
  Raylib.set_texture_wrap texture Raylib.TextureWrap.Mirror_clamp;

  let width = Float.of_int (Raylib.Texture.width texture)  in
  let height = Float.of_int (Raylib.Texture.height texture)  in

  let choices = ["New Game"; "Continue"; "Quit"] in

  let rec loop () =
    match Raylib.window_should_close () with
    | true -> Raylib.close_window ()
    | false ->
        let open Raylib in

        (* let pressed_key = get_char_pressed () in *)

        begin_drawing ();
        clear_background Color.black;

        draw_texture_pro 
          texture 
          (Raylib.Rectangle.create 0.0 0.0 width height)
          (Raylib.Rectangle.create 0.0 0.0 800.0 640.0)
          (Raylib.Vector2.create 0.0 0.0)
          0.0
          Color.white;

        (* Game Title *)
        draw_text 
          "TOMBS OF THE ANCIENT KINGS" 
          ((screen_width / 2) * tile_width - measure_text "TOMBS OF THE ANCIENT KINGS" tile_height / 2) 
          ((screen_height / 2 - 4) * tile_height) tile_height Color.yellow;

        draw_text 
          "By me!" 
          ((screen_width / 2) * tile_width - measure_text "By me!" tile_height / 2) 
          ((screen_height / 2 - 2) * tile_height) tile_height Color.yellow;

        menu "" choices 24;

        if is_key_pressed Key.A then
          print_string "A pressed";
        if is_key_pressed Key.B then
          print_string "B pressed";
        if is_key_pressed Key.C then
          Caml.exit 0;

        end_drawing ();
        loop () 
      in

  loop()