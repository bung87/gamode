import std/logging
import appdirs
import os
export logging

let logDir = userLogs("gamode", "bung", "0.1.0")
createDir(logDir)
# var logFile = open(logDir / "info.log", fmWrite)
var logPath* = logDir / "info.log"
var loggerFile = newFileLogger( logPath)
addHandler(loggerFile)

proc logOsError*(): OSErrorCode {.inline,discardable.} = 
  let err = osLastError() 
  error( osErrorMsg(err))
  return err