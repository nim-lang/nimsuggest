import tables, net, parseopt2, strutils, rdstdin
import compiler/msgs
import commonMode

const stdinModeHelpMsg = """
Nimsuggest Stdin Mode Switches:
  -i, --interactive:[true|false]
          Run in interactive mode, suitable for terminal use.       
"""

const interactiveHelpMsg = """
Usage: sug|con|def|use|dus|chk|highlight|outline file.nim[;dirtyfile.nim]:line:col
Type 'quit' to quit, 'debug' to toggle debug mode on/off, and 'terse'
to toggle terse mode on/off.
"""


type StdinModeData* = ref object of BaseModeData
  interactive: bool


# ModeData Interface Methods
proc initStdinModeData*(cmdline: CmdLineData): StdinModeData =
  new(result)
  result.projectPath = cmdline.projectPath
  result.interactive = true

  for switch in cmdline.modeSwitches:
    case switch.kind
    of cmdLongOption, cmdShortOption:
      case switch.key.normalize
      of "interactive", "i":
        if switch.value == "":
          result.interactive = true
        else:
          try:
            result.interactive = parseBool(switch.value)
          except ValueError:
            quit("Invalid \"interactive\" value \"" & switch.value & "\"")
      else:
        quit("Invalid mode switch \"$#:$#\"" % [switch.key, switch.value])
    else:
      discard

proc echoStdinModeOptions*() =
  echo(stdinModeHelpMsg)

proc mainCommand*(data: StdinModeData) =
  msgs.writelnHook = (proc (msg: string) = echo msg)
  let prefix = if data.interactive: "> " else: ""
  if data.interactive:
    echo("Running Nimsuggest Stdin Mode")
    echo("Project file: \"$#\"" % [data.projectPath])
    echo interactiveHelpMsg

  var line = ""
  while readLineFromStdin(prefix, line):
    flushFile(stdin)
    parseCmdLine line
    echo("\n")
    flushFile(stdout)