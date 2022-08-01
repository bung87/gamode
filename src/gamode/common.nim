import winim/inc/windef
export windef

converter toLPCWSTR*(s: string): LPCWSTR = 
  ## Converts a Nim string to Sciter-expected ptr wchar_t (LPCWSTR)
  var widestr = newWideCString(s)
  result = cast[LPCWSTR](addr widestr[0])