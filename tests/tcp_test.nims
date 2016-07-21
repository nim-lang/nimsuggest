import strutils, ospaths

var sample = thisDir() / "sample.nim"
const kill_nimsuggest = "if pgrep nimsuggest; then pkill -9 -x nimsuggest; fi"

proc check(file, direction: string, initialFile = sample) =
  exec """echo "$1" > message""".format(direction)
  exec """FILE=$1 SAMPLE=$2 ./tcp_suggest_test""".format(file, initialFile)
  echo "TEST: ", $file, " succeed!"

template test(desc, body: typed) =
  echo desc
  # Setup
  exec kill_nimsuggest
  body
  # Teardown
  exec kill_nimsuggest
  echo "------------------------"

# Replace <<<__THIS_DIRECTORY__>>> to $PWD in expected dir
# and put converted files expected_tmp directory
exec "bash ./replace.sh"

test("TCP mode should apply basic methods:"):
  check("tcp_def", "def sample.nim:9:3")
  check("tcp_sug", "sug sample.nim:13:2")
  check("tcp_use", "use sample.nim:9:3")
  check("tcp_dus", "dus sample.nim:9:3")
  check("tcp_highlight", "highlight sample.nim:-1:-1")
  check("tcp_chk", "chk sample.nim:-1:-1")

# Check config.nims is properly detect
test("TCP mode should detect config.nims"):
  check("tcp_config_nims", "chk config_nims_test.nim:-1:-1",
        thisDir() / "config_nims_test.nim")
