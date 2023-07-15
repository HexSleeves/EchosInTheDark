open Raylib
open Base

class spriteAtlas (tex : Raylib.Texture.t) (spriteW : int) (spriteH : int) =
  let texture = tex in
  let spriteWidth = Float.of_int spriteW in
  let spriteHeight = Float.of_int spriteH in
  let spritesPerRow = Raylib.Texture.width texture / spriteW in
  let spritesPerColumn = Raylib.Texture.height texture / spriteH in
  let maxIndex = spritesPerRow * spritesPerColumn in

  let getRect index =
    if index > maxIndex || index < 0 then
      Raylib.Rectangle.create 0.0 0.0 spriteWidth spriteHeight
    else
      Raylib.Rectangle.create
        (Float.of_int (index % spritesPerRow * spriteW))
        (Float.of_int (index / spritesPerRow * spriteH))
        spriteWidth spriteHeight
  in

  object (s)
    method spriteDimensions = Vector2.create spriteWidth spriteHeight

    method drawSprite index position tint =
      let pos = Vector2.multiply position s#spriteDimensions in

      draw_texture_pro texture (getRect index)
        (Rectangle.create (Vector2.x pos) (Vector2.y pos) spriteWidth
           spriteHeight)
        (Vector2.zero ()) 0.0 tint
  end
