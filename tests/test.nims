import strutils

var port = 6000

proc check(file, direction: string) =
  exec """echo "$1" > message""".format(direction)
  exec """FILE=$1 PORT=$2 ./suggest_test""".format(file, $port)
  echo "TEST: ", $file, " succeed!"
  port = port + 1

check("tcp_def", "def sample.nim:9:3")
