# This file tests EPC (Emacs RPC) protocol, which is used to communicate
# between nimsuggest and Emacs.
# See also: https://github.com/kiwanami/emacs-epc/#implementation

when defined(epctest):
  import strutils, ospaths

proc mockEPCCall(sug_method, real, dirty: string,
                 id, line, column: int,
                 nohex = false): string =
  ## mock EPC call API
  let
    fmt = if nohex:
            """(call $1 $2 ("$3" $4 $5 "$6"))"""
          else:
            """(call $1 $2 (\"$3\" $4 $5 \"$6\"))"""
    content = format(fmt, id, sug_method, real, line, column, dirty)
    hexSize = "$1".format(toHex(len(content) - 4, 6).toLower)
  if nohex:
    content
  else:
    hexSize & content

when defined(epctest):
  let sample = thisDir() / "sample.nim"
  proc check(file, mtd: string, epc_id: int, line, column: int,
             real=sample, dirty=sample) =
    let
      direction = mockEPCCall(mtd, real, dirty, epc_id, line, column)
    echo "TEST: ", $file, " started:"
    exec """echo "$#" > message""".format(direction)
    exec "FILE=$# ./epc_suggest_test".format(file)
    echo "      ", $file, " SUCCEED!"

  # Currently nimsuggest-epc is not supported all available methods
  check("epc_def", "def", 1, 9, 3)
  check("epc_dus", "dus", 1, 9, 3)
  check("epc_sug", "sug", 1, 13, 2)
  check("epc_use", "use", 1, 9, 3)
  check("epc_chk", "chk", 1, -1, -1)

  # Check config.nims is properly detected
  let conffile = thisDir() /  "config_nims_test.nim"
  check("epc_config_nims", "chk", 1, -1, -1, conffile, conffile)
