(* Export system modules *)
module Action_handler = Action_handler
module Combat_system = Combat_system
module Log_system = Log_system
module Movement_system = Movement_system

(* Initialize all systems *)
let init () =
  Log_system.init ();
  Combat_system.init ()
