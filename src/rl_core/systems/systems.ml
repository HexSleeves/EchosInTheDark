(* Export system modules *)
module Item_system = Item_system
module Turn_system = Turn_system
module Movement_system = Movement_system
module Log_system = Log_system
module Action_handler = Action_handler
module Combat_system = Combat_system

(* Initialize all systems *)
let init () = Item_system.init ()
