open Base
open Types

(* Import backend action type and direction type *)
module BackendAction = Action
module Direction = Direction

(* Define UI action type, wrapping backend and frontend actions *)
type ui_action =
  | Backend of BackendAction.t
  | ToggleRender
  | ToggleEffects
  | ToggleHybridMode
  | OpenMenu
  | CloseMenu
(* Add more UI-specific actions as needed *)

(* Map keys to ui_action *)
let key_action_map : (Raylib.Key.t * ui_action) list =
  [
    (Raylib.Key.W, Backend (BackendAction.Move Direction.North));
    (Raylib.Key.S, Backend (BackendAction.Move Direction.South));
    (Raylib.Key.A, Backend (BackendAction.Move Direction.West));
    (Raylib.Key.D, Backend (BackendAction.Move Direction.East));
    (Raylib.Key.Up, Backend (BackendAction.Move Direction.North));
    (Raylib.Key.Down, Backend (BackendAction.Move Direction.South));
    (Raylib.Key.Left, Backend (BackendAction.Move Direction.West));
    (Raylib.Key.Right, Backend (BackendAction.Move Direction.East));
    (Raylib.Key.Comma, Backend BackendAction.StairsUp);
    (Raylib.Key.Period, Backend BackendAction.StairsDown);
    (Raylib.Key.Space, Backend BackendAction.Wait);
    (Raylib.Key.T, ToggleRender);
    (* Add more mappings as needed *)
  ]

let action_of_key (key : Raylib.Key.t) =
  Base.List.Assoc.find ~equal:Poly.equal key_action_map key

let get_current_action () =
  let open Raylib in
  List.find_map key_action_map ~f:(fun (k, action) ->
      if is_key_pressed k then Some action else None)

(* Optionally: get all currently pressed actions *)
let get_all_current_actions () =
  let open Raylib in
  List.filter_map key_action_map ~f:(fun (k, action) ->
      if is_key_pressed k then Some action else None)
