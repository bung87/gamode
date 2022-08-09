import winim/inc/winuser
import winim/inc/wingdi

var settings: DEVMODEW
EnumDisplaySettings(nil, ENUM_REGISTRY_SETTINGS, settings.addr )
echo repr settings