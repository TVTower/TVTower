Type TAudienceTest Extends TTest
	Method CreateAndInit() { test }
		Local audience:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )

		assertEqualsI(0, audience.Id)
		assertEqualsF(100, audience.Children)
		assertEqualsF(200, audience.Teenagers)
		assertEqualsF(300, audience.HouseWifes)
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
		assertEqualsF(300, audience.HouseWifes)
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
		
		audience.HouseWifes = 2000
		audience.CalcGenderBreakdown()
		assertEqualsAud(TAudience.CreateAndInit(1000, 1000, 2000, 1000, 1000, 1000, 1000, 4400, 3600 ), audience)		
	End Method
	
	Method FixGenderCount() { test }
		Local audience:TAudience = TAudience.CreateAndInitValue(100)
		assertEqualsF(100, audience.Women )
		assertEqualsF(100, audience.Men)
		
		audience.Employees = 300 
		audience.HouseWifes = 200
		
		Local expected:TAudience = audience.Copy()
		expected.Women = 500
		expected.Men = 500		
		
		audience.FixGenderCount()
		
		assertEqualsAud(expected, audience)	
	End Method
	
	Method GetByTargetID() { test }
		Local audience:TAudience = TAudience.CreateAndInit(100, 200, 300, 400, 500, 600, 700, 800, 900 )
		
		'Falsch-Angaben
		Try
			audience.GetByTargetID(0)	
			fail("No Exception")
		Catch ex:TArgumentException 'Alles gut			
			assertEqualsExceptions(TArgumentException.Create("targetID", "0"), ex)
		Catch ex:Object 'falsche excpetion			
			fail("Wrong Exception: " + ex.ToString())
		End Try		
		
		'Falsch-Angaben
		Try
			audience.GetByTargetID(10)	
			fail("No Exception")
		Catch ex:TArgumentException 'Alles gut			
			assertEqualsExceptions(TArgumentException.Create("targetID", "10"), ex)
		Catch ex:Object 'falsche excpetion			
			fail("Wrong Exception: " + ex.ToString())
		End Try			
		
		assertEqualsI(100, audience.GetByTargetID(1))
		assertEqualsI(200, audience.GetByTargetID(2))
		assertEqualsI(300, audience.GetByTargetID(3))
		assertEqualsI(400, audience.GetByTargetID(4))
		assertEqualsI(500, audience.GetByTargetID(5))
		assertEqualsI(600, audience.GetByTargetID(6))
		assertEqualsI(700, audience.GetByTargetID(7))
		assertEqualsI(800, audience.GetByTargetID(8))
		assertEqualsI(900, audience.GetByTargetID(9))		
	End Method
	
	Method assertEqualsAud(expected:TAudience, actual:TAudience, message:String = Null)	
		assertEqualsI(expected.Id, actual.Id, message + " [-> Id]")
		assertEqualsF(expected.Children, actual.Children, 0, message + " [-> Children]")
		assertEqualsF(expected.Teenagers, actual.Teenagers, 0, message + " [-> Teenagers]")
		assertEqualsF(expected.HouseWifes, actual.HouseWifes, 0, message + " [-> HouseWifes]")
		assertEqualsF(expected.Employees, actual.Employees, 0, message + " [-> Employees]")
		assertEqualsF(expected.Unemployed, actual.Unemployed, 0, message + " [-> Unemployed]")
		assertEqualsF(expected.Manager, actual.Manager, 0, message + " [-> Manager]")
		assertEqualsF(expected.Pensioners, actual.Pensioners, 0, message + " [-> Pensioners]")
		assertEqualsF(expected.Women, actual.Women, 0, message + " [-> Women]")
		assertEqualsF(expected.Men, actual.Men, 0, message + " [-> Men]")
	End Method
	
	Method assertEqualsExceptions(expected:TBlitzException, actual:TBlitzException, message:String = Null)	
		assertEquals(TTypeId.ForObject(expected).Name(), TTypeId.ForObject(actual).Name(), message + " [-> Type]")
		assertEquals(expected.ToString(), actual.ToString(), message + " [-> Type]")
	End Method	
End Type