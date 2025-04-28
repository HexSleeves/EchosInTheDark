val err : 'a Logs.log
val warn : 'a Logs.log
val info : 'a Logs.log
val debug : 'a Logs.log
val make_logger : string -> (module Logs.LOG)
