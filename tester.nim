# Tester for nimsuggest.
# Every test file can have a #[!]# comment that is deleted from the input
# before 'nimsuggest' is invoked to ensure this token doesn't make a
# crucial difference for Nim's parser.

import os, osproc, strutils, streams

type
  Test = object
    cmd: string
    script: seq[(string, string)]

const
  curDir = when defined(windows): "" else: "./"
  DummyEof = "!EOF!"

proc parseTest(filename: string): Test =
  const cursorMarker = "#[!]#"
  let nimsug = curDir & addFileExt("nimsuggest", ExeExt)
  let dest = getTempDir() / extractFilename(filename)
  result.cmd = nimsug & " --tester " & dest
  result.script = @[]
  var tmp = open(dest, fmWrite)
  var specSection = 0
  var markers = newSeq[string]()
  var i = 1
  for x in lines(filename):
    let marker = x.find(cursorMarker)+1
    if marker > 0:
      markers.add dest & ":" & $i & ":" & $marker
      tmp.writeLine x.replace(cursorMarker, "")
    else:
      tmp.writeLine x
    if x.contains("""""""""):
      inc specSection
    elif specSection == 1:
      if x.startsWith("$nimsuggest"):
        result.cmd = x % ["nimsuggest", nimsug, "file", dest]
      elif x.startsWith(">"):
        # since 'markers' here are not complete yet, we do the $substitutions
        # afterwards
        result.script.add((x.substr(1), ""))
      else:
        # expected output line:
        result.script[^1][1].add x.replace(";;", "\t") & '\L'
    inc i
  tmp.close()
  # now that we know the markers, substitute them:
  for a in mitems(result.script):
    a[0] = a[0] % markers

proc runTest(filename: string) =
  let s = parseTest filename
  let cl = parseCmdLine(s.cmd)
  var p = startProcess(command=cl[0], args=cl[1 .. ^1],
                       options={poStdErrToStdOut, poUsePath,
                       poInteractive, poDemon})
  let outp = p.outputStream
  let inp = p.inputStream
  var report = ""
  var a = newStringOfCap(120)
  # read and ignore anything nimsuggest says at startup:
  while outp.readLine(a):
    echo "got ", a
    if a == DummyEof: break
  for req, resp in items(s.script):
    echo "requesting ", req
    inp.writeLine(req)
    var answer = ""
    when false:
      while outp.readLine(a):
        if a == DummyEof: break
        answer.add a
        answer.add '\L'
    else:
      answer = outp.readAll()
    if answer != resp:
      report.add "\nTest failed: " & filename
      report.add "\n  Expected:  " & resp
      report.add "\n  But got:   " & answer
  inp.writeLine("quit")
  close(p)

proc main() =
  for x in walkFiles("tests/t*.nim"):
    runTest(x)

main()
