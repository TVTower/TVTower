SuperStrict

'Framework BaH.MaxUnit
Framework Brl.StandardIO
Import "source/external/maxunit.bmx"

'Import pub.freeaudio 'fuer rtaudio

Import "source/main.bmx"
Incbin "source/version.txt"


'Unit-Tests
Include "unittests/test_testsuite.bmx"

New TTestSuite.run()