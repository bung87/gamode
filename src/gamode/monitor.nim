import winim/inc/winuser
import winim/inc/wingdi
import winim/inc/windef

proc getMaxRate*():int =  
  var settings: DEVMODEW
  var i = 0
  var rate:int = 0
  while EnumDisplaySettings(nil, DWORD(i), settings.addr ) == TRUE:
    inc i
    if int(settings.dmDisplayFrequency) > rate:
      rate = int(settings.dmDisplayFrequency)

  return rate

proc changeRefreshRate*(rate:int): int = 
  # DISP_CHANGE_SUCCESSFUL = 0
  var cur:DEVMODEW
  EnumDisplaySettings(nil, ENUM_CURRENT_SETTINGS, cur.addr)
  var dm = cur
  dm.dmFields = DM_DISPLAYFREQUENCY
  dm.dmDisplayFrequency = DWORD(rate)
  var iRet = ChangeDisplaySettings(dm.addr, CDS_TEST)
  if (iRet == DISP_CHANGE_FAILED):
    return iRet
  else: 
    iRet = ChangeDisplaySettings( dm.addr, CDS_UPDATEREGISTRY); 
  return iRet

when isMainModule:
    let maxRate = getMaxRate()
    echo maxRate
    echo changeRefreshRate(maxRate)