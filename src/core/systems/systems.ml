(* Export system modules *)
module Combat_system = Combat_system
module Log_system = Log_system

(* Initialize all systems *)
let init () =
  Log_system.init ();
  Combat_system.init ()
