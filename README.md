# <img src="logo256.png" alt="logo" width="32" height="32" style="vertical-align: bottom;" /> gamode  

windows optimization tool for game.

support win8 and upper.  

development under win11.  

![preview](preview.png)  

- [x] enable system builtin game mode  
- [x] disable <kbd>win</kbd> hotkeys  
- [x] load us keyboard layout for CJK users  
- [ ] disable File and Printer Sharing  
- [x] disable windows auto update  
- [x] disable mouse enhance pointer precision
- [x] switch to maximum performance power plan
- [x] switch monitor refresh rate between 60 and max  
- [x] switch sysMain service status  
- [x] switch Windows Search service status

## Development  

`nim c -d:release --app:gui .\src\gamode.nim`

assembly Manifests(require windows SDK)  

`mt.exe -manifest .\src\gamode.exe.manifest -outputresource:.\src\gamode.exe` 

set app icon  
`rcedit ".\src\gamode.exe" --set-icon "gamode.ico"`