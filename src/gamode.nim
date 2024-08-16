import gamode/[common, registry, registrydef, priv, srv, mouse, power, bundler, monitor,logger]
import winim/inc/winuser
import winim/inc/windef
import std/[os,sugar,strutils,winlean]

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
  noWinKeys.close
  winKeys.close()

proc noWinKeysOff() = 
  let winKeys = HKEY_CURRENT_USER.openSubKey(
      "Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer", true)
  # winKeys.deleteSubKey("NoWinKeys")
  winKeys.setValue("NoWinKeys", 0'i32)
  winKeys.close()

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
  # disable windows auto update
  stopService("wuauserv")
  # SysMain is a service that preloads the apps you frequently use to the RAM, thus boosting the system performance.
  stopService("SysMain")
  stopService("WSearch")
  disableMouseAccelerationOn()
  maximumPerformanceOn()
  discard changeRefreshRate(getMaxRate())

proc restoreBack() =
  adjustPrivilege()
  gameModeOff()
  ActivateKeyboardLayout(0,KLF_SETFORPROCESS)
  noWinKeysOff()
  disableStickyKeysOff()
  startService("SysMain")
  startService("WSearch")
  var preserve: HKEY
  PowerSetActiveScheme(preserve, Balanced.unsafeAddr)
  discard changeRefreshRate(60)




when isMainModule:
  import os, strutils
  import gamode/webview
  # import crowngui
  
  # import std/threadpool
  # {.experimental: "parallel".}
  const htmlPath = currentSourcePath().splitPath.head / "assets" / "index.html"
  const pDir = htmlPath.parentDir
  const prefix = "<!DOCTYPE html>"
  const html = bundleAssets(htmlPath, pDir)

  # const coded = getDataUri(prefix & html, "text/html")
  # let app = newApplication(prefix & html)

  let app = newWebView(prefix & html, title="gamode", width=800, height=480)
  # let ins =  GetModuleHandle(nil)
  # let hWindowIcon = LoadIconW(ins, MAKEINTRESOURCE(0))
  # app.setIcon(hWindowIcon)
  # let menu = CreateMenu()
  # var item = MENUITEMINFOA()
  # item.cbSize = sizeof(MENUITEMINFOA).UINT
  # item.fMask = MIIM_STRING
  # item.fType = MFT_STRING
  # var t = "view log"
  # item.dwTypeData = t[0].addr
  # InsertMenuItemA(menu,3001,FALSE,item.addr)
  # app.setMenu(menu)
  var chan: Channel[string]
  var worker: Thread[void]
  
  proc work() = 
    while true:
      let tried = chan.tryRecv()
      if tried.dataAvailable:
        if tried.msg == "start":
          startOptimization()
        elif tried.msg == "restore":
          restoreBack()

  createThread(worker, work)
  chan.open
  
  app.bindProcs("api"):
    proc start() = chan.send("start")#startOptimization()
    proc restore() = chan.send("restore")#restoreBack()
    proc viewLog() = discard shellExecuteW(0, newWideCString(""), newWideCString(logPath), NULL, NULL, winlean.SW_SHOWNORMAL)
  app.run()
  
  worker.joinThread()
  chan.close()
  app.exit()
  # app.destroy()
  
