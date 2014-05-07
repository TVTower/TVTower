Rem
	Mersenne: Random numbers

	Version: 1.01"
	Author: Various"
	License: Public Domain"
	Credit: Adapted for BlitzMax by Kanati"
EndRem
import brl.blitz

Import "base.util.mersenne.c"

Extern "c"
  Function SeedRand(seed:int)
  Function Rand32:Int()
  Function RandMax:Int(hi:int)
  Function RandRange:Int(lo:int,hi:int)
End Extern