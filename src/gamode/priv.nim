
import winim/inc/winbase
import winim/inc/windef
import common

const TOKEN_ADJUST_PRIVILEGES = 0x00000020

proc adjustPrivilege*() =
  var hToken: windef.HANDLE
  if (OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, hToken.addr)) == TRUE:
    var tp: TOKEN_PRIVILEGES
    tp.PrivilegeCount = 1
    tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED
    if (LookupPrivilegeValue(nil, SE_DEBUG_NAME, tp.Privileges[0].Luid.addr)) == TRUE:
      AdjustTokenPrivileges(hToken, FALSE, tp.addr, (int32)sizeof(tp), nil, nil)
    CloseHandle(hToken)
