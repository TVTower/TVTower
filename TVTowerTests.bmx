SuperStrict

Framework BaH.MaxUnit

Import pub.freeaudio 'fuer rtaudio

Import "source/main.bmx"
Incbin "source/version.txt"


'Unit-Tests
Include "unittests/test_testsuite.bmx"

New TTestSuite.run()