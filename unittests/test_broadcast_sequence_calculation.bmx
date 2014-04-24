Type SequenceCalculationTest Extends TTest
	Method GetSequenceDefault() { test }	
		Local sequenceCalc:TSequenceCalculation = new TSequenceCalculation		
		sequenceCalc.PredecessorShareOnRise = 0.25
		sequenceCalc.PredecessorShareOnShrink  = 0.5
		sequenceCalc.Successor = New TAudienceAttraction		
		sequenceCalc.Successor.BlockAttraction = TAudience.CreateAndInitValue(100)
		sequenceCalc.Successor.CalculateFinalAttraction()

		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(-25), sequenceCalc.GetSequenceDefault())
		
		sequenceCalc.Successor.BlockAttraction = TAudience.CreateAndInit(10, 20, 30, 40, 50, 60, 70, 80, 90)
		sequenceCalc.Successor.CalculateFinalAttraction()
		TestAssert.assertEqualsAud(TAudience.CreateAndInit(-2.5, -5, -7.5, -10, -12.5, -15, -17.5, -20, -22.5), sequenceCalc.GetSequenceDefault())
		
		Local riseMod:TAudience = TAudience.CreateAndInitValue(1.3)
		Local shrinkMod:TAudience = TAudience.CreateAndInitValue(1.3)		
		Local expected:TAudience = TAudience.CreateAndInit(-2, -4, -6, -8, -10, -12, -14, -16, -18)
		TestAssert.assertEqualsAud(expected, sequenceCalc.GetSequenceDefault(riseMod, shrinkMod))	
		
		riseMod = TAudience.CreateAndInitValue(0.3)
		shrinkMod = TAudience.CreateAndInitValue(0.3)		
		
		'riseMod kann nicht kleiner als 0.8 sein. Wird gecutted.
		expected = TAudience.CreateAndInit(-3.125, -6.25, -9.375, -12.5, -15.625, -18.75, -21.875, -25, -28.125)
		TestAssert.assertEqualsAud(expected, sequenceCalc.GetSequenceDefault(riseMod, shrinkMod))
		
		
		
		
		sequenceCalc.Predecessor = New TAudienceAttraction
		sequenceCalc.Predecessor.BlockAttraction = TAudience.CreateAndInitValue(100)
		sequenceCalc.Predecessor.CalculateFinalAttraction()
		sequenceCalc.Successor.BlockAttraction = TAudience.CreateAndInitValue(0)
		sequenceCalc.Successor.CalculateFinalAttraction()		
		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(50), sequenceCalc.GetSequenceDefault())
		
		sequenceCalc.Predecessor.BlockAttraction = TAudience.CreateAndInit(10, 20, 30, 40, 50, 60, 70, 80, 100)
		sequenceCalc.Predecessor.CalculateFinalAttraction()
		TestAssert.assertEqualsAud(TAudience.CreateAndInit(5, 10, 15, 20, 25, 30, 35, 40, 50), sequenceCalc.GetSequenceDefault())
		
		riseMod = TAudience.CreateAndInitValue(1.5) 'Maximum wird auf 1.3 reduziert
		shrinkMod = TAudience.CreateAndInitValue(1.5) 'Maximum wird auf 1.3 reduziert
		expected = TAudience.CreateAndInit(6.25, 12.5, 18.75, 25, 31.25, 37.50, 43.75, 50, 62.50)
		TestAssert.assertEqualsAud(expected, sequenceCalc.GetSequenceDefault(riseMod, shrinkMod))
		
		riseMod = TAudience.CreateAndInitValue(0.3)
		shrinkMod = TAudience.CreateAndInitValue(0.3)		
		expected = TAudience.CreateAndInit(1.5, 3, 4.5, 6, 7.50000048, 9, 10.5, 12, 15)
		TestAssert.assertEqualsAud(expected, sequenceCalc.GetSequenceDefault(riseMod, shrinkMod))
		
		riseMod = TAudience.CreateAndInitValue(0.1)
		shrinkMod = TAudience.CreateAndInitValue(0.1)
		expected = TAudience.CreateAndInit(1.25, 2.5, 3.75, 5, 6.25, 7.50, 8.75, 10, 12.5)
		TestAssert.assertEqualsAud(expected, sequenceCalc.GetSequenceDefault(riseMod, shrinkMod))
		
		riseMod = TAudience.CreateAndInitValue(2)
		shrinkMod = TAudience.CreateAndInitValue(2)
		expected = TAudience.CreateAndInit(6.25, 12.5, 18.75, 25, 31.25, 37.50, 43.75, 50, 62.50)
		TestAssert.assertEqualsAud(expected, sequenceCalc.GetSequenceDefault(riseMod, shrinkMod))	
	End Method

	Method CalcSequenceCase() { test }	
		Local sequenceCalc:TSequenceCalculation = new TSequenceCalculation		
		sequenceCalc.PredecessorShareOnRise = 0.25
		sequenceCalc.PredecessorShareOnShrink  = 0.5
		
		
		assertEqualsF(-12.50, sequenceCalc.CalcSequenceCase(50, 100, 1, 1), 0, "a")
		assertEqualsF(25, sequenceCalc.CalcSequenceCase(100, 50, 1, 1), 0, "b")
		
		assertEqualsF(-6.25, sequenceCalc.CalcSequenceCase(50, 100, 2, 1), 0, "c")
		assertEqualsF(25, sequenceCalc.CalcSequenceCase(100, 50, 2, 1), 0, "d")
		
		assertEqualsF(-12.5, sequenceCalc.CalcSequenceCase(50, 100, 1, 2), 0, "e")
		assertEqualsF(50, sequenceCalc.CalcSequenceCase(100, 50, 1, 2), 0, "f")
		
		assertEqualsF(-25, sequenceCalc.CalcSequenceCase(50, 100, 0.5, 0.5), 0, "g")
		assertEqualsF(12.5, sequenceCalc.CalcSequenceCase(100, 50, 0.5, 0.5), 0, "h")
		
		assertEqualsF(-8.33333302, sequenceCalc.CalcSequenceCase(50, 100, 1.5, 1.5), 0, "i")
		assertEqualsF(37.5000000, sequenceCalc.CalcSequenceCase(100, 50, 1.5, 1.5), 0, "j")	
	End Method
End Type