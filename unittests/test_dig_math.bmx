SuperStrict

Framework brl.standardio
Import BRL.MaxUnit
Import "../source/Dig/base.util.math.bmx"

New TTestSuite.run()

Type TMathTest Extends TTest
	Method setup() { before }
		'nothing to prepare for now
	End Method

	
	Method testNumberToString() { test }
		assertEquals("0.95",  NumberToString(0.95, 2))
		assertEquals("0.95",  NumberToString(0.95, 2, False))
		assertEquals("0.95",  NumberToString(0.95, 2, False, Asc(".")))
		assertEquals("0.95",  NumberToString(0.95, 2, True, Asc(".")))
		assertEquals("0,95",  NumberToString(0.95, 2, True, Asc(",")))
		assertEquals("1.00",  NumberToString(0.995, 2))
		assertEquals("123456.950", NumberToString(123456.95, 3, False))
		assertEquals("123456.95",  NumberToString(123456.95, 3, True))
	End Method

	Method testNegativeNumberToString() { test }
		assertEquals("-0.95",  NumberToString(-0.95, 2))
		assertEquals("-0.95",  NumberToString(-0.95, 2, False))
		assertEquals("-0.95",  NumberToString(-0.95, 2, False, Asc(".")))
		assertEquals("-0.95",  NumberToString(-0.95, 2, True, Asc(".")))
		assertEquals("-0,95",  NumberToString(-0.95, 2, True, Asc(",")))
		assertEquals("-123456.950",  NumberToString(-123456.95, 3, False))
		assertEquals("-123456.95",  NumberToString(-123456.95, 3, True))
	End Method


	Method testNumberToDottedValue() { test }
		assertEquals("1,000.00",  NumberToDottedValue(1000, Asc(","), Asc("."), 2))
		assertEquals("1,000",     NumberToDottedValue(1000, Asc(","), Asc("."), 0))
		assertEquals("1,000",     NumberToDottedValue(1000, Asc(","), Asc("."),-1))
		assertEquals("1,000",     NumberToDottedValue(1000, Asc(","), Asc(".")))

		assertEquals("-1,000.00",  NumberToDottedValue(-1000, Asc(","), Asc("."), 2))
		assertEquals("-1,000",     NumberToDottedValue(-1000, Asc(","), Asc("."), 0))
		assertEquals("-1,000",     NumberToDottedValue(-1000, Asc(","), Asc("."),-1))
		assertEquals("-1,000",     NumberToDottedValue(-1000, Asc(","), Asc(".")))

		assertEquals("123,456,000.78",  NumberToDottedValue(123456000.78, Asc(","), Asc("."), 2))
		assertEquals("-123,456,000.78",  NumberToDottedValue(-123456000.78, Asc(","), Asc("."), 2))
	End Method
End Type
