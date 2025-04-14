type t = { level : Logs.level }

let configure ~level =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some level)

let info str = Logs.info (fun m -> m "%s" str)
let debug str = Logs.debug (fun m -> m "%s" str)
let warn str = Logs.warn (fun m -> m "%s" str)
let error str = Logs.err (fun m -> m "%s" str)
