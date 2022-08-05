import winim/inc/winimbase
import winim/inc/powrprof
import common

const MaximumPerformance = DEFINE_GUID("8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c")
const Balanced = DEFINE_GUID("381b4222-f694-41f0-9685-ff5bb260df2e")
const PowerSourceOptimized = DEFINE_GUID("a1841308-3541-4fab-bc81-f71556f20b4a")

var preserve: HKEY
# PowerSetActiveScheme(preserve, MaximumPerformance.unsafeAddr)
PowerSetActiveScheme(preserve, Balanced.unsafeAddr)
