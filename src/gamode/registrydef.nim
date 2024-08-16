import winlean

{.deadCodeElim: on.}

const
  REG_LIB = "Advapi32"

type
  RegistryKey* = Handle

  RegistrySecurityAccess* = enum
    KEY_QUERY_VALUE = 0x0001,
    KEY_SET_VALUE = 0x0002,
    KEY_CREATE_SUB_KEY = 0x0004,
    KEY_ENUMERATE_SUB_KEYS = 0x0008,
    KEY_NOTIFY = 0x0010,
    KEY_CREATE_LINK = 0x0020,
    KEY_WOW64_64KEY = 0x0100,
    KEY_WOW64_32KEY = 0x0200,
    KEY_WRITE = 0x20006,
    KEY_READ = 0x20019,
    KEY_ALL_ACCESS = 0xf003f

  RegistryValueType* = enum
    REG_NONE = 0i32,
    REG_SZ = 1i32,
    REG_EXPAND_SZ = 2i32,
    REG_BINARY = 3i32,
    REG_DWORD = 4i32,
    REG_DWORD_BIG_ENDIAN = 5i32,
    REG_LINK = 6i32,
    REG_MULTI_SZ = 7i32,
    REG_RESOURCE_LIST = 8i32,
    REG_FULL_RESOURCE_DESCRIPTOR = 9i32,
    REG_RESOURCE_REQUIREMENTS_LIST = 10i32,
    REG_QWORD = 11i32

  ACL = object
    aclRevision: uint8
    sbz1: uint8
    aclSize: uint16
    aceCount: uint16
    sbz2: uint16

  SECURITY_INFORMATION = DWORD

  SECURITY_DESCRIPTOR = object
    revision: uint8
    sbz1: uint8
    control: uint16
    owner: pointer
    group: pointer
    sacl: ptr ACL
    dacl: ptr ACL

type
  VALENT = object
    veValuename: WideCString
    veValuelen: DWORD
    veValueptr: DWORD
    veType: DWORD

const
  HKEY_CLASSES_ROOT* = RegistryKey(0x80000000)
  HKEY_CURRENT_USER* = RegistryKey(0x80000001)
  HKEY_LOCAL_MACHINE* = RegistryKey(0x80000002)
  HKEY_USERS* = RegistryKey(0x80000003)
  HKEY_PERFORMANCE_DATA* = RegistryKey(0x80000004)
  HKEY_CURRENT_CONFIG* = RegistryKey(0x80000005)
  HKEY_DYN_DATA* {.deprecated.} = RegistryKey(0x80000006)

proc regCloseKey*(hKey: RegistryKey): int32 {.stdcall, dynlib: REG_LIB,
    importc: "RegCloseKey".}

proc regConnectRegistryW*(lpMachineName: WideCString, hKey: RegistryKey,
    phkResult: ptr RegistryKey): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegConnectRegistryW".}

proc regCopyTreeW*(hKeySrc: RegistryKey, lpSubKey: WideCString,
    hKeyDest: RegistryKey): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegCopyTreeW".}

proc regCreateKeyExW*(hKey: RegistryKey, lpSubKey: WideCString, reserved: int32,
    lpClass: WideCString, dwOptions: int32, samDesired: RegistrySecurityAccess, lpSecurityAttributes: ptr SECURITY_ATTRIBUTES,
        phkResult: ptr RegistryKey,
    lpdwDisposition: ptr DWORD): int32 {.stdcall, dynlib: REG_LIB,
        importc: "RegCreateKeyExW".}

proc regCreateKeyTransactedW*(hKey: RegistryKey, lpSubKey: WideCString,
    reserved: DWORD, lpClass: WideCString, dwOptions: DWORD, samDesired: RegistrySecurityAccess,
        lpSecurityAttributes: ptr SECURITY_ATTRIBUTES,
        phkResult: ptr RegistryKey,
    lpdwDisposition: ptr DWORD, hTransaction: Handle,
        pExtendedParameter: pointer): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegCreateKeyTransactedW".}

proc regDeleteKeyW*(hKey: RegistryKey, lpSubKey: WideCString): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegDeleteKeyW".}

proc regDeleteKeyExW*(hKey: RegistryKey, lpSubKey: WideCString,
    samDesired: RegistrySecurityAccess, reserved: DWORD): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegDeleteKeyExW".}

proc regDeleteKeyTransactedW*(hKey: RegistryKey, lpSubKey: WideCString,
    samDesired: RegistrySecurityAccess, reserved: DWORD,

hTransaction: Handle, pExtendedParameter: pointer): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegDeleteKeyTransactedW".}

proc regDeleteKeyValueW*(hKey: RegistryKey, lpSubKey: WideCString,
    lpValueName: WideCString): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegDeleteKeyValueW".}

proc regDeleteTreeW*(hKey: RegistryKey, lpSubKey: WideCString): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegDeleteTreeW".}

proc regDeleteValueW*(hKey: RegistryKey, lpValueName: WideCString): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegDeleteValueW".}

proc regDisablePredefinedCache*(): int32 {.stdcall, dynlib: REG_LIB,
    importc: "RegDisablePredefinedCache".}

proc regDisablePredefinedCacheEx*(): int32 {.stdcall, dynlib: REG_LIB,
    importc: "RegDisablePredefinedCacheEx".}

proc regDisableReflectionKey*(hBase: RegistryKey): int32 {.stdcall,
    dynlib: REG_LIB, importc: "RegDisableReflectionKey".}

proc regEnableReflectionKey*(hBase: RegistryKey): int32 {.stdcall,
    dynlib: REG_LIB, importc: "RegEnableReflectionKey".}

proc regEnumKeyExW*(hKey: RegistryKey, dwIndex: DWORD, lpName: WideCString,
    lpcName: ptr DWORD, lpReserved: ptr DWORD,

lpClass: WideCString, lpcClass: ptr DWORD,
        lpftLastWriteTime: ptr FILETIME): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegEnumKeyExW".}

proc regEnumValueW*(hKey: RegistryKey, dwIndex: DWORD, lpValueName: WideCString,
    lpcchValueName: ptr DWORD, lpReserved: ptr DWORD, lpType: ptr DWORD,
        lpData: ptr uint8, lpcbData: ptr DWORD): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegEnumValueW".}

proc regFlushKey*(hKey: RegistryKey): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegFlushKey".}

proc regGetKeySecurity*(hKey: RegistryKey,
    securityInformation: SECURITY_INFORMATION,

pSecurityDescriptor: ptr SECURITY_DESCRIPTOR,
        lpcbSecurityDescriptor: ptr DWORD): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegGetKeySecurity".}

proc regGetValueW*(hKey: RegistryKey, lpSubKey: WideCString,
    lpValue: WideCString, dwFlags: DWORD, pdwType: ptr DWORD,

pvData: pointer, pcbData: ptr DWORD): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegGetValueW".}

proc regLoadKeyW*(hKey: RegistryKey, lpSubKey: WideCString,
    lpFile: WideCString): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegLoadKeyW".}

proc regLoadMUIStringW*(hKey: RegistryKey, pszValue: WideCString,
    pszOutBuf: WideCString, cbOutBuf: DWORD,

pcbData: ptr DWORD, flags: DWORD, pszDirectory: WideCString): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegLoadMUIStringW".}

proc regNotifyChangeKeyValue*(hKey: RegistryKey, bWatchSubtree: WINBOOL,
    dwNotifyFilter: DWORD, hEvent: Handle, fAsynchronous: WINBOOL): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegNotifyChangeKeyValue".}

proc regOpenCurrentUser*(samDesired: RegistrySecurityAccess,
    phkResult: ptr RegistryKey): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegOpenCurrentUser".}

proc regOpenKeyExW*(hKey: RegistryKey, lpSubKey: WideCString, ulOptions: DWORD,
    samDesired: RegistrySecurityAccess, phkResult: ptr RegistryKey): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegOpenKeyExW".}

proc regOpenKeyTransactedW*(hKey: RegistryKey, lpSubKey: WideCString,
    ulOptions: DWORD, samDesired: RegistrySecurityAccess,

phkResult: ptr RegistryKey, hTransaction: Handle,
        pExtendedParameter: pointer): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegOpenKeyTransactedW".}

proc regOpenUserClassesRoot*(hToken: Handle, dwOptions: DWORD,
    samDesired: RegistrySecurityAccess, phkResult: ptr RegistryKey): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegOpenUserClassesRoot".}

proc regOverridePredefKey*(hKey: RegistryKey, hNewHKey: RegistryKey): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegOverridePredefKey".}

proc regQueryInfoKeyW*(hKey: RegistryKey, lpClass: WideCString,
    lpcClass: ptr DWORD, lpReserved: ptr DWORD, lpcSubKeys: ptr DWORD, lpcMaxSubKeyLen: ptr DWORD,
        lpcMaxClassLen: ptr DWORD, lpcValues: ptr DWORD,
    lpcMaxValueNameLen: ptr DWORD, lpcValueLen: ptr DWORD,
        lpcbSecurityDescription: ptr DWORD,
    lpftLastWriteTime: ptr FILETIME): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegQueryInfoKeyW".}

proc regQueryMultipleValuesW*(hKey: RegistryKey, val_list: ptr VALENT,
    num_vals: DWORD, lpValueBuf: WideCString, ldwTotsize: ptr DWORD): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegQueryMultipleValuesW".}

proc regQueryReflectionKey*(hBase: RegistryKey,
    bIsReflectionDisabled: ptr WINBOOL): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegQueryReflectionKey".}

proc regQueryValueExW*(hKey: RegistryKey, lpValueName: WideCString,
    lpReserved: ptr DWORD, lpType: ptr RegistryValueType, lpData: ptr int8,
        lpcbData: ptr DWORD): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegQueryValueExW".}

proc regReplaceKeyW*(hKey: RegistryKey, lpSubKey: WideCString,
    lpNewFile: WideCString, lpOldFile: WideCString): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegReplaceKeyW".}

proc regRestoreKeyW*(hKey: RegistryKey, lpFile: WideCString,
    dwFlags: DWORD): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegRestoreKeyW".}

proc regSaveKeyW*(hKey: RegistryKey, lpFile: WideCString,
    lpSecurityAttributes: ptr SECURITY_ATTRIBUTES): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegSaveKeyW".}

proc regSaveKeyExW*(hKey: RegistryKey, lpFile: WideCString,
    lpSecurityAttributes: ptr SECURITY_ATTRIBUTES, flags: DWORD): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegSaveKeyExW".}

proc regSetKeyValueW*(hKey: RegistryKey, lpSubKey: WideCString,
    lpValueName: WideCString, dwType: RegistryValueType,

lpData: pointer, cbData: DWORD): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegSetKeyValueW".}

proc regSetKeySecurity*(hKey: RegistryKey,
    securityInformation: SECURITY_INFORMATION,

pSecurityDescriptor: ptr SECURITY_DESCRIPTOR): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegSetKeySecurity".}

proc regSetValueExW*(hKey: RegistryKey, lpValueName: WideCString,
    reserved: DWORD, dwType: RegistryValueType,

lpData: ptr int8, cbData: DWORD): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegSetValueExW".}

proc regUnLoadKeyW*(hKey: RegistryKey, lpSubKey: WideCString): int32
    {.stdcall, dynlib: REG_LIB, importc: "RegUnLoadKeyW".}
