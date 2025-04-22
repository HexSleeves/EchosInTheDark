(** Input module for mapping key state to action_type. This module is
    backend-agnostic and does not depend on Raylib directly. The caller must
    provide the is_key_pressed function and a module with key fields (e.g.,
    Raylib.Key). *)

open Action

(** Map a raw Raylib key into one of our UI key_actions. *)
let of_key (key : Raylib.Key.t) : action_type option =
  let open Raylib in
  match key with
  | Key.W | Key.Up -> Some (Move Types.North)
  | Key.S | Key.Down -> Some (Move Types.South)
  | Key.A | Key.Left -> Some (Move Types.West)
  | Key.D | Key.Right -> Some (Move Types.East)
  | Key.Comma -> Some StairsUp
  | Key.Period -> Some StairsDown
  | Key.Space -> Some Wait
  | _ -> None

let action_from_keys () : action_type option =
  let open Raylib in
  get_key_pressed () |> of_key
