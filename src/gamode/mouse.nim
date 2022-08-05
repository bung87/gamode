import winim/inc/windef
import winim/inc/winuser

# https://stackoverflow.com/questions/3902477/how-to-configure-mouse-enhance-pointer-precision-programmatically
# https://stackoverflow.com/questions/16813653/mouse-speed-not-changing-by-using-spi-setmousespeed

proc setMouseAcceleration*(mouseAccel: bool): bool =
  var mouseParams: array[3, int32]
  if SystemParametersInfo(SPI_GETMOUSE, 0, mouseParams.addr, 0) == FALSE:
    return false
  mouseParams[2] = BOOL(mouseAccel)
  if SystemParametersInfo(SPI_SETMOUSE, 0, mouseParams.addr, SPIF_UPDATEINIFILE) == FALSE:
    return false
  return true

when isMainModule:
  echo setMouseAcceleration(false)
