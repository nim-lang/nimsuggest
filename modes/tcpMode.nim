import tables, net, parseopt2, strutils
import ../nimsuggest, commonMode
import compiler/msgs


const tcpModeHelpMsg = """
Nimsuggest TCP Mode Switches:
  -p, --port:port_no         Port to use to connect (defaults to 8000).
  --address:"address"        Address to bind to. Defaults to ""
  --persist                  Create a persistant connection that isn't closed
                             after the first completed command. Completed
                             commands are then denoted by a newline.
"""


type TcpModeData = ref object of ModeData
  port: Port
  address: string not nil
  persist: bool


proc initializeData*(): ModeData =
  var res = new(TcpModeData)
  res.port = Port(0)
  res.address = ""

  result = ModeData(res)

proc addModes*(modes: TableRef[string, ModeInitializer]) =
  modes["tcp"] = initializeData


# ModeData Interface Methods
method processSwitches(data: TcpModeData, switches: SwitchSequence) =
  for switch in switches:
    case switch.kind
    of cmdLongOption, cmdShortOption:
      case switch.key.normalize
      of "p", "port":
        try:
          data.port = Port(parseInt(switch.value))
        except ValueError:
          quit("Invalid port:'" & switch.value & "'")
      of "address":
        data.address = switch.value
      of "persist":
        if switch.value == "":
          data.persist = true
        else:
          try:
            data.persist = parseBool(switch.value)
          except ValueError:
            quit("Invalid 'persistance' value '" & switch.value & "'")
      else:
        echo("Invalid mode switch '$#'" % [switch.key])
        quit()
    else:
      discard

method echoOptions(data: TcpModeData) =
  echo(tcpModeHelpMsg)
  quit()

method mainCommand(data: TcpModeData) =
  msgs.writelnHook = proc (msg: string) = discard
  echo("Running Nimsuggest TCP Mode on port $#, address \"$#\"" % [$data.port, data.address])
  echo("Project file: \"$#\"" % [data.projectPath])
  var
    inp = "".TaintedString
    server = newSocket()
  server.bindAddr(data.port, data.address)
  server.listen()

  if data.persist:
    var stdoutSocket = newSocket()
    msgs.writelnHook = proc (line: string) =
      stdoutSocket.send(line & "\c\L")
      
    accept(server, stdoutSocket)
    
    template readWriteCommand() =
        stdoutSocket.readLine(inp)
        parseCmdLine inp.string
        stdoutSocket.send("\c\l")

    while true:
      readWriteCommand()
      if data.persist:
        stdoutSocket.close()
        server = newSocket()