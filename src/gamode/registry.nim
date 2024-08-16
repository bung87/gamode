import registrydef, strutils, typetraits, winlean

type
  RegistryError* = object of CatchableError

const
  FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x100
  FORMAT_MESSAGE_IGNORE_INSERTS = 0x200
  FORMAT_MESSAGE_FROM_SYSTEM = 0x1000

  ERROR_SUCCESS = 0
  ERROR_FILE_NOT_FOUND = 2
  USER_LANGUAGE = 0x0400

  MAX_KEY_LEN = 255
  MAX_VALUE_LEN = 16383

proc getErrorMessage(code: int32): string {.raises: [].} =
  var msgbuf: pointer
  discard formatMessageW(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ALLOCATE_BUFFER or
    FORMAT_MESSAGE_IGNORE_INSERTS, nil, code, USER_LANGUAGE, msgbuf.addr, 0, nil)
  result = $cast[WideCString](msgbuf)
  localFree(msgbuf)

proc raiseError(code: int32) {.inline, raises: [RegistryError].} =
  raise newException(RegistryError, $code & ": " & getErrorMessage(code))

proc close*(this: RegistryKey) {.raises: [RegistryError].} =
  let code = regCloseKey(this)
  if unlikely(code != ERROR_SUCCESS):
    raiseError(code)

proc createSubKey*(this: RegistryKey, subkey: string, writable: bool): RegistryKey {.raises: [RegistryError].} =
  var createdHandle: RegistryKey
  let code = regCreateKeyExW(this, newWideCString(subkey), 0, nil, 0,
    if writable: KEY_ALL_ACCESS else: KEY_READ, nil, createdHandle.addr, nil)
  if unlikely(code != ERROR_SUCCESS):
    raiseError(code)
  return createdHandle

proc createSubKey*(this: RegistryKey, subkey: string): RegistryKey {.raises: [RegistryError].} =
  return this.createSubKey(subkey, true)

proc deleteSubKey*(this: RegistryKey, subkey: string, raiseOnMissingSubKey: bool) {.raises: [RegistryError].} =
  let code = regDeleteKeyW(this, newWideCString(subkey))
  if unlikely(code != ERROR_SUCCESS) and (raiseOnMissingSubKey or code != ERROR_FILE_NOT_FOUND):
    raiseError(code)

proc deleteSubKey*(this: RegistryKey, subkey: string) {.raises: [RegistryError].} =
  this.deleteSubKey(subkey, true)

proc deleteSubKeyTree*(this: RegistryKey, subkey: string, raiseOnMissingSubKey: bool) {.raises: [RegistryError].} =
  let code = regDeleteTreeW(this, newWideCString(subkey))
  if unlikely(code != ERROR_SUCCESS) and (raiseOnMissingSubKey or code != ERROR_FILE_NOT_FOUND):
    raiseError(code)

proc deleteSubKeyTree*(this: RegistryKey, subkey: string) {.raises: [RegistryError].} =
  this.deleteSubKeyTree(subkey, true)

proc deleteValue*(this: RegistryKey, name: string, raiseOnMissingValue: bool) {.raises: [RegistryError].} =
  let code = regDeleteKeyValueW(this, nil, newWideCString(name))
  if unlikely(code != ERROR_SUCCESS) and (raiseOnMissingValue or code != ERROR_FILE_NOT_FOUND):
    raiseError(code)

proc deleteValue*(this: RegistryKey, name: string) {.raises: [RegistryError].} =
  this.deleteValue(name, true)

proc flush*(this: RegistryKey) {.raises: [RegistryError].} =
  let code = regFlushKey(this)
  if unlikely(code != ERROR_SUCCESS):
    raiseError(code)

iterator getSubKeyNames*(this: RegistryKey): string {.raises: [RegistryError].} =
  var keyCount: int32
  let code = regQueryInfoKeyW(this, nil, nil, nil, keyCount.addr, nil, nil, nil, nil, nil, nil, nil)
  if unlikely(code != ERROR_SUCCESS):
    raiseError(code)

  var nameBuffer = newWideCString((MAX_KEY_LEN + 1) * sizeof(Utf16Char))

  for i in 0..<keyCount:
    var nameLen: int32 = MAX_KEY_LEN
    let code = regEnumKeyExW(this, int32(i), nameBuffer, nameLen.addr, nil, nil, nil, nil)
    if unlikely(code != ERROR_SUCCESS):
      raiseError(code)

    nameBuffer[nameLen] = Utf16Char(0)
    yield $nameBuffer

proc tryGetValue*[T](this: RegistryKey, name: string, value: var T): bool {.raises: [RegistryError, ValueError].} =
  var kind: RegistryValueType
  var size: int32 = 0
  let code = regQueryValueExW(this, newWideCString(name), nil, kind.addr, nil, size.addr)
  if code == ERROR_FILE_NOT_FOUND:
    return false
  if unlikely(code != ERROR_SUCCESS):
    raiseError(code)

  case kind:
  of REG_DWORD:
    var tmp: int32
    size = int32(sizeof(tmp))
    let code = regGetValueW(this, nil, newWideCString(name), 0x0000ffff, nil, cast[pointer](tmp.addr), size.addr)
    if code == ERROR_FILE_NOT_FOUND:
      return false
    if unlikely(code != ERROR_SUCCESS):
      raiseError(code)

    when T is SomeNumber:
      value = T(tmp)
      return true
    elif T is string:
      value = $tmp
      return true
    else:
      {.fatal: "The type " & T.name & " is not supported yet.".}
  of REG_QWORD:
    var tmp: int64
    size = int32(sizeof(tmp))
    let code = regGetValueW(this, nil, newWideCString(name), 0x0000ffff, nil, cast[pointer](tmp.addr), size.addr)
    if code == ERROR_FILE_NOT_FOUND:
      return false
    if unlikely(code != ERROR_SUCCESS):
      raiseError(code)

    when T is SomeNumber:
      value = T(tmp)
      return true
    elif T is string:
      value = $tmp
      return true
    else:
      {.fatal: "The type " & T.name & " is not supported yet.".}
  of REG_BINARY:
    var tmp: float64
    size = int32(sizeof(tmp))
    let code = regGetValueW(this, nil, newWideCString(name), 0x0000ffff, nil, cast[pointer](tmp.addr), size.addr)
    if code == ERROR_FILE_NOT_FOUND:
      return false
    if unlikely(code != ERROR_SUCCESS):
      raiseError(code)

    when T is SomeNumber:
      value = T(tmp)
      return true
    elif T is string:
      value = $tmp
      return true
    else:
      {.fatal: "The type " & T.name & " is not supported yet.".}
  of REG_SZ, REG_EXPAND_SZ:
    if size == 0:
      size = 256
    var buffer: WideCString
    unsafeNew(buffer, size + sizeof(Utf16Char))
    buffer[size div sizeof(Utf16Char) - 1] = Utf16Char(0)
    let code = regGetValueW(this, nil, newWideCString(name), 0x0000ffff, nil, cast[pointer](buffer), size.addr)
    if code == ERROR_FILE_NOT_FOUND:
      return false
    if unlikely(code != ERROR_SUCCESS):
      raiseError(code)

    when T is SomeOrdinal:
      value = parseInt($buffer)
      return true
    elif T is SomeFloat:
      value = parseFloat($buffer)
      return true
    elif T is string:
      value = $buffer
      return true
    else:
      {.fatal: "The type " & T.name & " is not supported yet.".}
  else:
    raise newException(RegistryError, "The registry value is of type " & $kind & ", which is not supported")

proc getValue*[T](this: RegistryKey, name: string, default: T): T {.raises: [RegistryError, ValueError].} =
  if not this.tryGetValue(name, result):
    result = default

proc getValueKind*(this: RegistryKey, name: string): RegistryValueType {.raises: [RegistryError].} =
  let code = regQueryValueExW(this, newWideCString(name), nil, result.addr, nil, nil)
  if unlikely(code != ERROR_SUCCESS):
    raiseError(code)

iterator getValueNames*(this: RegistryKey): string {.raises: [RegistryError].} =
  var valCount: int32
  let code = regQueryInfoKeyW(this, nil, nil, nil, nil, nil, nil, valCount.addr, nil, nil, nil, nil)
  if unlikely(code != ERROR_SUCCESS):
    raiseError(code)

  var nameBuffer = newWideCString((MAX_VALUE_LEN + 1) * sizeof(Utf16Char))

  for i in 0..<valCount:
    var nameLen: int32 = MAX_VALUE_LEN
    let code = regEnumValueW(this, int32(i), nameBuffer, nameLen.addr, nil, nil, nil, nil)
    if unlikely(code != ERROR_SUCCESS):
      raiseError(code)

    nameBuffer[nameLen] = Utf16Char(0)
    yield $nameBuffer

proc openSubKey*(this: RegistryKey, name: string, writable: bool): RegistryKey {.raises: [RegistryError].} =
  let code = regOpenKeyExW(this, newWideCString(name), 0, if writable: KEY_ALL_ACCESS else: KEY_READ, result.addr)
  if unlikely(code != ERROR_SUCCESS):
    raiseError(code)

proc openSubKey*(this: RegistryKey, name: string): RegistryKey {.raises: [RegistryError].} =
  return this.openSubKey(name, false)

proc setValue[T](this: RegistryKey, name: string, value: T, valueKind: RegistryValueType) {.raises: [RegistryError].} =
  when T is string:
    let wstr = newWideCString(value)
    let code = regSetKeyValueW(this, nil, newWideCString(name), valueKind, wstr[0].addr, int32(wstr.len * sizeof(Utf16Char) + sizeof(Utf16Char)))
  elif T is SomeNumber:
    var val = value
    let code = regSetKeyValueW(this, nil, newWideCString(name), valueKind, val.addr, int32(sizeof(value)))
  else:
    {.fatal: "A value of type " & T.name & " cannot be written directly to the registry.".}
  if unlikely(code != ERROR_SUCCESS):
    raiseError(code)

proc setValue*[T](this: RegistryKey, name: string, value: T) {.raises: [RegistryError].} =
  when T is int and sizeof(int) == 8:
    {.warning: "Only a REG_DWORD is written when using int in 64bit mode.".}
    this.setValue(name, int32(value), REG_DWORD)
  when T is uint and sizeof(uint) == 8:
    {.warning: "Only a REG_DWORD is written when using uint in 64bit mode.".}
    this.setValue(name, uint32(value), REG_DWORD)
  when T is int64 or T is uint64:
    this.setValue(name, value, REG_QWORD)
  elif T is SomeOrdinal:
    this.setValue(name, value, REG_DWORD)
  elif T is SomeFloat:
    this.setValue(name, float64(value), REG_BINARY)
  elif T is string:
    this.setValue(name, value, REG_SZ)
  else:
    {.fatal: "A value of type " & T.name & " cannot be written directly to the registry.".}
