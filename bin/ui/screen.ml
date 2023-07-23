open Notty
open Lwt.Infix
open Notty_lwt
open Notty.Infix

(* Everything related to the screen *)
type t = MainMenu | MapGen of Mapgen.t option | Play

let dot = I.string A.(fg lightred) "."
let wall = I.string A.(fg lightcyan) "#"

let r (w, h) =
  I.tabulate w (h - 1) (fun x y -> dot)
  <-> I.(strf ~attr:A.(fg lightblack) "[generation]" |> hsnap ~align:`Left w)

let render term = function
  | MainMenu -> Lwt.return_unit
  | MapGen data -> Lwt.return_unit
  | Play -> Term.image term (r (Term.size term))
