Type ProgrammesTest Extends TTest
	Field TestPlayer:TPlayer

	Method InitTest() { before }
		TTestKit.SetGame()		
		TestPlayer = TTestKit.SetPlayer()
	End Method
	
	Method ExitTest() { after }
		TTestKit.RemoveGame()
	End Method

	Method ProgrammeData() { test }		
		Local data:TProgrammeData = TTestKit.CrProgrammeData(Null, 1, 0.5)
		assertEqualsF(0.5, data.outcome)
	End Method
	
	Method ProgrammeLicence() { test }
		Local licence:TProgrammeLicence = TTestKit.CrProgrammeLicence(Null, 1, TVTProgrammeLicenceType.SINGLE, 0.5)			
		assertTrue(licence.isSingle())
	End Method
	
	Method ProgrammeTopicality() { test }
		Local programme:TProgramme = TTestKit.CrProgrammeSmall("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5)		
		assertEqualsF(1.0, programme.data.GetMaxTopicality(), 0.006)

		'5 years old... (1985 - 1980)
		programme = TTestKit.CrProgrammeSmall("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, 1980)
		assertEqualsF(0.95, programme.data.GetMaxTopicality(), 0.006)
		assertEqualsF(0.95, programme.data.GetTopicality(), 0.006)
		
		'=== Zusätzlicher Topicality-Faktor hängt von der Zuschauerquote ab ===
		assertEqualsF(1.0, programme.GetTopicalityCutModifier(0), 0.0005)
		assertEqualsF(0.8239, programme.GetTopicalityCutModifier(0.2), 0.0005)
		
		'=== Senken der Topicality ===
		Local progDataCollection:TProgrammeDataCollection = GetProgrammeDataCollection()
		assertEqualsF(0.85, progDataCollection.wearoffFactor, 0.0005)
		assertEqualsF(1, programme.data.GetGenreWearoffModifier(), 0.0005)
		assertEqualsF(1, programme.data.GetWearoffModifier(), 0.0005)				
		programme.data.CutTopicality(programme.GetTopicalityCutModifier(0.5))		
		assertEqualsF(0.4976, programme.data.GetTopicality(), 0.0005)
		programme.data.CutTopicality(programme.GetTopicalityCutModifier(0.5))		
		assertEqualsF(0.2607, programme.data.GetTopicality(), 0.0005)	
		programme.data.CutTopicality(programme.GetTopicalityCutModifier(0.5))		
		assertEqualsF(0.1366, programme.data.GetTopicality(), 0.0005)
		
		'=== Refresh der Topicality ===
		
		assertEqualsF(1.5, progDataCollection.refreshFactor, 0.0005)
		assertEqualsF(1, programme.data.GetGenreRefreshModifier(), 0.0005)
		assertEqualsF(1, programme.data.GetRefreshModifier(), 0.0005)			
		GetProgrammeDataCollection().RefreshTopicalities()		
		assertEqualsF(0.2048, programme.data.GetTopicality(), 0.0005)
		GetProgrammeDataCollection().RefreshTopicalities()		
		assertEqualsF(0.3073, programme.data.GetTopicality(), 0.0005)
		GetProgrammeDataCollection().RefreshTopicalities()		
		assertEqualsF(0.4609, programme.data.GetTopicality(), 0.0005)
		
		'=== Extreme Jahrgänge ===
				
		programme = TTestKit.CrProgrammeSmall("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, 1975)
		assertEqualsF(0.90, programme.data.GetMaxTopicality(), 0.006)	

		programme = TTestKit.CrProgrammeSmall("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, 1970)
		assertEqualsF(0.85, programme.data.GetMaxTopicality(), 0.006)		
		
		programme = TTestKit.CrProgrammeSmall("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, 1935)
		assertEqualsF(0.5, programme.data.GetMaxTopicality(), 0.006)				

		programme = TTestKit.CrProgrammeSmall("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, 1885)
		assertEqualsF(0.01, programme.data.GetMaxTopicality(), 0.006)
		
		programme = TTestKit.CrProgrammeSmall("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, 1990)
		assertEqualsF(1.0, programme.data.GetMaxTopicality(), 0.006)		
		
		programme = TTestKit.CrProgrammeSmall("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5)
		programme.licence.data.SetTimesAired(1, 1)
		assertEqualsF(0.96, programme.data.GetMaxTopicality(), 0.006)			

		programme = TTestKit.CrProgrammeSmall("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5)
		programme.licence.data.SetTimesAired(2, 1)
		assertEqualsF(0.92, programme.data.GetMaxTopicality(), 0.006)			
		
		programme = TTestKit.CrProgrammeSmall("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5)
		programme.licence.data.SetTimesAired(100, 1)
		assertEqualsF(0.6, programme.data.GetMaxTopicality(), 0.006)					
	End Method
	
	Method ProgrammeQuality() { test }
		Local programme:TProgramme = TTestKit.CrProgrammeSmall("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5)		
		assertEquals("abc", programme.GetTitle())
		assertEqualsF(1.0, programme.data.GetMaxTopicality(), 0.006)
		assertEqualsF(0.50, programme.GetQuality(), 0.006)
		
		
		programme = TTestKit.CrProgrammeSmall("abc2", 0, TVTProgrammeLicenceType.SINGLE)
		programme.licence.data.Outcome = 0.20
		programme.licence.data.review = 0.40
		programme.licence.data.speed = 0.60
		
		assertEqualsF(0.34, programme.data.GetQualityRaw(), 0.006)
		assertEqualsF(0.34, programme.GetQuality(), 0.006)
		
		
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition(1, 0, 0.5, 0.5)
		programme = TTestKit.CrProgramme("abc2", 0, TVTProgrammeLicenceType.SINGLE, 1, genreDef)
		programme.licence.data.Outcome = 0.20
		programme.licence.data.review = 0.40
		programme.licence.data.speed = 0.60
		assertEqualsF(0.50, programme.data.GetQualityRaw(), 0.006)
		assertEqualsF(0.50, programme.GetQuality(), 0.006)
		
		'Mod durch Alter
		programme = TTestKit.CrProgrammeSmall("abc3", 0, TVTProgrammeLicenceType.SINGLE, 0.5, 1980)
		assertEqualsF(0.50, programme.data.GetQualityRaw(), 0.006)
		assertEqualsF(0.4287, programme.GetQuality(), 0.0005)
		
		'Extremes Alter
		programme = TTestKit.CrProgrammeSmall("abc3", 0, TVTProgrammeLicenceType.SINGLE, 0.5, 1870)
		'DebugStop
		assertEqualsF(0.50, programme.data.GetQualityRaw(), 0.006)
		assertEqualsF(0.01, programme.GetQuality(), 0.006)		
	End Method	

	Method GetAudienceAttraction() { test }
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, genreDef)
		
		programme.owner = 0
		'Falsch-Angaben
		Try
			programme.GetAudienceAttraction(0, 1, Null, Null)
			fail("No Exception")
		Catch ex:TBlitzException 'Alles gut			
			assertEquals("The programme 'abc' has no owner.", ex.ToString())
		Catch ex:Object 'falsche excpetion			
			fail("Wrong Exception: " + ex.ToString())
		End Try			
		
		programme.owner = 1	
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.625), programme.GetAudienceAttraction(0, 1, Null, Null))

		'Trailer: TODO
		
		'Flags: TODO
	End Method
	
	Method GetAudienceAttraction_Popularity() { test }
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, genreDef)		
		
		genreDef.Popularity.Popularity = +25
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.75), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		genreDef.Popularity.Popularity = -25
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.50), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		genreDef.Popularity.Popularity = +250 'Eigentliches maximum 50
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.875), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		genreDef.Popularity.Popularity = -250 'Eigentliches minimum 50
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.375), programme.GetAudienceAttraction(0, 1, Null, Null))		
	End Method
	
	Method GetAudienceAttraction_AudienceAttraction() { test }
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, genreDef)
		
		genreDef.Popularity.Popularity = 0
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(0)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.50), programme.GetAudienceAttraction(0, 1, Null, Null), "x1")
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(1)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.75), programme.GetAudienceAttraction(0, 1, Null, Null), "x2")

		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(2)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.80), programme.GetAudienceAttraction(0, 1, Null, Null), "x3")
		
		genreDef.AudienceAttraction = TAudience.CreateAndInit(0, 0.1, 0.3, 0.4, 0.5, 0.6, 0.7, 0.9, 1) 
		Local expected:TAudience = TAudience.CreateAndInit(0.5, 0.525, 0.575, 0.6, 0.625, 0.65, 0.675, 0.725, 0.75) 
		TestAssert.assertEqualsAud(expected, programme.GetAudienceAttraction(0, 1, Null, Null))		
		
		'Popularity & AudienceAttraction
		
		genreDef.Popularity.Popularity = +250 'Eigentliches maximum 50
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(2)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(0, 1, Null, Null))		
	End Method
	
	Method GetAudienceAttraction_PublicImage() { test }
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, genreDef)
		
		genreDef.Popularity.Popularity = 0
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(0.5)		
		
		Local publicImage:TPublicImage = GetPublicImageCollection().Get(TestPlayer.playerID)
		
		publicImage.ImageValues = TAudience.CreateAndInitValue(0)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.625), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		publicImage.ImageValues = TAudience.CreateAndInitValue(100)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.8), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		publicImage.ImageValues = TAudience.CreateAndInitValue(150)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.8), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		publicImage.ImageValues = TAudience.CreateAndInitValue(-50)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.5375), programme.GetAudienceAttraction(0, 1, Null, Null))
	End Method
	
	Method GetAudienceAttraction_QualityOverTimeEffectMod() { test }
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, genreDef)
		
		Local publicImage:TPublicImage = GetPublicImageCollection().Get(TestPlayer.playerID)
		publicImage.ImageValues = TAudience.CreateAndInitValue(100)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.8), programme.GetAudienceAttraction(0, 2, Null, Null))
		
		programme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.25, genreDef)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.4), programme.GetAudienceAttraction(0, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.4), programme.GetAudienceAttraction(4, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.4), programme.GetAudienceAttraction(8, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.4), programme.GetAudienceAttraction(12, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.4), programme.GetAudienceAttraction(16, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.4), programme.GetAudienceAttraction(20, 1, Null, Null))
		
		programme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.75, genreDef)		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(0, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(4, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(8, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(12, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(16, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(20, 1, Null, Null))		
		
		programme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 1, genreDef)		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(0, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(4, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(8, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(12, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(16, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.0), programme.GetAudienceAttraction(20, 1, Null, Null))		
	End Method		
	
	Method GetAudienceAttraction_Sequence() { test }
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()	
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, genreDef)		
		
		programme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 1, genreDef)		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1), programme.GetAudienceAttraction(0, 1, Null, Null, True))		
		
		Local newsAttraction:TAudienceAttraction = new TAudienceAttraction
		newsAttraction.FinalAttraction = TAudience.CreateAndInitValue(1)		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1), programme.GetAudienceAttraction(0, 1, Null, newsAttraction, True))			
		
		newsAttraction.FinalAttraction = TAudience.CreateAndInitValue(0.5)		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1), programme.GetAudienceAttraction(0, 1, Null, newsAttraction, True))		
						
		
		
		programme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, genreDef)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.4867), programme.GetAudienceAttraction(0, 1, Null, Null, True))
		
		newsAttraction.FinalAttraction = TAudience.CreateAndInitValue(1)		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.76057), programme.GetAudienceAttraction(0, 1, Null, newsAttraction, True))	
		
		newsAttraction.FinalAttraction = TAudience.CreateAndInitValue(0.5)		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.59734), programme.GetAudienceAttraction(0, 1, Null, newsAttraction, True))							
	End Method
	
	Method GetAudienceAttraction_SequenceAndFlow() { test }
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()	
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, genreDef)		
		Local newsAttraction:TAudienceAttraction = new TAudienceAttraction
	
		'Sequence - AudienceFlow - Steigend
		Local lastMovieGenreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local lastMovie:TProgramme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, lastMovieGenreDef)		
		Local lastMovieAttr:TAudienceAttraction = lastMovie.GetAudienceAttraction(0, 1, Null, Null)
		newsAttraction.SetFixAttraction(TAudience.CreateAndInitValue(0.5))		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.63287), programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True))		

		
		'lastMovie = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, lastMovieGenreDef)		
		'lastMovieAttr = lastMovie.GetAudienceAttraction(0, 1, Null, Null)		
		
		'Vorgängersendung 0.5 -> Nachrichten 0.5 -> Folgende Sendung 1.0

		'Perfekter AudienceFlow 0.5 -> 1 -> 0.5		
		newsAttraction.SetFixAttraction(TAudience.CreateAndInitValue(1))		
		genreDef.GenreId = 1
		'DebugStop
		Local actual:TAudienceAttraction = programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.045625), actual.AudienceFlowBonus)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.089311), actual.SequenceEffect)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.759936), actual)		

		'Guter AudienceFlow 0.5 -> 1 -> 0.5
		genreDef.GenreId = 2
		lastMovieGenreDef.GoodFollower.AddLast("2")
		actual = programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.03193), actual.AudienceFlowBonus)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.09302), actual.SequenceEffect)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.74996), actual)					
				
		'Normaler AudienceFlow 0.5 -> 1 -> 0.5 
		genreDef.GenreId = 3
		actual = programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.01596), actual.AudienceFlowBonus)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.09735), actual.SequenceEffect)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.73832), actual)	
		
		'Schlechter AudienceFlow 0.5 -> 1 -> 0.5
		genreDef.GenreId = 4
		lastMovieGenreDef.BadFollower.AddLast("4")				
		actual = programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.00456), actual.AudienceFlowBonus)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.10044), actual.SequenceEffect)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.73000), actual)


		lastMovie = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 1, lastMovieGenreDef)		
		lastMovieAttr = lastMovie.GetAudienceAttraction(0, 1, Null, Null)
				
		
		'Perfekter AudienceFlow 1 -> 1 -> 0.5
		genreDef.GenreId = 1
		actual = programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.25664), actual.AudienceFlowBonus)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.03209), actual.SequenceEffect)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.91373), actual)	

		'Guter AudienceFlow 1 -> 1 -> 0.5
		genreDef.GenreId = 2
		lastMovieGenreDef.GoodFollower.AddLast("2")
		actual = programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.17965), actual.AudienceFlowBonus)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.05297), actual.SequenceEffect)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.85762), actual)					
				
		'Normaler AudienceFlow 1 -> 1 -> 0.5
		genreDef.GenreId = 3
		actual = programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.08982), actual.AudienceFlowBonus)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.07732), actual.SequenceEffect)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.79215), actual)	
		
		'Schlechter AudienceFlow 1 -> 1 -> 0.5
		genreDef.GenreId = 4
		lastMovieGenreDef.BadFollower.AddLast("4")				
		actual = programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.02566), actual.AudienceFlowBonus)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.09472), actual.SequenceEffect)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.74538), actual)		
		
		
		
		'Perfekter AudienceFlow 1 -> 1 -> 0.5 , ABER scheiß News
		newsAttraction.SetFixAttraction(TAudience.CreateAndInitValue(0.2))
		genreDef.GenreId = 1
		actual = programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.04562), actual.AudienceFlowBonus)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(-0.10414), actual.SequenceEffect)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.56649), actual)	
		
		'Schlechter AudienceFlow 1 -> 1 -> 0.5  UND scheiß News
		genreDef.GenreId = 4
		lastMovieGenreDef.BadFollower.AddLast("4")				
		actual = programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.00456), actual.AudienceFlowBonus)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(-0.09505), actual.SequenceEffect)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.53451), actual)	
		
		newsAttraction.SetFixAttraction(TAudience.CreateAndInitValue(1))
	
		'Sequence - AudienceFlow - Steigend		
	End Method
	
	Method GetAudienceFlowMod() { test }
		Local newsAttraction:TAudienceAttraction = new TAudienceAttraction
		newsAttraction.SetFixAttraction(TAudience.CreateAndInitValue(1))
		
		Local lastMovieGenreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local lastMovie:TProgramme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 1, lastMovieGenreDef)		
		Local lastMovieAttr:TAudienceAttraction = lastMovie.GetAudienceAttraction(0, 1, Null, Null)
		lastMovieGenreDef.GoodFollower.AddLast("2")
		lastMovieGenreDef.BadFollower.AddLast("4")
							
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TVTProgrammeLicenceType.SINGLE, 0.5, genreDef)
		Local programmeAttr:TAudienceAttraction = programme.GetAudienceAttraction(0, 1, Null, Null)		
		
		'Perfekter Match
		genreDef.GenreId = 1
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1), lastMovieGenreDef.GetAudienceFlowMod(genreDef), "p1")
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.25664), TProgramme.GetAudienceFlowBonusIntern(lastMovieAttr, programmeAttr, newsAttraction), "p1")
				
		'Guter Follower		
		genreDef.GenreId = 2
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.7), lastMovieGenreDef.GetAudienceFlowMod(genreDef), "p1")
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.17965), TProgramme.GetAudienceFlowBonusIntern(lastMovieAttr, programmeAttr, newsAttraction ), "g1")
		
		'Normaler Follower	
		genreDef.GenreId = 3
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.35), lastMovieGenreDef.GetAudienceFlowMod(genreDef), "p1")	
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.08982), TProgramme.GetAudienceFlowBonusIntern(lastMovieAttr, programmeAttr, newsAttraction ), "n1")
		
		'Schlechter Follower
		genreDef.GenreId = 4		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.1), lastMovieGenreDef.GetAudienceFlowMod(genreDef), "p1")
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.02566), TProgramme.GetAudienceFlowBonusIntern(lastMovieAttr, programmeAttr, newsAttraction), "b1")
	End Method
End Type