import tables, net, parseopt2, strutils
import compiler/msgs
import commonMode

from os import nil

const tcpModeHelpMsg = """
Nimsuggest TCP Mode Switches:
  -p, --port:port_no         Port to use to connect (defaults to 8000).
  --address:"address"        Address to bind/connect to. Defaults to ""
  --persist                  Create a persistant connection that isn't closed
                             after the first completed command. Completed
                             commands are then denoted by a newline.
                             Not compatible with the 'client' switch.
  --client                   Act as a client. In client mode the nimsuggest
                             tool will attempt to connect to the address and
                             port specified by the 'address' and 'port'
                             switches, instead of binding to them as a server.
"""


type TcpModeData* = ref object of BaseModeData
  port: Port
  address: string
  client: bool
  persist: bool


# ModeData Interface Methods
proc initTcpModeData*(cmdline: CmdLineData): TcpModeData =
  new(result)
  result.projectPath = cmdline.projectPath
  result.port = Port(0)
  result.address = ""
  result.client = false

  for switch in cmdline.modeSwitches:
    case switch.kind
    of cmdLongOption, cmdShortOption:
      case switch.key.normalize
      of "p", "port":
        try:
          result.port = Port(parseInt(switch.value))
        except ValueError:
          quit("Invalid port:'" & switch.value & "'")
      of "address":
        result.address = switch.value
      of "client":
        result.client = true
      of "persist":
        if switch.value == "":
          result.persist = true
        else:
          try:
            result.persist = parseBool(switch.value)
          except ValueError:
            quit("Invalid 'persistance' value '" & switch.value & "'")
      else:
        quit("Invalid mode switch '$#'" % [switch.key])
    else:
      discard

proc echoTcpModeOptions*() =
  echo(tcpModeHelpMsg)

proc serveAsServer(data: TcpModeData) =
  var 
    server = newSocket()
    stdoutSocket: Socket
    inp = "".TaintedString
  server.bindAddr(data.port, data.address)
  server.listen()

  template setupStdoutSocket = 
    stdoutSocket = newSocket()
    msgs.writelnHook = proc (line: string) =
      stdoutSocket.send(line & "\c\L")
    accept(server, stdoutSocket)

  setupStdoutSocket()
  while true:
    stdoutSocket.readLine(inp)
    parseCmdLine inp.string
    stdoutSocket.send("\c\L")

    if not data.persist:
      stdoutSocket.close()
      setupStdoutSocket()

proc serveAsClient(data: TcpModeData) =
  var
    input = "".TaintedString
    stdoutSocket: Socket

  while true:
    if stdoutSocket == nil:
      stdoutSocket = newSocket()
      stdoutSocket.connect(data.address, data.port)
      msgs.writelnHook = proc (line: string) =
        stdoutSocket.send(line & "\c\L")

    try:
      stdoutSocket.readLine(input)
      if input == "":
        stdoutSocket = nil
        continue
      parseCmdLine(string(input))
      stdoutSocket.send("\c\l\c\l")
    except OSError:
      quit()

proc mainCommand*(data: TcpModeData) =
  msgs.writelnHook = proc (msg: string) = discard
  echo("Running Nimsuggest TCP Mode on port $#, address \"$#\"" % [$data.port, data.address])
  echo("Project file: \"$#\"" % [data.projectPath])
  if data.client:
    serveAsClient(data)
  else:
    serveAsServer(data)