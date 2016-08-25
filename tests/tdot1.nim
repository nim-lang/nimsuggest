discard """
$nimsuggest --tester $file
>sug $1
sug;;skField;;x;;int;;/private/tmp/tdot1.nim;;10;;4;;"";;100
sug;;skField;;y;;int;;/private/tmp/tdot1.nim;;10;;7;;"";;100
sug;;skProc;;tdot1.main;;proc (f: Foo);;/private/tmp/tdot1.nim;;12;;5;;"";;100
"""

type
  Foo = object
    x, y: int

proc main(f: Foo) =
  f.#[!]#
