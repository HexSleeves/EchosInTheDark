type t = { level : Logs.level }

let configure ~level =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some level)
