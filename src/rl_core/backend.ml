module Tilemap = Map.Tilemap
module Actor = Actor_manager.Actor
open Base

type t = State.t

let make ~debug ~w ~h ~seed : t = State.make ~debug ~w ~h ~seed

(* Helper function to get player entity *)
let get_mode (state : t) : Types.CtrlMode.t = State.get_mode state

let set_mode (state : t) (mode : Types.CtrlMode.t) : t =
  State.set_mode state mode

let get_player (state : t) : Types.Entity.entity = State.get_player state
let get_current_map (state : t) : Tilemap.t = State.get_current_map state

let get_entities (state : t) : Types.Entity.entity list =
  State.get_entities state

let move_entity (state : t) (entity_id : Types.Entity.entity_id)
    (loc : Types.Loc.t) : t =
  State.move_entity state entity_id loc

let queue_actor_action (state : t) (actor_id : Actor.actor_id)
    (action : Types.Action.t) : t =
  State.queue_actor_action state actor_id action

(* ////////////////////////////// *)
(* SPAWN HELPERS *)
(* ////////////////////////////// *)

(* Spawn player: handles entity creation, actor management, and turn scheduling *)
let spawn_player (state : t) ~pos ~direction : t =
  let player = State.get_player state in
  let player_id = player.id in
  (* 1. Spawn entity *)
  let state =
    State.spawn_player_entity state ~pos ~direction ~actor_id:player_id
  in
  (* 2. Create actor *)
  let player_actor = Actor.create ~speed:100 ~next_turn_time:0 in
  let state = State.add_actor state player_actor player_id in
  (* 3. Schedule turn *)
  let state = State.schedule_turn_now state player_id in
  state

(* Spawn creature: handles entity creation and actor management *)
let spawn_creature (state : t) ~pos ~direction ~species ~health ~glyph ~name
    ~actor_id ~description : t =
  (* NOTE: This assumes you will add a State.spawn_creature_entity function to encapsulate this logic in State *)
  let state, creature_actor_id =
    State.spawn_creature_entity state ~pos ~direction ~species ~health ~glyph
      ~name ~actor_id ~description
  in
  (* 2. Create a default actor for the creature *)
  let creature_actor = Actor.create ~speed:100 ~next_turn_time:0 in
  let state = State.add_actor state creature_actor creature_actor_id in
  (* 3. Don't schedule turn immediately, let Turn_system handle it *)
  state
