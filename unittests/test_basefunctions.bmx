SuperStrict

Framework brl.standardio
Import BRL.MaxUnit
Import "../source/basefunctions.bmx"

New TTestSuite.run()

Type TMathTest Extends TTest
	Method setup() { before }
		'nothing to prepare for now
	End Method

	
	Method testRoundToBeautifulValue() { test }
		assertEquals(50,  TFunctions.RoundToBeautifulValue(43))
		assertEquals(200,  TFunctions.RoundToBeautifulValue(190))
		assertEquals(23000,  TFunctions.RoundToBeautifulValue(23000))
		assertEquals(55000,  TFunctions.RoundToBeautifulValue(53000))

		assertEquals(-50,  TFunctions.RoundToBeautifulValue(-43))
		assertEquals(-200,  TFunctions.RoundToBeautifulValue(-190))
		assertEquals(-23000,  TFunctions.RoundToBeautifulValue(-23000))
		assertEquals(-55000,  TFunctions.RoundToBeautifulValue(-53000))
	End Method

End Type
