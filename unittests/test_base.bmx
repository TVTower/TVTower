Type TestAssert Extends TTest
	Function assertEqualsAud(expected:TAudience, actual:TAudience, message:String = Null)	
		assertEqualsI(expected.Id, actual.Id, message + " [-> Id]")
		assertEqualsF(expected.Children, actual.Children, 0.000005, message + " [-> Children]")
		assertEqualsF(expected.Teenagers, actual.Teenagers, 0.000005, message + " [-> Teenagers]")
		assertEqualsF(expected.HouseWifes, actual.HouseWifes, 0.000005, message + " [-> HouseWifes]")
		assertEqualsF(expected.Employees, actual.Employees, 0.000005, message + " [-> Employees]")
		assertEqualsF(expected.Unemployed, actual.Unemployed, 0.000005, message + " [-> Unemployed]")
		assertEqualsF(expected.Manager, actual.Manager, 0.000005, message + " [-> Manager]")
		assertEqualsF(expected.Pensioners, actual.Pensioners, 0.000005, message + " [-> Pensioners]")
		assertEqualsF(expected.Women, actual.Women, 0.000005, message + " [-> Women]")
		assertEqualsF(expected.Men, actual.Men, 0.000005, message + " [-> Men]")
	End Function
	
	Function assertEqualsExceptions(expected:TBlitzException, actual:TBlitzException, message:String = Null)	
		assertEquals(TTypeId.ForObject(expected).Name(), TTypeId.ForObject(actual).Name(), message + " [-> Type]")
		assertEquals(expected.ToString(), actual.ToString(), message + " [-> Type]")
	End Function
End Type

Type TTestKit
	Function SetGame(debugMode:Int=False)
		If debugMode Then
			TDevHelper.setLogMode(LOG_ALL)
			TDevHelper.setPrintMode(LOG_ALL)
		Else
			TDevHelper.setLogMode(0)
			TDevHelper.setPrintMode(0)
		EndIf
		Game = new TGame.Create()
	End Function
	
	Function RemoveGame()
		TGame._instance = null
		TGame._initDone = false
		Game = null
	End Function
	
	Function CrProgrammeData:TProgrammeData(title:String = null, genre:Int = 0, fixQuality:Float = 1, year:Int = 1985)
		Local data:TProgrammeData = TProgrammeData.CreateMinimal(title, genre, fixQuality, year)
		Return data
	End Function
	
	Function CrProgrammeLicence:TProgrammeLicence(title:String = null, genre:Int = 0, licenceType:Int, fixQuality:Float = 1, year:Int = 1985)
		Local data:TProgrammeData = CrProgrammeData(title, genre, fixQuality, year)		
		data.programmeType = licenceType
		Local licence:TProgrammeLicence = TProgrammeLicence.Create(title, "", licenceType)
		licence.AddData(data)
		Return licence
	End Function
	
	Function CrProgrammeSmall:TProgramme(title:String = null, genre:Int = 0, licenceType:Int, fixQuality:Float = 1, year:Int = 1985)
		Local licence:TProgrammeLicence = CrProgrammeLicence(title, genre, licenceType, fixQuality, year)		
		licence.data.genreDefinitionCache = CrMovieGenreDefinition()
		Return TProgramme.Create(licence)
	End Function	
	
	Function CrProgramme:TProgramme(title:String = null, genre:Int = 0, licenceType:Int, fixQuality:Float = 1, genreDef:TMovieGenreDefinition = Null)
		Local licence:TProgrammeLicence = CrProgrammeLicence(title, genre, licenceType, fixQuality)		
		If genreDef Then licence.data.genreDefinitionCache = genreDef
		Return TProgramme.Create(licence)
	End Function
	
	Function CrMovieGenreDefinition:TMovieGenreDefinition(outcomeMod:Float = 0.5, reviewMod:Float = 0.3, speedMod:Float = 0.2 )
		Local definition:TMovieGenreDefinition = New TMovieGenreDefinition
		definition.OutcomeMod = outcomeMod
		definition.ReviewMod = reviewMod
		definition.SpeedMod = speedMod
		Return definition
	End Function	
EndType