import gamode/[common, registry, registrydef, priv, srv, mouse, power, webview]
import winlean
import winim/inc/winuser
import winim/inc/windef
import strutils
import std/sugar
import os

const AutoGameModeEnabled = "AutoGameModeEnabled"
const AllowAutoGameMode = "AllowAutoGameMode"
# const layoutEN = "United Kingdom"
const layoutUS = "00000409"

proc getLayoutName(kbdLayout: HKL): string =
  # eg "US"
  let kbdLayoutHex = toHex(kbdLayout, 8)
  let lng = kbdLayoutHex[4..7]
  result = align(lng, 8, '0')

# proc getLayoutName(kbdLayout: HKL): string =
#   # eg "US"
#   let kbdLayoutHex = toHex(kbdLayout, 8)
#   let lng = kbdLayoutHex[4..7]
#   let lngReg = align(lng, 8, '0')
#   let layouts = HKEY_LOCAL_MACHINE.openSubKey(
#       "SYSTEM\\CurrentControlSet\\Control\\Keyboard Layouts\\" & lngReg)
#   result = layouts.getValue("Layout Text", "")

proc gameModeOn() =
  # https://www.guru3d.com/news-story/windows-10-game-mode-can-impact-fps-negatively-with-stutters-and-freezes.html
  let gameBar = HKEY_CURRENT_USER.openSubKey("Software\\Microsoft\\GameBar", true)
  gameBar.setValue(AutoGameModeEnabled, 1'i32)
  gameBar.setValue(AllowAutoGameMode, 1'i32)
  gameBar.close()

proc gameModeOff() =
  # https://www.guru3d.com/news-story/windows-10-game-mode-can-impact-fps-negatively-with-stutters-and-freezes.html
  let gameBar = HKEY_CURRENT_USER.openSubKey("Software\\Microsoft\\GameBar", true)
  gameBar.setValue(AutoGameModeEnabled, 0'i32)
  gameBar.setValue(AllowAutoGameMode, 0'i32)
  gameBar.close()

proc disableStickyKeysOn() =
  let stickyKeys = HKEY_CURRENT_USER.openSubKey(
      "Control Panel\\Accessibility\\StickyKeys", true)
  stickyKeys.setValue("Flags", "506") # open 511 on win 11
  stickyKeys.close()

proc disableStickyKeysOff() =
  let stickyKeys = HKEY_CURRENT_USER.openSubKey(
      "Control Panel\\Accessibility\\StickyKeys", true)
  stickyKeys.setValue("Flags", "511") # open 511 on win 11
  stickyKeys.close()

proc usLayoutOn() =
  let dbcsEnabled = GetSystemMetrics(SM_DBCSENABLED)
  if dbcsEnabled != 0:
    var lst: array[100, HKL]
    let count = GetKeyboardLayoutList(100, lst[0].addr)
    var usIndex = -1
    let layouts = collect(newSeq):
      for i in countup(0, count - 1):
        let name = getLayoutName(lst[i])
        if name == layoutUS:
          usIndex = i
        name
    var kbdLayout: HKL
    if layoutUS notin layouts:
      kbdLayout = LoadKeyboardLayout(layoutUS, KLF_ACTIVATE)
    else:
      if usIndex != -1:
        kbdLayout = lst[usIndex]
        kbdLayout = LoadKeyboardLayout(layoutUS, KLF_ACTIVATE)
    # let s = ActivateKeyboardLayout(kbdLayout, KLF_SETFORPROCESS)
    # var hWnd = GetForegroundWindow()
    # PostMessage(hWnd, WM_INPUTLANGCHANGEREQUEST, INPUTLANGCHANGE_FORWARD, HKL_NEXT)

proc noWinKeysOn() =
  let winKeys = HKEY_CURRENT_USER.openSubKey(
      "Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer", true)
  let noWinKeys = winKeys.createSubKey("NoWinKeys", true)
  winKeys.setValue("NoWinKeys", 1'i32)
  winKeys.close()

proc noWinKeysOff() = 
  let winKeys = HKEY_CURRENT_USER.openSubKey(
      "Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer", true)
  # winKeys.deleteSubKey("NoWinKeys")
  winKeys.setValue("NoWinKeys", 0'i32)
  winKeys.close()

proc stopWuau() =
  # disable windows auto update
  stopService("wuauserv")

proc disableMouseAccelerationOn() =
  # disable mouse enhance pointer precision
  discard setMouseAcceleration(false)

proc maximumPerformanceOn() =
  # maximum performance power plan
  var preserve: HKEY
  PowerSetActiveScheme(preserve, MaximumPerformance.unsafeAddr)

proc startOptimization() =
  adjustPrivilege()
  gameModeOn()
  usLayoutOn()
  disableStickyKeysOn()
  noWinKeysOn()
  stopWuau()
  disableMouseAccelerationOn()
  maximumPerformanceOn()

proc restoreBack() =
  adjustPrivilege()
  gameModeOff()
  ActivateKeyboardLayout(0,KLF_SETFORPROCESS)
  noWinKeysOff()
  disableStickyKeysOff()
  var preserve: HKEY
  PowerSetActiveScheme(preserve, Balanced.unsafeAddr)

when isMainModule:

  let app = newWebView(currentSourcePath().splitPath.head / "assets" / "index.html", title="gamode", width=800, height=480)
  app.bindProcs("api"):
    proc start() = startOptimization()
    proc restore() = restoreBack()
  app.run()
  app.exit()
  
