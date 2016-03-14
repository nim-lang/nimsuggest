#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nimsuggest is a tool that helps to give editors IDE like capabilities.
import tables, parseopt2, strutils, os, parseutils, sequtils, net, rdstdin, sexp

import compiler/options, compiler/commands, compiler/modules, compiler/sem,
  compiler/passes, compiler/passaux, compiler/msgs, compiler/nimconf,
  compiler/extccomp, compiler/condsyms, compiler/lists,
  compiler/sigmatch, compiler/ast

import modes/commonMode, modes/tcpMode, modes/stdinMode, modes/epcMode

const 
  nimsuggestVersion = "0.1.0"
  helpMsg = """
Nimsuggest - Tool to give every editor IDE like capabilities for Nim
Usage:
  nimsuggest [options] [mode] [mode_options] "path/to/projectfile.nim"

Options:
  --nimPath:"path"      Set the path to the Nim compiler.
  --v2                  Use protocol version 2       
  --debug               Enable debug output.
  --help                Print help output for the specified mode.
  --version             Print nimsuggest version to stdout, then quit.

Modes:
  tcp            Use text-based input from a tcp socket.
  stdin          Use text-based input from stdin (interactive use)
                 This is the default mode.
  epc            Use epc mode.

In addition, all command line options of Nim that do not affect code generation
are supported. To pass a Nim compiler command-line argument, prefix it with
"nim." when passing global options, for example:
  nimsuggest --nim.define:release tcp projectfile.nim
"""

type
  ModeKind = enum
    mkStdin, mkTcp, mkEpc

  NimsuggestData = ref object of RootObj
    case mode*: ModeKind
    of mkStdin:
      stdinData: StdinModeData
    of mkTcp:
      tcpData: TcpModeData
    of mkEpc:
      epcData: EpcModeData


# ModeData procedures which dispatch into mode-specific procedures.
proc initModeData(data: NimsuggestData, cmdline: CmdLineData) =
  case data.mode
  of mkStdin: 
    data.stdinData = initStdinModeData(cmdline)
  of mkTcp: 
    data.tcpData = initTcpModeData(cmdline)
  of mkEpc: 
    data.epcData = initEpcModeData(cmdline)

proc echoOptions(mode: ModeKind) =
  case mode
  of mkStdin: echoStdinModeOptions()
  of mkTcp:   echoTcpModeOptions()
  of mkEpc:   echoEpcModeOptions()

proc mainCommand(data: NimsuggestData) =
  case data.mode
  of mkStdin: mainCommand(data.stdinData)
  of mkTcp:   mainCommand(data.tcpData)
  of mkEpc:   mainCommand(data.epcData)


# Command line logic
proc gatherCmdLineData(): CmdLineData =
  ## Gather the command line parameters into an CmdLineData object.
  ## This works in two parts: we first get the global nimsuggest switches and
  ## mode, then get the mode switches and project file.
  var parser = initOptParser()
  result = CmdLineData(
      mode: "",
      nimsuggestSwitches: @[],
      modeSwitches: @[],
      compilerSwitches: @[],
      projectPath: "",
    )

  # Get the nimsuggest switches and mode
  while true:
    parser.next()
    case parser.kind
    of cmdLongOption, cmdShortOption:
      # We filter global switches here to allow the user to pass
      # switches to the compiler.
      if parser.key.startsWith("nim."):
        result.compilerSwitches.add(
          (parser.kind, parser.key[4..^1], parser.val)
        )
      else:
        result.nimsuggestSwitches.add(
          (parser.kind, parser.key, parser.val)
        )
    of cmdArgument:
      result.mode = parser.key
      break
    of cmdEnd:
      break

  # Process the remaining mode switches and project file.
  while true:
    parser.next()
    case parser.kind:
    of cmdLongOption, cmdShortOption:
      result.modeSwitches.add(
        (parser.kind, parser.key, parser.val)
      )
    of cmdArgument:
      # Grab the project file and exit
      result.projectPath = parser.key
      break
    of cmdEnd:
      break

  # Ensure that there are no remaining arguments
  parser.next()
  if parser.kind != cmdEnd:
    quit("Error: Extra switches after project file.")


proc oldProcessCmdLine*(): CmdLineData =
  var parser = initOptParser()
  result = CmdLineData(
      mode: "",
      nimsuggestSwitches: @[],
      modeSwitches: @[],
      compilerSwitches: @[],
      projectPath: "",
    )

  result.mode = "stdin"
  result.modeSwitches.add(
    (cmdLongoption, "interactive", "true")
  )

  while true:
    parser.next()
    case parser.kind
    of cmdEnd: break
    of cmdLongoption, cmdShortOption:
      case parser.key.normalize
      of "port", "address":
        result.mode = "tcp"
        result.modeSwitches.add(
          (parser.kind, parser.key, parser.val)
        )
      of "stdin":
        discard
      of "epc":
        result.mode = "epc"
      of "debug":
        incl(gGlobalOptions, optIdeDebug)
      of "v2":
        suggestVersion = 2
      else:
        result.compilerSwitches.add(
          (parser.kind, parser.key, parser.val)
        )
    of cmdArgument:
      result.projectPath = unixToNativePath(parser.key)


# Main setup procs
proc setupCompiler(projectPath: string) =
    condsyms.initDefines()
    defineSymbol "nimsuggest"

    gProjectName = unixToNativePath(projectPath)
    if gProjectName != "":
      try:
        gProjectFull = canonicalizePath(gProjectName)
      except OSError:
        gProjectFull = gProjectName
        
      var p = splitFile(gProjectFull)
      gProjectPath = p.dir
    else:
      gProjectPath = getCurrentDir()

    # Find Nim's prefix dir.
    let binaryPath = findExe("nim")
    if binaryPath == "":
      raise newException(IOError,
          "Cannot find Nim standard library: Nim compiler not in PATH")
    gPrefixDir = binaryPath.splitPath().head.parentDir()

    # Load the configuration files
    loadConfigs(DefaultConfig) # load all config files

    extccomp.initVars()
    registerPass verbosePass
    registerPass semPass

    gCmd = cmdIdeTools
    gGlobalOptions.incl(optCaasEnabled)
    isServing = true
    msgs.gErrorMax = high(int)

    wantMainModule()
    appendStr(searchPaths, options.libpath)
    if gProjectFull.len != 0:
      # current path is always looked first for modules
      prependStr(searchPaths, gProjectPath)


proc main =
  var data = NimsuggestData()
  if paramCount() == 0:
    quit(helpMsg)

  # Gather and process command line data
  var cmdLineData = gatherCmdLineData()
  if normalize(cmdLineData.mode) notin ["tcp", "epc", "stdin"]:
    cmdLineData = oldProcessCmdLine()

  # Get the mode
  case cmdLineData.mode.normalize
  of "tcp":   data.mode = mkTcp
  of "epc":   data.mode = mkEpc
  of "stdin": data.mode = mkStdin

  # Process the nimsuggest switches
  for switch in cmdLineData.nimsuggestSwitches:
    case switch.kind
    of cmdLongOption:
      case switch.key.normalize
      of "help", "h":
        echo(helpMsg)
        echoOptions(data.mode)
        quit(QuitFailure)
      of "v2":
        suggestVersion = 2
      of "version":
        quit(nimsuggestVersion)
      else:
        quit("Invalid switch '$#:$#'" % [switch.key, switch.value])
    else:
      quit("Invalid switch '$#:$#'" % [switch.key, switch.value])

  # Check for project path here. Checking any earlier leads to --help not
  # working without a project path.
  if cmdLineData.projectPath == "":
    quit("Error: Project path not supplied")

  # Initialize mode-specific data
  # Uses the previously set data.mode
  data.initModeData(cmdLineData)

  # Process the compiler switches
  for switch in cmdLineData.compilerSwitches:
    commands.processSwitch(switch.key, switch.value, passCmd1, gCmdLineInfo)

  # Initialize Environment
  setupCompiler(cmdLineData.projectPath)

  # Process the command line again, as some parts may have been overridden by
  # configuration files.
  for switch in cmdLineData.compilerSwitches:
    commands.processSwitch(switch.key, switch.value, passCmd2, gCmdLineInfo)

  var oldHook = msgs.writelnHook
  msgs.writelnHook = (proc (msg: string) = discard)
  compileProject()
  msgs.writelnHook = oldHook
  data.mainCommand()

suggestVersion = 1
when isMainModule:
  main()
