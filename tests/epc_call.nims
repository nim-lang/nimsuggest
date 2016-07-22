# This file tests EPC (Emacs RPC) protocol, which is used to communicate
# between nimsuggest and Emacs.
# See also: https://github.com/kiwanami/emacs-epc/#implementation

when not defined(unitTest):
  import strutils, ospaths
  const
    prjpath {.strdefine.} = thisDir() / "sample.nim" ## Project Path
    dirty {.strdefine.} = prjpath ## dirty file (tmp file)
    sug {.strdefine.} = "def" ## method name like sug/def/dus/chk etc.
    id {.intdefine.} = 1 ## uid for EPC (only Emacs care about)
    line {.intdefine.} = 1 ## line number to test
    col {.intdefine.} = 1 ## column number to test

proc mockEPCCall(sug=sug, prjpath=prjpath, dirty=dirty,
                 id=id, line=line, col=col, nohex = false): string =
  ## mock EPC call API
  let
    fmt = """(call $1 $2 ("$3" $4 $5 "$6"))"""
    content = format(fmt, id, sug, prjpath, line, col, dirty)
    hexSize = "$1".format(toHex(len(content), 6).toLower)
  if nohex:
    content
  else:
    hexSize & content

when not defined(unitTest):
  echo mockEPCCall()
