open Raylib
open Rl2023.Spriteatlas

class sharedstate (imagePath : string) (spriteWidth : int) (spriteHeight : int)
  (screenWidth : int) (screenHeight : int) =
  let spritesheet =
    new spriteAtlas (load_texture imagePath) spriteWidth spriteHeight
  in
  let screen_texture =
    load_render_texture (screenWidth * spriteWidth) (screenHeight * spriteHeight)
  in

  let map_layer =
    load_render_texture (screenWidth * spriteWidth) (screenHeight * spriteHeight)
  in
  let actor_layer =
    load_render_texture (screenWidth * spriteWidth) (screenHeight * spriteHeight)
  in

  object
    method get_spritesheet = spritesheet

    method draw_screen_texture =
      let text = RenderTexture.texture screen_texture in

      draw_texture_pro text
        (Rectangle.create 0.0 0.0
           (Float.of_int (Texture.width text))
           (Float.of_int (-Texture.height text)))
        (Rectangle.create 0.0 0.0
           (get_screen_width () |> Float.of_int)
           (get_screen_height () |> Float.of_int))
        Utils.v_zero 0.0 Color.white

    method render_layers =
      let w =
        RenderTexture.texture screen_texture |> Texture.width |> Float.of_int
      in
      let h =
        RenderTexture.texture screen_texture |> Texture.height |> Float.of_int
      in

      begin_texture_mode screen_texture;
      clear_background Color.black;

      (* Map Layer *)
      let map_text = RenderTexture.texture map_layer in
      let map_width = Texture.width map_text |> Float.of_int in
      let map_height = -Texture.height map_text |> Float.of_int in
      draw_texture_pro map_text
        (Rectangle.create 0.0 0.0 map_width map_height)
        (Rectangle.create 0.0 0.0 w h)
        Utils.v_zero 0.0 Color.white;

      (* Actor Layer *)
      let actor_text = RenderTexture.texture actor_layer in
      let actor_width = Texture.width actor_text |> Float.of_int in
      let actor_height = -Texture.height actor_text |> Float.of_int in
      draw_texture_pro actor_text
        (Rectangle.create 0.0 0.0 actor_width actor_height)
        (Rectangle.create 0.0 0.0 w h)
        Utils.v_zero 0.0 Color.white;

      end_texture_mode ()
  end

module CtrlM = struct
  type invclass = InvGround | InvUnit
  type invprop = invclass * int * int * Unit.t * Unit.t list
  type t = Normal | Died of float
end

type t = { debug : bool; random_seed : string; cm : CtrlM.t }

let make w h used_seed debug =
  let _ = w in
  let _ = h in
  (* let geo_w = 45 in *)
  (* let geo_h = 45 in *)
  { debug; random_seed = used_seed; cm = CtrlM.Normal }

let init seed b_debug =
  let max_seed = 1000000000 in
  let hash_string s =
    Utils.fold_lim
      (fun a i -> ((a * 256) + Char.code s.[i]) mod (max_seed / 512))
      0 0
      (String.length s - 1)
  in

  Random.init (hash_string seed);
  make 25 16 seed b_debug

let init_full opt_string b_debug =
  let seed =
    match opt_string with
    | Some s -> s
    | None ->
        let rnd_seed_string () =
          let len = 1 + Random.int 6 in
          let s =
            String.init len (fun _ -> Char.chr (Char.code 'a' + Random.int 26))
          in
          Printf.printf "Random seed: %s\n%!" s;
          s
        in

        rnd_seed_string ()
  in
  init seed b_debug

(* ~ game modes *)
type game_mode = Play of t | Exit
