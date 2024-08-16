# Package

version       = "0.2.0"
author        = "bung87"
description   = "windows optimization tool for game"
license       = "MIT"
srcDir        = "src"
bin           = @["gamode"]

installExt = @["nim", "js","css","html"]

# Dependencies

requires "nim >= 1.6.6"
requires "winim"
requires "crowngui >= 0.2.17"
when NimMajor >= 2:
  requires "htmlparser"