open Base
open Actors
module Tilemap = Dungeon.Tilemap
module Entity = Types.Entity

type t = State.t

let make ~debug ~w ~h ~seed ~current_level : t =
  State.make ~debug ~w ~h ~seed ~current_level

let get_debug (state : t) : bool = State.get_debug state

(* Mode *)
let get_mode (state : t) = State.get_mode state
let set_mode mode (state : t) : t = State.set_mode mode state

(* Entity *)
let get_player_id (state : t) : Types.Entity.id = State.get_player_id state

let get_player_entity (state : t) : Types.Entity.t =
  State.get_player_entity state

let get_entities (state : t) : Types.Entity.t list = State.get_entities state

let move_entity (id : Types.Entity.id) (loc : Types.Loc.t) (state : t) : t =
  State.move_entity id loc state

let queue_actor_action (state : t) (actor_id : Actor.actor_id)
    (action : Types.Action.t) : t =
  State.queue_actor_action state actor_id action

(* Map *)
let get_current_map (state : t) : Tilemap.t = State.get_current_map state
let process_turns (state : t) : t = Systems.Turn_system.process_turns state

let run_ai_step (state : t) : t =
  let open Types in
  let creatures = State.get_creatures state in
  List.fold creatures ~init:state ~f:(fun st (base, data) ->
      let id = base.id in
      match State.get_actor st id with
      | Some actor when Option.is_none (Actor.peek_next_action actor) ->
          let action = Ai.Wander.decide (Entity.Creature (base, data)) st in
          queue_actor_action st id action
      | _ -> st)
  |> fun state -> State.set_normal_mode state
