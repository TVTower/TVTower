Type TGenreDefinitionBase
	Field GenreId:Int
	Field AudienceAttraction:TAudience
	Field Popularity:TGenrePopularity
	
	Method GetAudienceFlowMod:TAudience(followerGenreId:Int, baseAttractionFollower:TAudience) Abstract
	
	Method GetSequence:TAudience(predecessor:TAudienceAttraction, successor:TAudienceAttraction, effectRise:Float, effectShrink:Float)
		Local result:TAudience = new TAudience
		Local predecessorValue:Float
		Local successorValue:Float
		
		For Local i:Int = 1 To 9
			If predecessor
				predecessorValue = predecessor.BlockAttraction.GetValue(i)
			Else
				predecessorValue = 0
			EndIf
			successorValue = successor.BlockAttraction.GetValue(i)
			If (predecessorValue < successorValue) 'Steigende Quote
				predecessorValue :* effectRise
				successorValue :* (1 - effectRise)
			Else 'Sinkende Quote
				predecessorValue :* effectShrink
				successorValue :* (1 - effectShrink)			
			Endif
			Local sum:Float = predecessorValue + successorValue
			Local sequence:Float = sum - successor.BlockAttraction.GetValue(i)
			'TODO: Faktoren berücksichtigen und Audience-Flow usw.
			result.SetValue(i, sequence)
		Next			
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

		Popularity = TGenrePopularity.Create(GenreId, RandRange(-10, 10), RandRange(-25, 25))
		Game.PopularityManager.AddPopularity(Popularity) 'Zum Manager hinzufügen

		'Print "Load newsgenre " + GenreId + ": " + AudienceAttraction.ToString()
		'print "OutcomeMod: " + OutcomeMod + " | ReviewMod: " + ReviewMod + " | SpeedMod: " + SpeedMod
	End Method

	Method CalculateAudienceAttraction:TAudienceAttraction(news:TNews, hour:Int, luckFactor:Int = 1)
		Throw "TODO"
		'Local result:TAudienceAttraction = Null

		'Local rawQuality:Float = news.GetQuality()
		'Local quality:Float = Max(0, Min(99, rawQuality))

		'result = CalculateQuotes(quality) 'Genre/Zielgruppe-Mod
		'result.Quality = rawQuality

		'Return result
	End Method
	
	Method GetAudienceFlowMod:TAudience(followerGenreId:Int, baseAttractionFollower:TAudience)
		Return TAudience.CreateAndInitValue(1) 'TODO: Prüfen ob hier auch was zu machen ist?
	End Method	
End Type


Type TMovieGenreDefinition Extends TGenreDefinitionBase
	Field TimeMods:Float[]

	Field OutcomeMod:Float = 0.5
	Field ReviewMod:Float = 0.3
	Field SpeedMod:Float = 0.2
	
	Field GoodFollower:TList = CreateList()
	Field BadFollower:TList = CreateList()

	Method LoadFromAssert(asset:TAsset)
		Local data:TMap = TMap(asset._object)
		GenreId = String(data.ValueForKey("id")).ToInt()
		OutcomeMod = String(data.ValueForKey("outcomeMod")).ToFloat()
		ReviewMod = String(data.ValueForKey("reviewMod")).ToFloat()
		SpeedMod = String(data.ValueForKey("speedMod")).ToFloat()

		GoodFollower = TList(data.ValueForKey("goodFollower"))
		If GoodFollower = Null Then GoodFollower = CreateList()
		BadFollower = TList(data.ValueForKey("badFollower"))
		If BadFollower = Null Then BadFollower = CreateList()
		
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

		Popularity = TGenrePopularity.Create(GenreId, RandRange(-10, 10), RandRange(-25, 25))
		Game.PopularityManager.AddPopularity(Popularity) 'Zum Manager hinzufügen

		'print "Load moviegenre" + GenreId + ": " + AudienceAttraction.ToString()
		'print "OutcomeMod: " + OutcomeMod + " | ReviewMod: " + ReviewMod + " | SpeedMod: " + SpeedMod
	End Method
	
	Method GetAudienceFlowMod:TAudience(followerGenreId:Int, baseAttractionFollower:TAudience)
		'DebugStop
		Local baseAttractionFollowerTemp:TAudience = baseAttractionFollower.Copy()
		baseAttractionFollowerTemp.DivideFloat(2).AddFloat(0.7)
		
		Local base:TAudience = GetAudienceFlowModBase(followerGenreId)
		base.Multiply(baseAttractionFollowerTemp)
		Return base
	End Method
	
	Method GetAudienceFlowModBase:TAudience(followerGenreId:Int)
		Local followerDefinition:TMovieGenreDefinition = Game.BroadcastManager.GetMovieGenreDefinition(followerGenreId)
	
		Local result:TAudience = followerDefinition.AudienceAttraction.Copy().DivideFloat(5) '0-0.2
		
		Local genreKey:String = String.FromInt(followerGenreId)
		If (GoodFollower.Contains(genreKey))
			Return result.AddFloat(0.3)
		ElseIf (BadFollower.Contains(genreKey))
			Return result.AddFloat(0.05).DivideFloat(2) 
		Else
			Return result.AddFloat(0.05)
		End If
	End Method	

rem
	Method CalculateAudienceAttraction:TAudienceAttraction(material:TBroadcastMaterial, hour:Int)
		'RONNY @Manuel: Todo fuer Werbesendungen
		If material.isType(TBroadcastMaterial.TYPE_ADVERTISEMENT)
			Local result:TAudienceAttraction = Null
			Local quality:Float =  0.01 * randrange(1,10)
			result = TAudienceAttraction.CreateAndInitAttraction(quality, quality, quality, quality, quality, quality, quality, quality, quality)
			result.RawQuality = quality
			result.GenrePopularityMod = 0
			result.GenrePopularityQuality = 0
			result.GenreTimeMod = 0
			result.GenreTimeQuality = 0
			Return result
		EndIf
		If Not material.isType(TBroadcastMaterial.TYPE_PROGRAMME)
			Throw "TMovieGenreDefinition.CalculateAudienceAttraction - given material is of wrong type."
			Return Null
		EndIf

		Local data:TProgrammeData = TProgramme(material).data
		Local quality:Float = 0
		Local result:TAudienceAttraction = New TAudienceAttraction

		result.RawQuality = data.GetQuality()
		
		quality = ManipulateQualityFactor(result.RawQuality, hour, result)
		
		'Vorläufiger Code für den Trailer-Bonus
		'========================================				
		'25% für eine Trailerausstrahlungen (egal zu welcher Uhrzeit), 40% für zwei Ausstrahlungen, 50% für drei Ausstrahlungen, 55% für vier und 60% für fünf und mehr.
		Local timesTrailerAired:Int = data.GetTimesTrailerAired(False)
		Local trailerMod:Float = 1
		
		Select timesTrailerAired
			Case 0 	trailerMod = 1
			Case 1 	trailerMod = 1.25
			Case 2 	trailerMod = 1.40
			Case 3 	trailerMod = 1.50
			Case 4 	trailerMod = 1.55
			Default	trailerMod = 1.6			
		EndSelect

		Local trailerQuality:Float = quality * trailerMod
		trailerQuality = Max(0, Min(0.98, trailerQuality))
		
		result.TrailerMod = trailerMod
		result.TrailerQuality = trailerQuality
		
		quality = trailerQuality
						
		'=======================================

		result = CalculateQuotes(quality, result) 'Genre/Zielgruppe-Mod

		Return result
	End Method
	
	Method ManipulateQualityFactor:Float(quality:Float, hour:Int, stats:TAudienceAttraction)
		Local timeMod:Float = 1
	
		'Popularitäts-Mod+
		Local popularityFactor:Float = (100.0 + Popularity.Popularity) / 100.0 'Popularity => Wert zwischen -50 und +50
		quality = quality * popularityFactor
		stats.GenrePopularityMod = popularityFactor
		stats.GenrePopularityQuality = quality
		
		'Wie gut passt der Sendeplatz zum Genre
		timeMod = TimeMods[hour] 'Genre/Zeit-Mod
		quality = quality * timeMod			
		stats.GenreTimeMod = timeMod
		
		quality = Max(0, Min(98, quality))
		stats.GenreTimeQuality = quality
						
		Return quality
	End Method
endrem
End Type
