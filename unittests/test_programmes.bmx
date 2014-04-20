Type ProgrammesTest Extends TTest

	Method InitTest() { before }
		TTestKit.SetGame()
	End Method
	
	Method ExitTest() { after }
		TTestKit.RemoveGame()
	End Method

	Method ProgrammeData() { test }
		Local data:TProgrammeData = TTestKit.CrProgrammeData(Null, 1, 0.5)
		assertEqualsI(127, data.outcome)
	End Method
	
	Method ProgrammeLicence() { test }
		Local licence:TProgrammeLicence = TTestKit.CrProgrammeLicence(Null, 1, TProgrammeLicence.TYPE_MOVIE, 0.5)			
		assertTrue(licence.isMovie())
	End Method
	
	Method ProgrammeTopicality() { test }
		Local programme:TProgramme = TTestKit.CrProgrammeSmall("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5)		
		assertEqualsF(255, programme.data.GetMaxTopicality(), 0.006)
		
		programme = TTestKit.CrProgrammeSmall("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, 1980)
		assertEqualsF(245, programme.data.GetMaxTopicality(), 0.006)
		assertEqualsF(245, programme.data.GetTopicality(), 0.006)
		
		'=== Zusätzlicher Topicality-Faktor hängt von der Zeit ab ===
		
		assertEqualsF(1.35, programme.GetTopicalityCutModifier(), 0.006)
		assertEqualsF(1.35, programme.GetTopicalityCutModifier(1), 0.006)
		assertEqualsF(1.2, programme.GetTopicalityCutModifier(8), 0.006)
		assertEqualsF(1, programme.GetTopicalityCutModifier(18), 0.006)
		
		'=== Senken der Topicality ===
		
		assertEqualsF(0.65, ProgrammeDataCollection.wearoffFactor, 0.006)
		assertEqualsF(1, programme.data.GetGenreWearoffModifier(), 0.006)
		assertEqualsF(1, programme.data.GetWearoffModifier(), 0.006)				
		programme.data.CutTopicality(programme.GetTopicalityCutModifier())		
		assertEqualsF(214, programme.data.GetTopicality(), 0.006)
		programme.data.CutTopicality(programme.GetTopicalityCutModifier())		
		assertEqualsF(187, programme.data.GetTopicality(), 0.006)	
		programme.data.CutTopicality(programme.GetTopicalityCutModifier(18))		
		assertEqualsF(121, programme.data.GetTopicality(), 0.006)
		
		'=== Refresh der Topicality ===
		
		assertEqualsF(1.5, ProgrammeDataCollection.refreshFactor, 0.006)
		assertEqualsF(1, programme.data.GetGenreRefreshModifier(), 0.006)
		assertEqualsF(1, programme.data.GetRefreshModifier(), 0.006)			
		TProgrammeData.RefreshAllTopicalities()		
		assertEqualsF(181, programme.data.GetTopicality(), 0.006)
		TProgrammeData.RefreshAllTopicalities()		
		assertEqualsF(245, programme.data.GetTopicality(), 0.006)
		TProgrammeData.RefreshAllTopicalities()		
		assertEqualsF(245, programme.data.GetTopicality(), 0.006)
		
		'=== Extreme Jahrgänge ===
				
		programme = TTestKit.CrProgrammeSmall("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, 1975)
		assertEqualsF(235, programme.data.GetMaxTopicality(), 0.006)	

		programme = TTestKit.CrProgrammeSmall("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, 1970)
		assertEqualsF(225, programme.data.GetMaxTopicality(), 0.006)		
		
		programme = TTestKit.CrProgrammeSmall("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, 1935)
		assertEqualsF(155, programme.data.GetMaxTopicality(), 0.006)				

		programme = TTestKit.CrProgrammeSmall("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, 1885)
		assertEqualsF(55, programme.data.GetMaxTopicality(), 0.006)
		
		programme = TTestKit.CrProgrammeSmall("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, 1990)
		assertEqualsF(255, programme.data.GetMaxTopicality(), 0.006)									
	End Method
	
	Method ProgrammeQuality() { test }
		Local programme:TProgramme = TTestKit.CrProgrammeSmall("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5)		
		assertEquals("abc", programme.GetTitle())
		assertEqualsF(255, programme.data.GetMaxTopicality(), 0.006)
		assertEqualsF(0.50, programme.GetQuality(), 0.006)
		
		
		programme = TTestKit.CrProgrammeSmall("abc2", 0, TProgrammeLicence.TYPE_MOVIE)
		programme.licence.data.Outcome = 50
		programme.licence.data.review = 100
		programme.licence.data.speed = 150
		
		assertEqualsF(0.33, programme.data.GetQualityRaw(), 0.006)
		assertEqualsF(0.34, programme.GetQuality(), 0.006)
		
		
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition(0, 0.5, 0.5)
		programme = TTestKit.CrProgramme("abc2", 0, TProgrammeLicence.TYPE_MOVIE, 1, genreDef)
		programme.licence.data.Outcome = 50
		programme.licence.data.review = 100
		programme.licence.data.speed = 150
		assertEqualsF(0.49, programme.data.GetQualityRaw(), 0.006)
		assertEqualsF(0.49, programme.GetQuality(), 0.006)
		
		'Mod durch Alter
		programme = TTestKit.CrProgrammeSmall("abc3", 0, TProgrammeLicence.TYPE_MOVIE, 0.5, 1980)
		assertEqualsF(0.50, programme.data.GetQualityRaw(), 0.006)
		assertEqualsF(0.44, programme.GetQuality(), 0.006)
		
		'Extremes Alter
		programme = TTestKit.CrProgrammeSmall("abc3", 0, TProgrammeLicence.TYPE_MOVIE, 0.5, 1870)
		'DebugStop
		assertEqualsF(0.50, programme.data.GetQualityRaw(), 0.006)
		assertEqualsF(0.01, programme.GetQuality(), 0.006)		
	End Method	

	Method GetAudienceAttraction() { test }
	rem
		Local progData:TProgrammeData = TProgrammeData.Create(
		Local licence:TProgrammeLicence = TProgrammeLicence.Create("Test1", "", 1)
		'licence.
		DebugStop
		Local programme:TProgramme = TProgramme.Create(licence)
		
		Local lastNewsBlockAttraction:TAudienceAttraction = new TAudienceAttraction
		DebugStop
		programme.GetAudienceAttraction(0, 0, lastNewsBlockAttraction, Null)
		endrem
	End Method
End Type