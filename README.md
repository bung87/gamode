# gamode  

- [x] enable system builtin game mode  
- [x] disable <kbd>win</kbd> hotkeys  
- [ ] load us keyboard layout for CJK users  
- [ ] disable File and Printer Sharing  
- [x] disable windows auto update  


## Development  

`nim c -d:release  .\src\gamode.nim`

assembly Manifests(require windows SDK)  

`mt.exe -manifest .\src\gamode.exe.manifest -outputresource:.\src\gamode.exe` 