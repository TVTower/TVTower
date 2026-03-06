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
		assertEquals("0.95",  MathHelper.NumberToString(0.95, 2))
		assertEquals("0.95",  MathHelper.NumberToString(0.95, 2, False))
		assertEquals("0.95",  MathHelper.NumberToString(0.95, 2, False, Asc(".")))
		assertEquals("0.95",  MathHelper.NumberToString(0.95, 2, True, Asc(".")))
		assertEquals("0,95",  MathHelper.NumberToString(0.95, 2, True, Asc(",")))
		assertEquals("1.00",  MathHelper.NumberToString(0.995, 2))
		assertEquals("123456.950", MathHelper.NumberToString(123456.95, 3, False))
		assertEquals("123456.95",  MathHelper.NumberToString(123456.95, 3, True))
	End Method

	Method testNegativeNumberToString() { test }
		assertEquals("-0.95",  MathHelper.NumberToString(-0.95, 2))
		assertEquals("-0.95",  MathHelper.NumberToString(-0.95, 2, False))
		assertEquals("-0.95",  MathHelper.NumberToString(-0.95, 2, False, Asc(".")))
		assertEquals("-0.95",  MathHelper.NumberToString(-0.95, 2, True, Asc(".")))
		assertEquals("-0,95",  MathHelper.NumberToString(-0.95, 2, True, Asc(",")))
		assertEquals("-123456.950", MathHelper.NumberToString(-123456.95, 3, False))
		assertEquals("-123456.95",  MathHelper.NumberToString(-123456.95, 3, True))
	End Method


	Method testNumberToDottedValue() { test }
		assertEquals("1,000.00",  MathHelper.DottedValue(1000, Asc(","), Asc("."), 2, False))
		assertEquals("1,000",     MathHelper.DottedValue(1000, Asc(","), Asc("."), 2))
		assertEquals("1,000",     MathHelper.DottedValue(1000, Asc(","), Asc("."), 0))
		assertEquals("1,000",     MathHelper.DottedValue(1000, Asc(","), Asc("."),-1))
		assertEquals("1,000",     MathHelper.DottedValue(1000, Asc(","), Asc(".")))

		assertEquals("-1,000.00",  MathHelper.DottedValue(-1000, Asc(","), Asc("."), 2, False))
		assertEquals("-1,000",     MathHelper.DottedValue(-1000, Asc(","), Asc("."), 2))
		assertEquals("-1,000",     MathHelper.DottedValue(-1000, Asc(","), Asc("."), 0))
		assertEquals("-1,000",     MathHelper.DottedValue(-1000, Asc(","), Asc("."),-1))
		assertEquals("-1,000",     MathHelper.DottedValue(-1000, Asc(","), Asc(".")))

		assertEquals("123,456,000.78",  MathHelper.DottedValue(123456000.78, Asc(","), Asc("."), 2))
		assertEquals("-123,456,000.78", MathHelper.DottedValue(-123456000.78, Asc(","), Asc("."), 2))
	End Method
	

	Method testLongDigitCount() { test }
		assertEquals(1, MathHelper.LongDigitCount(0))

		assertEquals(1, MathHelper.LongDigitCount(-5))
		assertEquals(1, MathHelper.LongDigitCount( 5))

		assertEquals(2, MathHelper.LongDigitCount(-50))
		assertEquals(2, MathHelper.LongDigitCount( 50))

		assertEquals(5, MathHelper.LongDigitCount(-50000))
		assertEquals(5, MathHelper.LongDigitCount( 50000))
	End Method
End Type
