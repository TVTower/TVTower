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
		
		Local riseMod:TAudience = TAudience.CreateAndInitValue(1.5)
		Local shrinkMod:TAudience = TAudience.CreateAndInitValue(1.5)		
		Local expected:TAudience = TAudience.CreateAndInit(-1.66666663, -3.33333325, -5, -6.66666651, -8.33333302, -10, -11.6666670, -13.3333330, -15)
		TestAssert.assertEqualsAud(expected, sequenceCalc.GetSequenceDefault(riseMod, shrinkMod))	
		
		riseMod = TAudience.CreateAndInitValue(0.3)
		shrinkMod = TAudience.CreateAndInitValue(0.3)		
		expected = TAudience.CreateAndInit(-2.5, -5, -7.5, -10, -12.5, -15, -17.5, -20, -22.5)
		TestAssert.assertEqualsAud(expected, sequenceCalc.GetSequenceDefault(riseMod, shrinkMod))
		
		
		
		
		sequenceCalc.Predecessor = New TAudienceAttraction
		sequenceCalc.Predecessor.BlockAttraction = TAudience.CreateAndInitValue(100)
		sequenceCalc.Predecessor.CalculateFinalAttraction()
		sequenceCalc.Successor.BlockAttraction = TAudience.CreateAndInitValue(0)
		sequenceCalc.Successor.CalculateFinalAttraction()		
		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(50), sequenceCalc.GetSequenceDefault())
		
		sequenceCalc.Predecessor.BlockAttraction = TAudience.CreateAndInit(10, 20, 30, 40, 50, 60, 70, 80, 90)
		sequenceCalc.Predecessor.CalculateFinalAttraction()
		TestAssert.assertEqualsAud(TAudience.CreateAndInit(5, 10, 15, 20, 25, 30, 35, 40, 45), sequenceCalc.GetSequenceDefault())
		
		riseMod = TAudience.CreateAndInitValue(1.5)
		shrinkMod = TAudience.CreateAndInitValue(1.5)		
		expected = TAudience.CreateAndInit(7.5, 15, 22.5, 30, 37.5, 45, 52.5, 60, 67.5)
		TestAssert.assertEqualsAud(expected, sequenceCalc.GetSequenceDefault(riseMod, shrinkMod))
		
		riseMod = TAudience.CreateAndInitValue(0.3)
		shrinkMod = TAudience.CreateAndInitValue(0.3)		
		expected = TAudience.CreateAndInit(1.5, 3, 4.5, 6, 7.50000048, 9, 10.5, 12, 13.5)
		TestAssert.assertEqualsAud(expected, sequenceCalc.GetSequenceDefault(riseMod, shrinkMod))		
	End Method

	Method CalcSequenceCase() { test }	
		Local sequenceCalc:TSequenceCalculation = new TSequenceCalculation		
		sequenceCalc.PredecessorShareOnRise = 0.25
		sequenceCalc.PredecessorShareOnShrink  = 0.5
		
		
		assertEqualsF(-12.50, sequenceCalc.CalcSequenceCase(50, 100, 1, 1))
		assertEqualsF(25, sequenceCalc.CalcSequenceCase(100, 50, 1, 1))
		
		assertEqualsF(-6.25, sequenceCalc.CalcSequenceCase(50, 100, 2, 1))
		assertEqualsF(25, sequenceCalc.CalcSequenceCase(100, 50, 2, 1))		
		
		assertEqualsF(-12.50, sequenceCalc.CalcSequenceCase(50, 100, 1, 2))
		assertEqualsF(50, sequenceCalc.CalcSequenceCase(100, 50, 1, 2))
		
		assertEqualsF(-12.50, sequenceCalc.CalcSequenceCase(50, 100, 0.5, 0.5))
		assertEqualsF(12.5, sequenceCalc.CalcSequenceCase(100, 50, 0.5, 0.5))	
		
		assertEqualsF(-8.33333302, sequenceCalc.CalcSequenceCase(50, 100, 1.5, 1.5))
		assertEqualsF(37.5000000, sequenceCalc.CalcSequenceCase(100, 50, 1.5, 1.5))			
	End Method
End Type