(* open Containers *)

(* All state *)
type t = {
  screen : Screen.t;
  font : Raylib.Font.t;
  mutable backend : Backend.t;
  mutable player_pos : int * int;
}

(* Backend *)
let get_backend t = t.backend
let set_backend t backend = t.backend <- backend

(* Screen *)
let get_screen t = t.screen

(* Screen transitions *)
let to_play t = { t with screen = Screen.Play }
let to_menu t menu_state = { t with screen = Screen.MainMenu menu_state }

let get_player_pos t = ref t.player_pos
