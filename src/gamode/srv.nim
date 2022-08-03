import common
import winim/inc/winsvc
import winim/inc/winbase
import winim/inc/winerror
import std/[strutils]
import priv

# https://docs.microsoft.com/en-us/windows/win32/services/stopping-a-service
# https://docs.microsoft.com/en-us/windows/win32/api/winsvc/nf-winsvc-controlservice

proc stopDependentServices(schSCManager: SC_HANDLE;
    schService: SC_HANDLE): bool =
  var dwBytesNeeded: DWORD
  var dwCount: DWORD

  var lpDependencies: LPENUM_SERVICE_STATUS = nil
  var ess: ENUM_SERVICE_STATUS
  var hDepService: SC_HANDLE
  var ssp: SERVICE_STATUS_PROCESS

  var dwStartTime: DWORD = GetTickCount()
  var dwTimeout: DWORD = 30000 # 30-second time-out

  # Pass a zero-length buffer to get the required buffer size.
  if EnumDependentServices(schService, SERVICE_ACTIVE,
        lpDependencies, 0, dwBytesNeeded.addr, dwCount.addr) == TRUE:
    # If the Enum call succeeds, then there are no dependent
    # services, so do nothing.
    echo "no deps"
    return true
  else:
    if GetLastError() != ERROR_MORE_DATA:
      echo "EnumDependentServices error"
      return false # Unexpected error

      # Allocate a buffer for the dependencies.
    lpDependencies = cast[LPENUM_SERVICE_STATUS] (HeapAlloc(
        GetProcessHeap(), HEAP_ZERO_MEMORY, dwBytesNeeded))

    if lpDependencies == nil:
      return false

    try:
      # Enumerate the dependencies.
      if not EnumDependentServices(schService, SERVICE_ACTIVE,
          lpDependencies, dwBytesNeeded, dwBytesNeeded.addr,
          dwCount.addr) == TRUE:
        return false

      for i in 0 ..< dwCount:
        ess = cast[ENUM_SERVICE_STATUS](cast[int](ess) * (cast[int](
            lpDependencies[]) + int(i)))
        # Open the service.
        hDepService = OpenService(schSCManager,
            ess.lpServiceName,
            SERVICE_STOP or SERVICE_QUERY_STATUS);

        if hDepService != 0:
          return false

        try:
          # Send a stop code.
          if not ControlService(hDepService,
                  SERVICE_CONTROL_STOP,
                  cast[LPSERVICE_STATUS](ssp.addr)) == TRUE:
            return false

          # Wait for the service to stop.
          while (ssp.dwCurrentState != SERVICE_STOPPED):
            Sleep(ssp.dwWaitHint);
            if not QueryServiceStatusEx(
                    hDepService,
                    SC_STATUS_PROCESS_INFO,
                    cast[LPBYTE](ssp.addr),
                    DWORD(sizeof(SERVICE_STATUS_PROCESS)),
                    dwBytesNeeded.addr) == TRUE:
              return false

            if (ssp.dwCurrentState == SERVICE_STOPPED):
              break

            if (GetTickCount() - dwStartTime > dwTimeout):
              return false
        finally:
          # Always release the service handle.
          CloseServiceHandle(hDepService)
    finally:
      # Always free the enumeration buffer.
      HeapFree(GetProcessHeap(), 0, lpDependencies)

  return true

proc stopService*(szSvcName: string) =
  var ssp: SERVICE_STATUS_PROCESS
  var dwStartTime = GetTickCount()
  var dwBytesNeeded: DWORD
  var dwTimeout: DWORD = 30000 # 30-second time-out
  var dwWaitTime: DWORD

  # Get a handle to the SCM database.
  # var szSvcName: LPCWSTR
  let schSCManager = OpenSCManager(
      nil,                 # local computer
    nil,                   # ServicesActive database
    SC_MANAGER_ALL_ACCESS) # full access rights
  if schSCManager == 0:
    echo "OpenSCManager failed $#" % [$GetLastError()]
    # ERROR_ACCESS_DENIED
    return
  let schService = OpenService(
      schSCManager, # SCM database
    szSvcName,      # name of service
    SERVICE_STOP or
    SERVICE_QUERY_STATUS or
    SERVICE_ENUMERATE_DEPENDENTS)
  if schService == 0:
    echo "OpenService failed $#" % [$GetLastError()]
    CloseServiceHandle(schSCManager);
    return
  proc cleanUp() =
    CloseServiceHandle(schService)
    CloseServiceHandle(schSCManager)

  #  Make sure the service is not already stopped.
  if not QueryServiceStatusEx(
      schService,
      SC_STATUS_PROCESS_INFO,
      cast[LPBYTE](ssp.addr),
      (DWORD)sizeof(SERVICE_STATUS_PROCESS),
      dwBytesNeeded.addr) == TRUE:
      echo "QueryServiceStatusEx failed $#" % [$GetLastError()]
      cleanUp()
      return
  if ssp.dwCurrentState == SERVICE_STOPPED:
    cleanUp()
    return

  # If a stop is pending, wait for it.

  while ssp.dwCurrentState == SERVICE_STOP_PENDING:

    # Do not wait longer than the wait hint. A good interval is
    # one-tenth of the wait hint but not less than 1 second
    # and not more than 10 seconds.

    dwWaitTime = ssp.dwWaitHint div 10

    if dwWaitTime < 1000:
      dwWaitTime = 1000
    elif dwWaitTime > 10000:
      dwWaitTime = 10000

    Sleep(dwWaitTime)
    if not QueryServiceStatusEx(
        schService,
        SC_STATUS_PROCESS_INFO,
        cast[LPBYTE](ssp.addr),
        (DWORD)sizeof(SERVICE_STATUS_PROCESS),
        dwBytesNeeded.addr) == TRUE:
    # QueryServiceStatusEx failed
      cleanUp()
      return

    if ssp.dwCurrentState == SERVICE_STOPPED:
    # Service stopped successfully.
      cleanUp()
      return

    if GetTickCount() - dwStartTime > dwTimeout:
    # Service stop timed out.
      cleanUp()
      return

  # If the service is running, dependencies must be stopped first.
  discard stopDependentServices(schSCManager, schService)

  # Send a stop code to the service.
  echo "dwCurrentState before control", $ssp.dwCurrentState
  if not ControlService(
          schService,
          SERVICE_CONTROL_STOP,
          cast[LPSERVICE_STATUS](ssp.addr)) == TRUE:
    echo "ControlService  failed $#" % [$GetLastError()]
    cleanUp()
    return
  # Wait for the service to stop.

  while ssp.dwCurrentState != SERVICE_STOPPED:
    Sleep(ssp.dwWaitHint)
    if not QueryServiceStatusEx(
            schService,
            SC_STATUS_PROCESS_INFO,
            cast[LPBYTE](ssp.addr),
            (DWORD)sizeof(SERVICE_STATUS_PROCESS),
            dwBytesNeeded.addr) == TRUE:

      cleanUp()
      return
    # echo "dwCurrentState after control", $ssp.dwCurrentState
    if ssp.dwCurrentState == SERVICE_STOPPED:
      break

    if GetTickCount() - dwStartTime > dwTimeout:
      # Wait timed out
      cleanUp()
      return

  # service stopped successfully

when isMainModule:
  adjustPrivilege()
  # powershell: Get-Service | Where-Object {$_.Name -like "*wuauserv*"}
  stopService("wuauserv")
