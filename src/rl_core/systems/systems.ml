(* Export system modules *)
module Item_system = Item_system
module Packed_system = Packed_system
module Performance_profiler = Performance_profiler
module Turn_system = Turn_system
module Movement_system = Movement_system
module Log_system = Log_system
module Action_handler = Action_handler
module Combat_system = Combat_system
module Position_profiler = Position_profiler

(* Initialize all systems *)
let init () =
  Item_system.init ();
  Packed_system.init ();
  Performance_profiler.init ();
  Position_profiler.init ()

(* Update all systems *)
let update (state : State_types.t) : State_types.t =
  (* Generate performance report periodically *)
  Performance_profiler.generate_report ();

  (* Update using the packed system for performance *)
  let state = Packed_system.update state in
  state
