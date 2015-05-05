Type TestAssert Extends TTest
	Function assertEqualsAud(expected:TAudience, actual:TAudience, message:String = Null)	
		assertEqualsI(expected.Id, actual.Id, message + " [-> Id]")
		assertEqualsF(expected.Children, actual.Children, 0.000005, message + " [-> Children]")
		assertEqualsF(expected.Teenagers, actual.Teenagers, 0.000005, message + " [-> Teenagers]")
		assertEqualsF(expected.HouseWives, actual.HouseWives, 0.000005, message + " [-> HouseWives]")
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
			TLogger.setLogMode(LOG_ALL)
			TLogger.setPrintMode(LOG_ALL)
		Else
			TLogger.setLogMode(0)
			TLogger.setPrintMode(0)
		EndIf
		
		App = TApp.Create(30, -1, True, False) 'create with screen refreshrate and vsync
		'App.LoadResources("config/resources.xml")		
		
		Game = new TGame.Create(False)
	End Function
	
	Function RemoveGame()
		TGame._instance = null
		TGame._initDone = false
		Game = null
	End Function
	
	Function SetPlayer:TPlayer()
		Local player:TPlayer = new TPlayer
		player.playerID = 1
		player.Name = "Test"
		TPublicImage.Create(player.GetPlayerID())
		GetPlayerCollection().Set(1, player)
		Return player
	End Function
	
	Function CrProgrammeData:TProgrammeData(title:String = null, genre:Int = 0, fixQuality:Float = 1, year:Int = 1985)
		Local localizedTitle:TLocalizedString = new TLocalizedString.Set(title)
		'Local data:TProgrammeData = TProgrammeData.CreateMinimal(localizedTitle, genre, fixQuality, year)
		Local data:TProgrammeData = TProgrammeData.Create("", localizedTitle, localizedTitle, null, "DE", year, 0, -1, fixQuality, fixQuality, fixQuality, null, genre, 1, False, TVTProgrammeProductType.MOVIE)
	
		Return data
	End Function
	
	Function CrProgrammeLicence:TProgrammeLicence(title:String = null, genre:Int = 0, licenceType:Int, fixQuality:Float = 1, year:Int = 1985)
		Local data:TProgrammeData = CrProgrammeData(title, genre, fixQuality, year)		
		Local licence:TProgrammeLicence = new TProgrammeLicence
		licence.SetData(data)
		licence.licenceType = licenceType
		Return licence
	End Function
	
	Function CrProgrammeSmall:TProgramme(title:String = null, genre:Int = 0, licenceType:Int = 8, fixQuality:Float = 1, year:Int = 1985)
		Local licence:TProgrammeLicence = CrProgrammeLicence(title, genre, licenceType, fixQuality, year)		
		licence.data.genreDefinitionCache = CrMovieGenreDefinition()
		Return TProgramme.Create(licence)
	End Function	
	
	Function CrProgramme:TProgramme(title:String = null, genre:Int = 0, licenceType:Int, fixQuality:Float = 1, genreDef:TMovieGenreDefinition = Null)
		Local licence:TProgrammeLicence = CrProgrammeLicence(title, genre, licenceType, fixQuality)		
		If genreDef Then licence.data.genreDefinitionCache = genreDef
		Local programme:TProgramme = TProgramme.Create(licence)
		programme.owner = 1
		Return programme
	End Function
	
	Function CrMovieGenreDefinition:TMovieGenreDefinition(id:Int = 1, outcomeMod:Float = 0.5, reviewMod:Float = 0.3, speedMod:Float = 0.2 )
		Local definition:TMovieGenreDefinition = New TMovieGenreDefinition
		definition.GenreId = id
		definition.OutcomeMod = outcomeMod
		definition.ReviewMod = reviewMod
		definition.SpeedMod = speedMod
		definition.Popularity = New TGenrePopularity
		definition.AudienceAttraction = TAudience.CreateAndInitValue(0.5)
		definition.TimeMods = definition.TimeMods[..24]
		For Local i:Int = 0 To 23
			definition.TimeMods[i] = 1.0
		Next
		Return definition
	End Function
	
	Function CrAudienceMarketCalculation:TAudienceMarketCalculation(audience:Int, player1:Int = True)
		Local market:TAudienceMarketCalculation = New TAudienceMarketCalculation
		market.maxAudience = TAudience.CreateWithBreakdown(audience)
		market.AddPlayer(player1)		
		Return market
	End Function
EndType