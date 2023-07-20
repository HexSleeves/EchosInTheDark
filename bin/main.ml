let width = 960
let height = 720
let sprite_size = 14.0

let setup () =
  let open Raylib in
  init_window width height
    "raylib [textures] example - texture source and destination rectangles";
  let scarfy = load_texture "resources/tileset.png" in

  set_target_fps 60;
  scarfy

let rec loop rotation scarfy =
  match Raylib.window_should_close () with
  | true -> Raylib.close_window ()
  | false ->
      let open Raylib in
      begin_drawing ();
      clear_background Color.raywhite;

      (* draw_texture scarfy 0 0 Color.white; *)
      let human_y = sprite_size *. 12. in
      let rect = Rectangle.create 0.0 human_y sprite_size sprite_size in
      draw_texture_rec scarfy rect (Vector2.create 0.0 0.0) Color.white;

      (* draw_texture_pro scarfy source_rec dest_rec origin rotation Color.white; *)
      draw_text "(c) Scarfy sprite by Eiden Marsal" (width - 200) (height - 20)
        10 Color.gray;

      end_drawing ();
      loop (rotation +. 1.0) scarfy

let () = setup () |> loop 0.0
