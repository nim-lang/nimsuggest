import ../sexp, os
import strutils

var
  prjpath = getCurrentDir() / "sample.nim" ## Project Path
  dirty = prjpath ## dirty file (tmp file)
  sug = "dus" ## method name like sug/def/dus/chk etc.
  id = 1 ## uid for EPC (only Emacs care about)
  line = 9 ## line number to test
  col = 3 ## column number to test

include "./epc_call.nims"

proc checkEPCProtocol() =
  # Check `mockEPCProtocol` is working correctl
  let
    s = parseSexp(mockEPCCall(sug, prjpath, dirty, id, line, col, on))
    epcAPI = s[0]
    unique_id = s[1].getNum
    args = s[3]

  assert("call" == epcAPI.getSymbol)
  assert(1 == unique_id)
  let
    dirty = args[0].getStr
    line = args[1].getNum
    column = args[2].getNum

  assert(prjpath == dirty) # no need to be same though
  assert(9 == line)
  assert(3 == column)

when isMainModule:
  checkEPCProtocol()
