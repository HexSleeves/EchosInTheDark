open Base
open Actors
open Types
module Tilemap = Dungeon.Tilemap

type t = State.t

let make ~debug ~w ~h ~seed ~current_level : t =
  (* Initialize systems *)
  Systems.Log_system.init ();
  Systems.Combat_system.init ();
  State.make ~debug ~w ~h ~seed ~current_level

let get_debug (state : t) : bool = State.get_debug state

(* Mode *)
let get_mode (state : t) = State.get_mode state
let set_mode mode (state : t) : t = State.set_mode mode state

(* Entity *)
let get_player_id (state : t) : entity_id = State.get_player_id state
let get_entities (state : t) : entity_id list = State.get_entities state

let queue_actor_action (state : t) (actor_id : Actor.actor_id)
    (action : Action.t) : t =
  State.queue_actor_action state actor_id action

(* Map *)
let get_current_map (state : t) : Tilemap.t option = State.get_current_map state
let get_equipment (id : entity_id) = State.get_equipment id

let set_equipment (id : entity_id) (eq : Components.Equipment.t) =
  State.set_equipment id eq

let move_entity (id : entity_id) (loc : Loc.t) (state : t) : t =
  State.move_entity id loc state

let process_turns (state : t) : t = Systems.Turn_system.process_turns state

let run_ai_step (state : t) : t =
  List.fold (State.get_creatures state) ~init:state
    ~f:(fun state' creature_id ->
      match State.get_actor state' creature_id with
      | Some actor when Option.is_none (Actor.peek_next_action actor) ->
          Ai.Wander.decide creature_id state'
          |> queue_actor_action state' creature_id
      | _ -> state')
  |> fun state -> State.set_normal_mode state
