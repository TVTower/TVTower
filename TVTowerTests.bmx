SuperStrict

Framework Brl.StandardIO
Import BRL.MaxUnit

Import "source/main.bmx"
Incbin "source/version.txt"


'Unit-Tests
Include "unittests/test_testsuite.bmx"

New TTestSuite.run()
