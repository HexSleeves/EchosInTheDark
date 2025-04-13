(* Main modules of game. They don't carry much state between them *)
type screen = MainMenu of Mainmenu.t | MapGen of Mapgen.t | Playing
