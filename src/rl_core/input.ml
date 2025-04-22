(** Input module for mapping key state to action_type. This module is
    backend-agnostic and does not depend on Raylib directly. The caller must
    provide the is_key_pressed function and a module with key fields (e.g.,
    Raylib.Key). *)

open Types

let of_key (key : Raylib.Key.t) : Types.Action.action_type option =
  let open Raylib in
  match key with
  | Key.W | Key.Up -> Some (Move Direction.North)
  | Key.S | Key.Down -> Some (Move Direction.South)
  | Key.A | Key.Left -> Some (Move Direction.West)
  | Key.D | Key.Right -> Some (Move Direction.East)
  | Key.Comma -> Some StairsUp
  | Key.Period -> Some StairsDown
  | Key.Space -> Some Wait
  | _ -> None

let action_from_keys () : Types.Action.action_type option =
  let open Raylib in
  get_key_pressed () |> of_key
