(* Export system modules *)
module Turn_system = Turn_system
module Movement_system = Movement_system
module Log_system = Log_system
module Action_handler = Action_handler
module Combat_system = Combat_system

(* Initialize all systems *)
let init () =
  (* Item and Stairs systems have been removed - their functionality is now directly in Action_handler *)
  Log_system.init ();
  Combat_system.init ()
