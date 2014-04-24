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
		
		programme = TTestKit.CrProgrammeSmall("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5)
		programme.licence.data.timesAired = 1
		assertEqualsF(250, programme.data.GetMaxTopicality(), 0.006)			

		programme = TTestKit.CrProgrammeSmall("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5)
		programme.licence.data.timesAired = 2
		assertEqualsF(245, programme.data.GetMaxTopicality(), 0.006)			
		
		programme = TTestKit.CrProgrammeSmall("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5)
		programme.licence.data.timesAired = 100
		assertEqualsF(205, programme.data.GetMaxTopicality(), 0.006)					
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
		
		
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition(1, 0, 0.5, 0.5)
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
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, genreDef)
		
		programme.owner = 0
		'Falsch-Angaben
		Try
			programme.GetAudienceAttraction(0, 1, Null, Null)
			fail("No Exception")
		Catch ex:TBlitzException 'Alles gut			
			assertEquals("The programme 'abc' have no owner.", ex.ToString())
		Catch ex:Object 'falsche excpetion			
			fail("Wrong Exception: " + ex.ToString())
		End Try			
		
		programme.owner = 1	
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.503058851), programme.GetAudienceAttraction(0, 1, Null, Null))

		'Trailer: TODO
		
		'Flags: TODO
	End Method
	
	Method GetAudienceAttraction_Popularity() { test }
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, genreDef)		
		
		genreDef.Popularity.Popularity = +25
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.628823578), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		genreDef.Popularity.Popularity = -25
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.377294123), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		genreDef.Popularity.Popularity = +250 'Eigentliches maximum 50
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.754588246), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		genreDef.Popularity.Popularity = -250 'Eigentliches minimum 50
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.251529425), programme.GetAudienceAttraction(0, 1, Null, Null))		
	End Method
	
	Method GetAudienceAttraction_AudienceAttraction() { test }
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, genreDef)
		
		genreDef.Popularity.Popularity = 0
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(0)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.201223522), programme.GetAudienceAttraction(0, 1, Null, Null), "x1")
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(1)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.804894149), programme.GetAudienceAttraction(0, 1, Null, Null), "x2")

		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(2)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.804894149), programme.GetAudienceAttraction(0, 1, Null, Null), "x3")
		
		genreDef.AudienceAttraction = TAudience.CreateAndInit(0, 0.1, 0.3, 0.4, 0.5, 0.6, 0.7, 0.9, 1) 
		Local expected:TAudience = TAudience.CreateAndInit(0.201223522, 0.261590600, 0.382324725, 0.442691773, 0.503058851, 0.563425899, 0.623793006, 0.744527102, 0.804894149) 
		TestAssert.assertEqualsAud(expected, programme.GetAudienceAttraction(0, 1, Null, Null))		
		
		'Popularity & AudienceAttraction
		
		genreDef.Popularity.Popularity = +250 'Eigentliches maximum 50
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(2)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.05642354), programme.GetAudienceAttraction(0, 1, Null, Null))		
	End Method
	
	Method GetAudienceAttraction_PublicImage() { test }
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, genreDef)
		
		genreDef.Popularity.Popularity = 0
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(0.5)		
		
		TestPlayer.PublicImage.ImageValues = TAudience.CreateAndInitValue(0)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.326988250), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		TestPlayer.PublicImage.ImageValues = TAudience.CreateAndInitValue(100)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.503058851), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		TestPlayer.PublicImage.ImageValues = TAudience.CreateAndInitValue(150)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.591094136), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		TestPlayer.PublicImage.ImageValues = TAudience.CreateAndInitValue(200)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.679129481), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		TestPlayer.PublicImage.ImageValues = TAudience.CreateAndInitValue(-50)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.326988250), programme.GetAudienceAttraction(0, 1, Null, Null))
		
		TestPlayer.PublicImage.ImageValues = TAudience.CreateAndInitValue(500)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.679129481), programme.GetAudienceAttraction(0, 1, Null, Null))	
	End Method
	
	Method GetAudienceAttraction_QualityOverTimeEffectMod() { test }
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, genreDef)
		
		TestPlayer.PublicImage.ImageValues = TAudience.CreateAndInitValue(100)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.503315330), programme.GetAudienceAttraction(0, 2, Null, Null))
		
		programme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.25, genreDef)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.254588246), programme.GetAudienceAttraction(0, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.233761936), programme.GetAudienceAttraction(0, 2, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.212935612), programme.GetAudienceAttraction(0, 3, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.203670606), programme.GetAudienceAttraction(0, 4, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.203670606), programme.GetAudienceAttraction(0, 5, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.203670606), programme.GetAudienceAttraction(0, 10, Null, Null))
		
		programme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.75, genreDef)		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.751529455), programme.GetAudienceAttraction(0, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.783034801), programme.GetAudienceAttraction(0, 2, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.814540029), programme.GetAudienceAttraction(0, 3, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.826682448), programme.GetAudienceAttraction(0, 4, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.826682448), programme.GetAudienceAttraction(0, 5, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.826682448), programme.GetAudienceAttraction(0, 10, Null, Null))		
		
		programme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 1, genreDef)		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1), programme.GetAudienceAttraction(0, 1, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.08333337), programme.GetAudienceAttraction(0, 2, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.10000002), programme.GetAudienceAttraction(0, 3, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.10000002), programme.GetAudienceAttraction(0, 4, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.10000002), programme.GetAudienceAttraction(0, 5, Null, Null))
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.10000002), programme.GetAudienceAttraction(0, 10, Null, Null))		
	End Method		
	
	Method GetAudienceAttraction_Sequence() { test }
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, genreDef)		
		
		programme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 1, genreDef)		
		'TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.75), programme.GetAudienceAttraction(0, 1, Null, Null, True))		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.778723419), programme.GetAudienceAttraction(0, 1, Null, Null, True))		
		
		Local newsAttraction:TAudienceAttraction = new TAudienceAttraction
		newsAttraction.BlockAttraction = TAudience.CreateAndInitValue(1)		
		'TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.27), programme.GetAudienceAttraction(0, 1, Null, newsAttraction, True))	
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1), programme.GetAudienceAttraction(0, 1, Null, newsAttraction, True))			
		
		newsAttraction.BlockAttraction = TAudience.CreateAndInitValue(0.5)		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.889361739), programme.GetAudienceAttraction(0, 1, Null, newsAttraction, True))		
		
		
		
		
		
		programme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, genreDef)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.391743690), programme.GetAudienceAttraction(0, 1, Null, Null, True))
		
		newsAttraction.BlockAttraction = TAudience.CreateAndInitValue(1)		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.682722211), programme.GetAudienceAttraction(0, 1, Null, newsAttraction, True))	
		
		newsAttraction.BlockAttraction = TAudience.CreateAndInitValue(0.5)		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.502381980), programme.GetAudienceAttraction(0, 1, Null, newsAttraction, True))						

		
		'Sequence - AudienceFlow
		Local lastMovieGenreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local lastMovie:TProgramme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, lastMovieGenreDef)		
		Local lastMovieAttr:TAudienceAttraction = lastMovie.GetAudienceAttraction(0, 1, Null, Null)
		newsAttraction.BlockAttraction = TAudience.CreateAndInitValue(0.5)	
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.502381980), programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True))		
		
		'Perfekt match!
		newsAttraction.BlockAttraction = TAudience.CreateAndInitValue(1)
		'DebugStop 'TODO: das nächste mal: GetAudienceFlowMod reaktivieren. Es fehlt noch eine Verbindung zur News-Audience-Attraction
		Local actual:TAudienceAttraction = programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.0993882269), actual.SequenceEffect)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.602447093), actual)				
		
		'Normal
		lastMovieGenreDef = TTestKit.CrMovieGenreDefinition(10)
		lastMovie = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 0.5, lastMovieGenreDef)		
		lastMovieAttr = lastMovie.GetAudienceAttraction(0, 1, Null, Null)		
		actual = programme.GetAudienceAttraction(0, 1, lastMovieAttr, newsAttraction, True)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.0688072369), actual.SequenceEffect)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.571866095), actual)
		
	End Method
	
	Method GetAudienceFlowMod() { test }
		Local lastMovieGenreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local lastMovie:TProgramme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 1, lastMovieGenreDef)		
		Local lastMovieAttr:TAudienceAttraction = lastMovie.GetAudienceAttraction(0, 1, Null, Null)
		lastMovieGenreDef.GoodFollower.AddLast("2")
		lastMovieGenreDef.BadFollower.AddLast("4")
		
		
		
		'Perfekter Match
		Local genreDef:TMovieGenreDefinition = TTestKit.CrMovieGenreDefinition()
		Local programme:TProgramme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 1, genreDef)
		Local programmeAttr:TAudienceAttraction = programme.GetAudienceAttraction(0, 1, Null, Null)		
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(1.3)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.25), TProgramme.GetAudienceFlowMod(lastMovieAttr, programmeAttr), "p1")
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(1)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1), TProgramme.GetAudienceFlowMod(lastMovieAttr, programmeAttr), "p2")
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(0.5)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.5), TProgramme.GetAudienceFlowMod(lastMovieAttr, programmeAttr), "p3")
		
		'Guter Follower		
		genreDef = TTestKit.CrMovieGenreDefinition(2)
		programme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 1, genreDef)
		programmeAttr = programme.GetAudienceAttraction(0, 1, Null, Null)
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(1.3)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(1.10), TProgramme.GetAudienceFlowMod(lastMovieAttr, programmeAttr), "g1")
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(1)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.846153855), TProgramme.GetAudienceFlowMod(lastMovieAttr, programmeAttr), "g2")
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(0.5)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.423076928), TProgramme.GetAudienceFlowMod(lastMovieAttr, programmeAttr), "g3")
		
		'Normaler Follower		
		genreDef = TTestKit.CrMovieGenreDefinition(3)
		programme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 1, genreDef)
		programmeAttr = programme.GetAudienceAttraction(0, 1, Null, Null)				
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(1.3)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.899999976), TProgramme.GetAudienceFlowMod(lastMovieAttr, programmeAttr), "n1")
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(1.0)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.692307711), TProgramme.GetAudienceFlowMod(lastMovieAttr, programmeAttr), "n2")
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(0.5)
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.346153855), TProgramme.GetAudienceFlowMod(lastMovieAttr, programmeAttr), "n3")
		
		'Schlechter Follower
		genreDef = TTestKit.CrMovieGenreDefinition(4)
		programme = TTestKit.CrProgramme("abc", 1, TProgrammeLicence.TYPE_MOVIE, 1, genreDef)
		programmeAttr = programme.GetAudienceAttraction(0, 1, Null, Null)
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(1.3)			
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.300000012), TProgramme.GetAudienceFlowMod(lastMovieAttr, programmeAttr), "b1")
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(1.0)			
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.25), TProgramme.GetAudienceFlowMod(lastMovieAttr, programmeAttr), "b2")
		
		genreDef.AudienceAttraction = TAudience.CreateAndInitValue(0.5)			
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0.25), TProgramme.GetAudienceFlowMod(lastMovieAttr, programmeAttr), "b3")
	End Method
End Type