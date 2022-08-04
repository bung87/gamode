import gamode/[common, registry, registrydef, priv, srv]
import winlean
import winim/inc/winuser
import winim/inc/windef
import strutils
import std/sugar

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

when isMainModule:
  adjustPrivilege()
  let gameBar = HKEY_CURRENT_USER.openSubKey("Software\\Microsoft\\GameBar", true)
  gameBar.setValue(AutoGameModeEnabled, 1'i32)
  gameBar.setValue(AllowAutoGameMode, 1'i32)
  gameBar.close()
  let stickyKeys = HKEY_CURRENT_USER.openSubKey(
      "Control Panel\\Accessibility\\StickyKeys", true)
  stickyKeys.setValue("Flags", "506") # open 511 on win 11
  stickyKeys.close()
  let dbcsEnabled = GetSystemMetrics(SM_DBCSENABLED)
  if dbcsEnabled != 0:
    echo LoadKeyboardLayout(layoutUS, KLF_ACTIVATE)
    # let preload = HKEY_USERS.openSubKey(".DEFAULT\\Keyboard Layout\\Preload", true)
    # preload.setValue("1", layoutUS)
    # preload.close
    # for k in preload.getSubKeyNames():
    #   echo k
    # var lst: array[100, HKL]
    # let count = GetKeyboardLayoutList(100, lst[0].addr)
    # var usIndex = -1
    # let layouts = collect(newSeq):
    #   for i in countup(0, count - 1):
    #     let name = getLayoutName(lst[i])
    #     if name == layoutUS:
    #       usIndex = i
    #     name
    # var kbdLayout: HKL
    # if layoutUS notin layouts:
    #   kbdLayout = LoadKeyboardLayout(layoutUS, KLF_ACTIVATE)
    # else:
    #   if usIndex != -1:
    #     kbdLayout = lst[usIndex]
    #     kbdLayout = LoadKeyboardLayout(layoutUS, KLF_ACTIVATE)
    #     echo kbdLayout
    #     echo toHex(kbdLayout, 8)
    # let s = ActivateKeyboardLayout(kbdLayout, KLF_SETFORPROCESS)

  let winKeys = HKEY_CURRENT_USER.openSubKey(
      "Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer", true)
  let noWinKeys = winKeys.createSubKey("NoWinKeys", true)
  winKeys.setValue("NoWinKeys", 1'i32)
  winKeys.close()
  stopService("wuauserv")


