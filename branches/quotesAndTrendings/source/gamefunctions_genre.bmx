Type TGenreDefinitionBase
	Field GenreId:Int
	Field AudienceAttraction:TAudience
	Field Popularity:TGenrePopulartity	

	Method CalculateQuotes:TAudienceAttraction(quality:Float)
		'Zielgruppe / 50 * Qualität
		'Local temp:float = Audience_Children / 50 * quality
		'Local extraAudience = temp/15 * temp/15

		Local result:TAudienceAttraction = New TAudienceAttraction
		result.RawQuality = quality
		
		result.Children = CalculateQuoteForGroup(quality, AudienceAttraction.Children)
		result.Teenagers = CalculateQuoteForGroup(quality, AudienceAttraction.Teenagers)
		result.HouseWifes = CalculateQuoteForGroup(quality, AudienceAttraction.HouseWifes)
		result.Employees = CalculateQuoteForGroup(quality, AudienceAttraction.Employees)
		result.Unemployed = CalculateQuoteForGroup(quality, AudienceAttraction.Unemployed)
		result.Manager = CalculateQuoteForGroup(quality, AudienceAttraction.Manager)
		result.Pensioners = CalculateQuoteForGroup(quality, AudienceAttraction.Pensioners)
		result.Women = CalculateQuoteForGroup(quality, AudienceAttraction.Women)
		result.Men = CalculateQuoteForGroup(quality, AudienceAttraction.Men)
		
		'Für die Statistik
		result.Genre = Self.GenreId
		result.AudienceAttraction = AudienceAttraction
		Local averageTempAll:TAudience = TAudience.CreateWithBreakdown(100000)
		Local averageTemp:TAudience = averageTempAll.GetNewInstance()
		averageTemp.Multiply(result)
		result.Average = float(float(averageTemp.GetSum()) / float(averageTempAll.GetSum()))		
		
		Return result
	End Method
	
	Method CalculateQuoteForGroup:Float(quality:Float, targetGroupAttendance:Float)
		Local result:Float = 0
		
		If (quality <= targetGroupAttendance)
			result = quality + (targetGroupAttendance - quality) * quality
		Else
			result = targetGroupAttendance + (quality - targetGroupAttendance) / 5
		EndIf
		'print "     Gr: " + result + " (quality: " + quality + " / targetGroupAttendance: " + targetGroupAttendance + ")"
		
		Return result
	End Method	
End Type

Type TNewsGenreDefinition Extends TGenreDefinitionBase
	Method LoadFromAssert(asset:TAsset)
		Local data:TMap = TMap(asset._object)

		GenreId = String(data.ValueForKey("id")).ToInt()
		'GenreId = String(data.ValueForKey("name"))
		
		AudienceAttraction = New TAudience
		AudienceAttraction.Children = String(data.ValueForKey("Children")).ToFloat()
		AudienceAttraction.Teenagers = String(data.ValueForKey("Teenagers")).ToFloat()
		AudienceAttraction.HouseWifes = String(data.ValueForKey("HouseWifes")).ToFloat()
		AudienceAttraction.Employees = String(data.ValueForKey("Employees")).ToFloat()
		AudienceAttraction.Unemployed = String(data.ValueForKey("Unemployed")).ToFloat()
		AudienceAttraction.Manager = String(data.ValueForKey("Manager")).ToFloat()
		AudienceAttraction.Pensioners = String(data.ValueForKey("Pensioners")).ToFloat()
		AudienceAttraction.Women = String(data.ValueForKey("Women")).ToFloat()
		AudienceAttraction.Men = String(data.ValueForKey("Men")).ToFloat()
				
		Popularity = TGenrePopulartity.Create(GenreId, RandRange(-10, 10), RandRange(-25, 25))
		Game.PopularityManager.AddPopularity(Popularity) 'Zum Manager hinzufügen		
		
		Print "Load newsgenre " + GenreId + ": " + AudienceAttraction.ToString()
		'print "OutcomeMod: " + OutcomeMod + " | ReviewMod: " + ReviewMod + " | SpeedMod: " + SpeedMod
	End Method

	Method CalculateAudienceAttraction:TAudienceAttraction(news:TNews, hour:Int, luckFactor:Int = 1)
		Local result:TAudienceAttraction = Null	
		
		Local rawQuality:Float = news.GetQuality(luckFactor)
		Local quality:Float = Max(0, Min(99, rawQuality))
									
		result = CalculateQuotes(quality) 'Genre/Zielgruppe-Mod
		result.RawQuality = rawQuality		
				
		Return result
	End Method	
End Type


Type TMovieGenreDefinition Extends TGenreDefinitionBase
	Field TimeMods:Float[]
	
	Field OutcomeMod:Float = 0.5
	Field ReviewMod:Float = 0.3
	Field SpeedMod:Float = 0.2
	
	Method LoadFromAssert(asset:TAsset)
		Local data:TMap = TMap(asset._object)
		GenreId = String(data.ValueForKey("id")).ToInt()
		OutcomeMod = String(data.ValueForKey("outcomeMod")).ToFloat()
		ReviewMod = String(data.ValueForKey("reviewMod")).ToFloat()
		SpeedMod = String(data.ValueForKey("speedMod")).ToFloat()
		
		TimeMods = TimeMods[..24]
		For Local i:Int = 0 To 23
			TimeMods[i] = String(data.ValueForKey("timeMod_" + i)).ToFloat()
		Next

		AudienceAttraction = New TAudience
		AudienceAttraction.Children = String(data.ValueForKey("Children")).ToFloat()
		AudienceAttraction.Teenagers = String(data.ValueForKey("Teenagers")).ToFloat()
		AudienceAttraction.HouseWifes = String(data.ValueForKey("HouseWifes")).ToFloat()
		AudienceAttraction.Employees = String(data.ValueForKey("Employees")).ToFloat()
		AudienceAttraction.Unemployed = String(data.ValueForKey("Unemployed")).ToFloat()
		AudienceAttraction.Manager = String(data.ValueForKey("Manager")).ToFloat()
		AudienceAttraction.Pensioners = String(data.ValueForKey("Pensioners")).ToFloat()
		AudienceAttraction.Women = String(data.ValueForKey("Women")).ToFloat()
		AudienceAttraction.Men = String(data.ValueForKey("Men")).ToFloat()
				
		Popularity = TGenrePopulartity.Create(GenreId, RandRange(-10, 10), RandRange(-25, 25))
		Game.PopularityManager.AddPopularity(Popularity) 'Zum Manager hinzufügen		
		
		'print "Load " + GenreId + ": " + AudienceAttraction.ToString()
		'print "OutcomeMod: " + OutcomeMod + " | ReviewMod: " + ReviewMod + " | SpeedMod: " + SpeedMod 
	End Method

	Method GetProgrammeQualityFallback:Float(programme:TProgramme)
		Local quality:Float = 0.0
		If programme.outcome > 0 Then
			quality = Float(programme.Outcome) / 255.0 * 0.5 ..
				+ Float(programme.review) / 255.0 * 0.3 ..
				+ Float(programme.speed) / 255.0 * 0.2
		Else 'tv shows
			quality = Float(programme.review) / 255.0 * 0.6 ..
				+ Float(programme.speed) / 255.0 * 0.4
		EndIf

		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Int = Max(0, 100 - Max(0, game.GetYear() - programme.year))
		quality:*Max(0.10, (age / 100.0))
		
		'repetitions wont be watched that much
		quality:*(programme.ComputeTopicality() / 255.0) ^ 2

		'no minus quote
		quality = Max(0, quality)
		Return quality
	End Method
	

	Method CalculateAudienceAttraction:TAudienceAttraction(programme:TProgramme, hour:Int, luckFactor:Int = 1)
		Local rawQuality:Float = 0
		Local quality:Float = 0
		Local genreTimeQuality:Float = 0
		Local result:TAudienceAttraction = Null		
		Local timeMod:Float = 1
		
		If Game.BroadcastManager.FEATURE_GENRE_ATTRIB_CALC = 1 'Die Gewichtung der Attribute bei der Berechnung der Filmqualität hängt vom Genre ab
			rawQuality = programme.GetQuality(luckFactor)
		Else
			rawQuality = GetProgrammeQualityFallback(programme)
		EndIf
		quality = rawQuality 
		
		'Popularitäts-Mod+
		Local popularityFactor:Float = (100.0 + Popularity.Popularity) / 100.0 'Popularity => Wert zwischen -50 und +50
		Local popularityQuality:Float = quality * popularityFactor
		quality = popularityQuality
						
		If Game.BroadcastManager.FEATURE_GENRE_TIME_MOD = 1 'Wie gut passt der Sendeplatz zum Genre
			timeMod = TimeMods[hour] 'Genre/Zeit-Mod	
			quality = quality * timeMod			
		EndIf
		quality = Max(0, Min(98, quality))
		genreTimeQuality = quality 'TODO: Aufräumen!!!!
				
		Print "G" + GenreId + "   Programm-Qualität: " + quality + " (ohne Zeit-Mod: " + rawQuality + ")"
		
		If Game.BroadcastManager.FEATURE_GENRE_TARGETGROUP_MOD = 1 'Wie gut kommt das Genre bei den Zielgruppen an
			result = CalculateQuotes(quality) 'Genre/Zielgruppe-Mod
		Else
			result = TAudienceAttraction.CreateAndInitAttraction(quality, quality, quality, quality, quality, quality, quality, quality, quality)
		EndIf
				
		Print "G" + GenreId + "   Quali. nach Zielg.: " + result.ToStringAverage() + " (Einfluss je nach Genre)"
		
		result.RawQuality = rawQuality
		result.GenrePopularityMod = popularityFactor 'TODO 
		result.GenrePopularityQuality = popularityQuality 'TODO
		result.GenreTimeMod = timeMod
		result.GenreTimeQuality = genreTimeQuality
		
		Return result
	End Method
End Type
