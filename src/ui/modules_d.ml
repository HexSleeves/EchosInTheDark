(* Main modules of game. They don't carry much state between them *)
type t = MainMenu of Mainmenu.t | MapGen | Playing
