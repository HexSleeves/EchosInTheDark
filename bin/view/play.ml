(* let dot = I.string A.(fg lightred) "."
   let wall = I.string A.(fg lightcyan) "#"
   let player = I.string A.(fg yellow) "@"

   let render (state : State.t) =
     let backend = state.backend in
     let get_tile x y =
       match Backend.get_tile backend x y with Wall -> wall | Floor -> dot
     in

     let term = state.renderer in
     let w, h = Term.size term in

     let is_player x y = state.player_pos = (x, y) in

     let render_inner =
       I.tabulate w (h - 1) (fun x y ->
           match is_player x y with true -> player | false -> get_tile x y)
       <-> I.(strf ~attr:A.(fg lightblack) "[generation]" |> hsnap ~align:`Left w)
     in

     Term.image term render_inner *)
