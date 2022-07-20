import gamode/[registry, registrydef]
import winlean

const AutoGameModeEnabled = "AutoGameModeEnabled"
const AllowAutoGameMode = "AllowAutoGameMode"
when isMainModule:
  let gameBar = HKEY_CURRENT_USER.openSubKey("Software\\Microsoft\\GameBar", true)
  gameBar.setValue(AutoGameModeEnabled, 1'i32)
  gameBar.setValue(AllowAutoGameMode, 1'i32)
  gameBar.close()
  let stickyKeys = HKEY_CURRENT_USER.openSubKey("Control Panel\\Accessibility\\StickyKeys", true)
  stickyKeys.setValue("Flags", "506") # open 511 on win 11
  stickyKeys.close()