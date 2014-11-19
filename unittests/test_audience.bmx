Type TAudienceTest Extends TTest
	Method CreateAndInit() { test }
		Local audience:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )

		assertEqualsI(0, audience.Id)
		assertEqualsF(100, audience.Children)
		assertEqualsF(200, audience.Teenagers)
		assertEqualsF(300, audience.HouseWives)
		assertEqualsF(400, audience.Employees)
		assertEqualsF(500, audience.Unemployed)
		assertEqualsF(600, audience.Manager)
		assertEqualsF(700, audience.Pensioners)
		assertEqualsF(800, audience.Women)
		assertEqualsF(900, audience.Men)
		
		audience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700 )

		assertEqualsI(0, audience.Id)
		assertEqualsF(100, audience.Children)
		assertEqualsF(200, audience.Teenagers)
		assertEqualsF(300, audience.HouseWives)
		assertEqualsF(400, audience.Employees)
		assertEqualsF(500, audience.Unemployed)
		assertEqualsF(600, audience.Manager)
		assertEqualsF(700, audience.Pensioners)
		assertEqualsF(1315, audience.Women)
		assertEqualsF(1485, audience.Men)			
	End Method

	Method CreateWithBreakdown() { test }
		Local audience:TAudience = TAudience.CreateWithBreakdown(1000)
		assertEqualsAud(TAudience.CreateAndInit(90, 100, 120, 405, 45, 30, 210, 506, 494 ), audience)
	End Method

	Method CreateAndInitValue() { test }
		Local audience:TAudience = TAudience.CreateAndInitValue(10.5)
		assertEqualsAud(TAudience.CreateAndInit(10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5 ), audience)
	End Method
	
	Method Copy() { test }
		Local audience:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )
		audience.Id = 3
		
		Local locCopy:TAudience = audience.Copy()
		
		assertNotSame(audience, locCopy)
		assertEqualsAud(audience, locCopy)
	End Method
	
	Method SetValuesFrom() { test }
		Local audience:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )
		audience.Id = 3
		
		Local locCopy:TAudience = new TAudience
		locCopy.SetValuesFrom(audience)
		
		assertEqualsI(0, locCopy.Id)
		locCopy.Id = 3
		
		assertNotSame(audience, locCopy)
		assertEqualsAud(audience, locCopy)
	End Method
	
	Method SetValues() { test }
		Local audience:TAudience = new TAudience.SetValues(100, 200, 300, 400, 500, 600, 700, 800, 900)
		assertEqualsAud(TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 ), audience)		
	End Method
	
	Method GetAverage() { test }
		Local audience:TAudience = TAudience.CreateAndInitValue(11.5)
		assertEqualsF(11.5, audience.GetAverage())
	End Method
	
	Method CalcGenderBreakdown() { test }
		Local audience:TAudience = TAudience.CreateAndInitValue(1000)
		audience.CalcGenderBreakdown()
		assertEqualsAud(TAudience.CreateAndInit(1000, 1000, 1000, 1000, 1000, 1000, 1000, 3500, 3500 ), audience)
		
		audience.HouseWives = 2000
		audience.CalcGenderBreakdown()
			
	End Method
	
	Method FixGenderCount() { test }
		Local audience:TAudience = TAudience.CreateAndInitValue(100)
		assertEqualsF(100, audience.Women )
		assertEqualsF(100, audience.Men)
		
		audience.Employees = 300 
		audience.HouseWives = 200
		
		Local expected:TAudience = audience.Copy()
		expected.Women = 500
		expected.Men = 500		
		
		audience.FixGenderCount()
		
		assertEqualsAud(expected, audience)	
	End Method
	
	Method CutMinimum() { test }
		Local audience:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )
		audience.CutMinimumFloat(480)				
		assertEqualsAud(TAudience.CreateAndInit(480, 480, 480, 480, 500, 600, 700, 800, 900 ), audience)	
	End Method	
	
	Method CutMaximum() { test }
		Local audience:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )
		audience.CutMaximumFloat(480)				
		assertEqualsAud(TAudience.CreateAndInit(100, 200, 300, 400, 480, 480, 480, 480, 480 ), audience)	
	End Method
	
	Method GetValue() { test }
		Local audience:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )
		
		'Falsch-Angaben
		Try
			audience.GetValue(0)	
			fail("No Exception")
		Catch ex:TArgumentException 'Alles gut			
			assertEqualsExceptions(TArgumentException.Create("targetID", "0"), ex)
		Catch ex:Object 'falsche excpetion			
			fail("Wrong Exception: " + ex.ToString())
		End Try		
		
		'Falsch-Angaben
		Try
			audience.GetValue(10)	
			fail("No Exception")
		Catch ex:TArgumentException 'Alles gut			
			assertEqualsExceptions(TArgumentException.Create("targetID", "10"), ex)
		Catch ex:Object 'falsche excpetion			
			fail("Wrong Exception: " + ex.ToString())
		End Try			

		for local i:int = 1 to 9
			assertEqualsI(i*100, audience.GetValue(TVTTargetGroup.GetGroupID(i)))
		Next
	End Method
	
	Method SetValue() { test }
		Local audience:TAudience = new TAudience
					
		'Falsch-Angaben
		Try
			audience.SetValue(0, 100)
			fail("No Exception")
		Catch ex:TArgumentException 'Alles gut			
			assertEqualsExceptions(TArgumentException.Create("targetID", "0"), ex)
		Catch ex:Object 'falsche excpetion			
			fail("Wrong Exception: " + ex.ToString())
		End Try		
		
		'Falsch-Angaben
		Try
			audience.SetValue(10, 100)
			fail("No Exception")
		Catch ex:TArgumentException 'Alles gut			
			assertEqualsExceptions(TArgumentException.Create("targetID", "10"), ex)
		Catch ex:Object 'falsche excpetion			
			fail("Wrong Exception: " + ex.ToString())
		End Try			
		
		for local i:int = 1 to 9
			audience.SetValue(TVTTargetGroup.GetGroupID(i), i*100)
		Next
		assertEqualsAud(TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 ), audience)
	End Method	
	
	Method GetSum() { test }
		Local audience:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )
		assertEqualsF(2800, audience.GetSum())	
	End Method
	
	Method MathFloat() { test }
		Local audience:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )
		audience.AddFloat(50)
		assertEqualsAud(TAudience.CreateAndInit(150, 250, 350, 450, 550, 650, 750, 850, 950 ), audience)
		audience.SubtractFloat(50)
		assertEqualsAud(TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 ), audience)		
		audience.MultiplyFloat(2)
		assertEqualsAud(TAudience.CreateAndInit(200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800 ), audience)
		audience.DivideFloat(2)
		assertEqualsAud(TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 ), audience)		
	End Method
	
	Method MathAudience() { test }
		Local audience:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )
		audience.Add(TAudience.CreateAndInit(1, 2, 3, 4, 5, 6, 7, 8, 9 ))
		assertEqualsAud(TAudience.CreateAndInit(101, 202, 303, 404, 505, 606, 707, 808, 909 ), audience)
		audience.Subtract(TAudience.CreateAndInit(1, 2, 3, 4, 5, 6, 7, 8, 9 ))
		assertEqualsAud(TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 ), audience)
		audience.Multiply(TAudience.CreateAndInit(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9 ))
		assertEqualsAud(TAudience.CreateAndInit(10, 40, 90, 160, 250, 360, 490, 640, 810 ), audience)
		audience.Divide(TAudience.CreateAndInit(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9 ))
		assertEqualsAud(TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 ), audience)		
	End Method
	
	Method Round() { test }
		Local audience:TAudience = TAudience.CreateAndInit(1.34, 2.4999, 2.50000000, 0, 0.444, 0.494949494, 1, 1.1, 1.5 )
		audience.Round()
		assertEqualsAud(TAudience.CreateAndInit(1, 2, 3, 0, 0, 0, 1, 1, 2 ), audience)
	End Method
	
	Method ToNumberSortMap() { test }
		Local audience:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )
		local aList:TNumberSortMap = audience.ToNumberSortMap(False)
		
		'Falsch-Angaben
		Try
			aList.NumberAtIndex(-1)
			fail("No Exception")
		Catch ex:TBlitzException 'Alles gut			
			assertEquals("Object index must be positive", ex.ToString())
		Catch ex:Object 'falsche excpetion			
			fail("Wrong Exception: " + ex.ToString())
		End Try			
		
		'Falsch-Angaben
		Try
			aList.NumberAtIndex(10)
			fail("No Exception")
		Catch ex:TBlitzException 'Alles gut			
			assertEquals("List index out of range", ex.ToString())
		Catch ex:Object 'falsche excpetion			
			fail("Wrong Exception: " + ex.ToString())
		End Try			
		
		assertEqualsI(7, aList.Content.Count())
		assertEqualsF(100, aList.NumberAtIndex(0))
		assertEqualsF(200, aList.NumberAtIndex(1))
		assertEqualsF(300, aList.NumberAtIndex(2))
		assertEqualsF(400, aList.NumberAtIndex(3))
		assertEqualsF(500, aList.NumberAtIndex(4))
		assertEqualsF(600, aList.NumberAtIndex(5))
		assertEqualsF(700, aList.NumberAtIndex(6))
		
		audience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )
		aList = audience.ToNumberSortMap(True)		
		assertEqualsI(9, aList.Content.Count())
		assertEqualsF(800, aList.NumberAtIndex(7))
		assertEqualsF(900, aList.NumberAtIndex(8))		
	End Method
	
	Method InnerSort() { test }
		Local audience1:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )
		Local audience2:TAudience = TAudience.CreateAndInit(99, 199, 299, 399, 499, 599, 699, 799, 899 )
		Local audience3:TAudience = TAudience.CreateAndInit(101, 201, 301, 401, 501, 601, 701, 801, 901 )
		
		Local tempList:TList = CreateList()
		tempList.AddLast(audience1)
		tempList.AddLast(audience2)
		tempList.AddLast(audience3)
		SortList(tempList,False,TAudience.ChildrenSort)
		
		assertEqualsI(0, TAudience.InnerSort(1, audience1, audience1))
		assertTrue(0 < TAudience.InnerSort(1, audience1, audience2))
		assertTrue(0 > TAudience.InnerSort(1, audience1, audience3))

		assertEqualsF(101, TAudience(tempList.ValueAtIndex(0)).Children)
		assertEqualsF(100, TAudience(tempList.ValueAtIndex(1)).Children)
		assertEqualsF(99, TAudience(tempList.ValueAtIndex(2)).Children)
	End Method
	
	Method assertEqualsAud(expected:TAudience, actual:TAudience, message:String = Null)	
		TestAssert.assertEqualsAud(expected, actual, message)
	End Method
	
	Method assertEqualsExceptions(expected:TBlitzException, actual:TBlitzException, message:String = Null)	
		TestAssert.assertEqualsExceptions(expected, actual, message)	
	End Method	
End Type