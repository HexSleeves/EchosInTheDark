open Rl2023
open Game

let () = Cli.parse |> Game.setup "Rl2023 Ocaml Style" |> Menu.main_menu
