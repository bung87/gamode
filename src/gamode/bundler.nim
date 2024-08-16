
when NimMajor >= 2:
  import pkg/htmlparser
else:
  import htmlparser
import xmltree  # To use '$' for XmlNode
import strtabs  # To access XmlAttributes
import os       # To use splitFile
import strutils # To use cmpIgnoreCase

proc getFileExt(file: string): string =
  let split = file.split('.')
  result = split[split.high]

proc bundleAssets*(htmlPath:string, pDir: string):string {.compileTime.} =
  let content = staticRead(htmlPath)

  let html = parseHtml(content)

  for a in  html.findAll("link"):
    if a.attrs.hasKey "href":
      let ext = getFileExt(a.attrs["href"])
      if cmpIgnoreCase(ext, "css") == 0:
        a.tag = "style"
        a.add newVerbatimText(staticRead(pDir / unixToNativePath(a.attrs["href"])))
        a.attrs.del "href"
        a.attrs.del "rel"
  for a in html.findAll("script"):
    if a.attrs.hasKey "src":
      let ext = getFileExt(a.attrs["src"])
      if cmpIgnoreCase(ext, "js") == 0:
        a.add newVerbatimText(staticRead(pDir / unixToNativePath(a.attrs["src"])))
        a.attrs.del "src"
  return $html