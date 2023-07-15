open Raylib
open Base
open Rl2023.Spriteatlas

let v_zero = Vector2.create 0.0 0.0

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
        v_zero 0.0 Color.white

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
        v_zero 0.0 Color.white;

      (* Actor Layer *)
      let actor_text = RenderTexture.texture actor_layer in
      let actor_width = Texture.width actor_text |> Float.of_int in
      let actor_height = -Texture.height actor_text |> Float.of_int in
      draw_texture_pro actor_text
        (Rectangle.create 0.0 0.0 actor_width actor_height)
        (Rectangle.create 0.0 0.0 w h)
        v_zero 0.0 Color.white;

      end_texture_mode
  end
