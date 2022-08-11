import std/logging
import appdirs
import os
export logging

let logDir = userLogs("gamode", "bung", "0.1.0")
var loggerFile = newFileLogger( logDir / "info.log")
addHandler(loggerFile)

proc logOsError*(): OSErrorCode {.inline,discardable.} = 
  let err = osLastError() 
  error( osErrorMsg(err))
  return err