import ../sexp, os
import strutils

let sample = getCurrentDir() / "sample.nim"

include "./epc_test.nims"

proc checkEPCProtocol(sample: string) =
  # Check `mockEPCProtocol` is working correctl
  let
    s = parseSexp(mockEPCCall("dus", sample, sample, 1, 9, 3, on))
    epcAPI = s[0]
    unique_id = s[1].getNum
    args = s[3]

  assert("call" == epcAPI.getSymbol)
  assert(1 == unique_id)
  let
    dirty = args[0].getStr
    line = args[1].getNum
    column = args[2].getNum

  assert(sample == dirty)
  assert(9 == line)
  assert(3 == column)

when isMainModule:
  checkEPCProtocol(sample)
