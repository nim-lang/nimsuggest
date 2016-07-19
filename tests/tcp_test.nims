import strutils, ospaths

var port = 6000
var sample = thisDir() / "sample.nim"

proc check(file, direction: string, initialFile = sample) =
  exec """echo "$1" > message""".format(direction)
  exec """FILE=$1 PORT=$2 SAMPLE=$3 ./tcp_suggest_test""".format(
    file, $port, initialFile
  )
  echo "TEST: ", $file, " succeed!"
  port = port + 1

exec "bash ./replace.sh"

check("tcp_def", "def sample.nim:9:3")
check("tcp_sug", "sug sample.nim:13:2")
check("tcp_dus", "dus sample.nim:9:3")
check("tcp_highlight", "highlight sample.nim:-1:-1")
check("tcp_outline", "outline sample.nim:-1:-1")

# Check config.nims is properly detected
check("tcp_config_nims", "chk config_nims_test.nim:-1:-1",
      thisDir() / "config_nims_test.nim")

# FIXME: somehow this doesn't work...
# check("tcp_use", "use sample.nim:9:3")
# check("tcp_chk", "chk sample.nim:-1:-1")
