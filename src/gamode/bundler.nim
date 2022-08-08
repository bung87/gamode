import htmlparser
import xmltree  # To use '$' for XmlNode
import strtabs  # To access XmlAttributes
import os       # To use splitFile
import strutils # To use cmpIgnoreCase

proc getFileExt(file: string): string =
  let split = file.split('.')
  result = split[split.high]

proc bundleAssets*(htmlPath:string, pDir: string):string =
  let content = staticRead(htmlPath)

  let html = parseHtml(content)
  for a in  html.findAll("link"):
    if a.attrs.hasKey "href":
      let ext = getFileExt(a.attrs["href"])
      if cmpIgnoreCase(ext, "css") == 0:
        a.tag = "style"
        # when compileTime:
        a.add newVerbatimText(staticRead(pDir / unixToNativePath(a.attrs["href"])))
        # else:
        #   a.add newText(readFile(pDir / unixToNativePath(a.attrs["href"])))
        a.attrs.del "href"
        a.attrs.del "rel"
  for a in html.findAll("script"):
    if a.attrs.hasKey "src":
      let ext = getFileExt(a.attrs["src"])
      if cmpIgnoreCase(ext, "js") == 0:
        # when compileTime:
        a.add newVerbatimText(staticRead(pDir / unixToNativePath(a.attrs["src"])))
        # else:
        #   a.add newText(readFile(pDir / unixToNativePath(a.attrs["src"])))
        a.attrs.del "src"
  return $html