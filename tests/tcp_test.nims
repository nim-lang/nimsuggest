import strutils

var port = 6010

proc check(file, direction: string) =
  exec """echo "$1" > message""".format(direction)
  exec """FILE=$1 PORT=$2 ./tcp_suggest_test""".format(file, $port)
  echo "TEST: ", $file, " succeed!"
  port = port + 1

exec "bash ./replace.sh"

check("tcp_def", "def sample.nim:9:3")
check("tcp_sug", "sug sample.nim:13:2")
check("tcp_dus", "dus sample.nim:9:3")
check("tcp_highlight", "highlight sample.nim:-1:-1")
check("tcp_outline", "outline sample.nim:-1:-1")

# FIXME: somehow this doesn't work...
# check("tcp_use", "use sample.nim:9:3")
# check("tcp_chk", "chk sample.nim:-1:-1")
