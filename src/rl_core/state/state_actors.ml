open Base
open Actors

let get_actor (state : State_types.t) (actor_id : Actor.actor_id) :
    Actor.t option =
  Actor_manager.get actor_id state.actor_manager

let add_actor (actor : Actor.t) (actor_id : Actor.actor_id)
    (state : State_types.t) : State_types.t =
  Actor_manager.add actor_id actor state.actor_manager |> fun am ->
  { state with actor_manager = am }

let remove_actor (actor_id : Actor.actor_id) (state : State_types.t) :
    State_types.t =
  {
    state with
    actor_manager = Actor_manager.remove actor_id state.actor_manager;
  }

let update_actor (state : State_types.t) (actor_id : Actor.actor_id)
    (f : Actor.t -> Actor.t) : State_types.t =
  Actor_manager.update actor_id f state.actor_manager |> fun am ->
  { state with actor_manager = am }

let queue_actor_action (state : State_types.t) (actor_id : Actor.actor_id)
    (action : Rl_types.Action.t) : State_types.t =
  update_actor state actor_id (fun actor -> Actor.queue_action actor action)
