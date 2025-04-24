open Base
module Tilemap = Dungeon.Tilemap
module Actor = Actor_manager.Actor
module Entity = Types.Entity

type t = State.t

let make ~debug ~w ~h ~seed : t = State.make ~debug ~w ~h ~seed

(* Mode *)
let get_mode (state : t) : Types.CtrlMode.t = State.get_mode state

let set_mode (mode : Types.CtrlMode.t) (state : t) : t =
  State.set_mode mode state

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

(* ////////////////////////////// *)
(* SPAWN HELPERS *)
(* ////////////////////////////// *)

(* Spawn player: handles entity creation, actor management, and turn scheduling *)
let spawn_player (state : t) ~pos ~direction : t =
  let player_id = State.get_player_id state in
  let player_actor = Actor.create ~speed:100 ~next_turn_time:0 in

  state
  |> State.spawn_player_entity ~pos ~direction
  |> State.add_actor player_actor player_id
  |> State.schedule_turn_now player_id

(* Spawn creature: handles entity creation and actor management *)
let spawn_creature (state : t) ~pos ~direction ~species ~health ~glyph ~name
    ~description : t =
  (* NOTE: This assumes you will add a state.spawn_creature_entity function to encapsulate this logic in state *)
  let state, creature_actor_id =
    State.spawn_creature_entity state ~pos ~direction ~species ~health ~glyph
      ~name ~description
  in
  (* 2. Create a default actor for the creature *)
  let creature_actor = Actor.create ~speed:100 ~next_turn_time:0 in
  let state = State.add_actor creature_actor creature_actor_id state in
  (* 3. Don't schedule turn immediately, let Turn_system handle it *)
  state
