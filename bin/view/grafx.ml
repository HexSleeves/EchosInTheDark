open Tsdl
open Renderer

(* choose color *)
let set_color r g b a = GlDraw.color ~alpha:a (r, g, b)

let draw_gl_scene win draw_func =
  let open Gl in
  
	(* Clear The Screen And The Depth Buffer *)
  GlClear.color (0.0, 0.0, 0.0);
  GlClear.clear [ `color; `depth ];
  
	(* Reset The View*)
  GlMat.load_identity ();
  GlMat.translate ~x:0.0 ~y:0.0 ~z:0.0 ();
  set_color 1.0 1.0 1.0 1.0;
  GlTex.bind_texture ~target:`texture_2d Renderer.texture.(0);
  GlDraw.begins `quads ;
  
	(* Main Draw fn *)
  draw_func ();

  (* Clear *)
  set_color 1.0 1.0 1.0 1.0;
  GlDraw.ends ();

  Sdl.gl_swap_window win;
	[@@ocamlformat "disable"]
