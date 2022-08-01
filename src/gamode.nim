import gamode/[common, registry, registrydef]
import winlean
import winim/inc/winuser
import winim/inc/windef
import strutils
import std/sugar

const AutoGameModeEnabled = "AutoGameModeEnabled"
const AllowAutoGameMode = "AllowAutoGameMode"
const layoutEN = "United Kingdom"
const layoutUS = "US"

proc getLayoutName(kbdLayout: HKL): string =
  let kbdLayoutHex = toHex(kbdLayout, 8)
  let lng = kbdLayoutHex[4..7]
  let lngReg = align(lng, 8, '0')
  let layouts = HKEY_LOCAL_MACHINE.openSubKey(
      "SYSTEM\\CurrentControlSet\\Control\\Keyboard Layouts\\" & lngReg)
  result = layouts.getValue("Layout Text", "")


when isMainModule:
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
    let kbdLayout = GetKeyboardLayout(0)
    var lst: array[100, HKL]
    let count = GetKeyboardLayoutList(100, lst[0].addr)
    let layouts = collect(newSeq):
      for i in countup(0, count - 1):
        getLayoutName(lst[i])
    # if layoutEN notin layouts and layoutUS notin layouts:
    let k = LoadKeyboardLayout("US", 8)
    # This function only affects the layout for the current process or thread.
    # let s = ActivateKeyboardLayout(k, 8)
    # echo s
  let winKeys = HKEY_CURRENT_USER.openSubKey(
      "Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer", true)
  # let noWinKeys = winKeys.createSubKey("NoWinKeys", true)
  winKeys.setValue("NoWinKeys", 1'i32)
  winKeys.close()

