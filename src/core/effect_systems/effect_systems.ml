(* Effect Systems Integration

   This module provides a unified interface for all game systems using effect handlers.
   It composes the individual effect handler modules to create a layered approach
   where each system focuses on its specific domain.

   SIMPLIFIED: The action handler now directly implements simple actions without
   going through the event bus, reducing indirection and complexity. Only actions
   that need to notify multiple systems (like combat) still use the event bus.
*)

open Base

(* Import the individual effect handler modules *)
module Turn_effects = Effect_turn_system
module Action_effects = Effect_action_handler
module State_effects = Effect_state

(* ========== Layered Handler Implementation ========== *)

(* Run a computation with all system handlers in a layered approach *)
let with_all_handlers (state : State.t) (f : unit -> 'a) : 'a * State.t =
  (* Only the final state is returned *)
  let first_result, final_state =
    State_effects.with_state_handler state (fun () ->
        Action_effects.with_action_handler state (fun () ->
            Turn_effects.with_turn_queue state f))
    |> fun (result_after, final_state) ->
    (result_after |> fst |> fst, final_state)
  in

  (first_result, final_state)

(* Run a function with all system handlers and return the updated state *)
let run_with_all_handlers (state : State.t) (f : unit -> 'a) : State.t =
  let _, final_state = with_all_handlers state f in
  final_state

(* Process turns using the layered effect handler approach *)
let process_turns (state : State.t) : State.t =
  (* Use the Turn module's process_turns_hybrid function with our layered handlers *)
  run_with_all_handlers state (fun () ->
      (* This will use the Turn module's implementation but with all effect handlers available *)
      Turn_effects.process_turns_hybrid state)
