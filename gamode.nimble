# Package

version       = "0.1.0"
author        = "Anonymous"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["gamode"]
installExt = @["nim", "js","css","html"]

# Dependencies

requires "nim >= 1.6.6"
requires "winim"
requires "fusion"
# requires "webgui"
