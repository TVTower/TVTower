SuperStrict
Import "Dig/base.util.registry.bmx"
Import "game.broadcast.genredefinition.base.bmx"
Import "game.popularity.bmx"

Type TMovieGenreDefinitionCollection
	Field definitions:TMovieGenreDefinition[]
	Field flagDefinitions:TMovieFlagDefinition[]
	Global _instance:TMovieGenreDefinitionCollection


	Function GetInstance:TMovieGenreDefinitionCollection()
		if not _instance then _instance = new TMovieGenreDefinitionCollection
		return _instance
	End Function


	Method Initialize()
		'clear old definitions
		definitions = new TMovieGenreDefinition[0]
		flagDefinitions = new TMovieFlagDefinition[0]

		Local genreMap:TMap = TMap(GetRegistry().Get("genres"))
		if not genreMap then Throw "Registry misses ~qgenres~q."
		For Local map:TMap = EachIn genreMap.Values()
			Local definition:TMovieGenreDefinition = New TMovieGenreDefinition
			definition.LoadFromMap(map)
			Set(definition.referenceId, definition)
		Next

		Local flagsMap:TMap = TMap(GetRegistry().Get("flags"))
		if not flagsMap then Throw "Registry misses ~qflags~q."
		For Local map:TMap = EachIn flagsMap.Values()
			Local definition:TMovieFlagDefinition = New TMovieFlagDefinition
			definition.LoadFromMap(map)
			SetFlag(definition.referenceId, definition)
		Next
	End Method


	Method Set:int(id:int=-1, definition:TMovieGenreDefinition)
		If definitions.length <= id Then definitions = definitions[..id+1]
		definitions[id] = definition
	End Method


	Method Get:TMovieGenreDefinition(id:Int)
		If id < 0 or id >= definitions.length Then return Null

		Return definitions[id]
	End Method


	Method SetFlag:int(id:int=-1, definition:TMovieFlagDefinition)
		If flagDefinitions.length <= id Then flagDefinitions = flagDefinitions[..id+1]
		flagDefinitions[id] = definition
	End Method


	Method GetFlag:TMovieFlagDefinition(id:Int)
		If id < 0 or id >= flagDefinitions.length Then return Null

		Return flagDefinitions[id]
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetMovieGenreDefinitionCollection:TMovieGenreDefinitionCollection()
	Return TMovieGenreDefinitionCollection.GetInstance()
End Function




Type TMovieGenreDefinition Extends TGenreDefinitionBase
	Field OutcomeMod:Float = 0.5
	Field ReviewMod:Float = 0.3
	Field SpeedMod:Float = 0.2

	Field GoodFollower:TList = CreateList()
	Field BadFollower:TList = CreateList()

	'override
	Method GetGUIDBaseName:string()
		return "movie-genre-definition"
	End Method

	
	Method InitBasic:TMovieGenreDefinition(genreId:int, data:TData)
		if not data then data = new TData
		Super.InitBasic(genreId, data)

		OutcomeMod = data.GetFloat("outcomeMod", 1.0)
		ReviewMod = data.GetFloat("reviewMod", 1.0)
		SpeedMod = data.GetFloat("speedMod", 1.0)

		GoodFollower = TList(data.Get("goodFollower"))
		If GoodFollower = Null Then GoodFollower = CreateList()
		BadFollower = TList(data.Get("badFollower"))
		If BadFollower = Null Then BadFollower = CreateList()

		'print "Load moviegenre" + referenceId + ": " + AudienceAttraction.ToString()
		'print "OutcomeMod: " + OutcomeMod + " | ReviewMod: " + ReviewMod + " | SpeedMod: " + SpeedMod

		return self
	End Method


	Method GetPopularity:TGenrePopularity()
		return TGenrePopularity(Super.GetPopularity())
	End Method


	Method GetAudienceFlowMod:TAudience(followerDefinition:TGenreDefinitionBase)
		'default audience flow mod
		local modValue:Float = 0.35
		
		Local followerReferenceKey:String = String.FromInt(followerDefinition.referenceId)
		If referenceId = followerDefinition.referenceId Then 'Perfekter match!
			modValue = 1.0
		Else If (GoodFollower.Contains(followerReferenceKey))
			modValue = 0.7
		ElseIf (BadFollower.Contains(followerReferenceKey))
			modValue = 0.1
		endif

		Return TAudience.CreateAndInitValue(modValue)
	End Method

	'Override
	'case: 1 = with AudienceFlow
	rem
	Method GetSequence:TAudience(predecessor:TAudienceAttraction, successor:TAudienceAttraction, effectRise:Float, effectShrink:Float, withAudienceFlow:Int = False)
		Local riseMod:TAudience = AudienceAttraction.Copy()

			If lastMovieBlockAttraction Then
				Local lastGenreDefintion:TMovieGenreDefinition = Game.BroadcastManager.GetMovieGenreDefinition(lastMovieBlockAttraction.Genre)
				Local audienceFlowMod:TAudience = lastGenreDefintion.GetAudienceFlowMod(result.Genre, result.BaseAttraction)

				result.AudienceFlowBonus = lastMovieBlockAttraction.Copy()
				result.AudienceFlowBonus.Multiply(audienceFlowMod)
			Else
				result.AudienceFlowBonus = lastNewsBlockAttraction.Copy()
				result.AudienceFlowBonus.MultiplyFloat(0.2)
			End If



		Return TGenreDefinitionBase.GetSequenceDefault(predecessor, successor, effectRise, effectShrink)
	End Method
	endrem

rem
	Method CalculateAudienceAttraction:TAudienceAttraction(material:TBroadcastMaterial, hour:Int)
		'RONNY @Manuel: Todo fuer Werbesendungen
		If material.isType(TVTBroadcastMaterialType.ADVERTISEMENT)
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
		If Not material.isType(TVTBroadcastMaterialType.PROGRAMME)
			Throw "TMovieGenreDefinition.CalculateAudienceAttraction - given material is of wrong type."
			Return Null
		EndIf

		Local data:TProgrammeData = TProgramme(material).data
		Local quality:Float = 0
		Local result:TAudienceAttraction = New TAudienceAttraction

		result.RawQuality = data.GetQualityRaw()

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



Type TMovieFlagDefinition Extends TMovieGenreDefinition

	'override
	Method GetGUIDBaseName:string()
		return "movie-flag-definition"
	End Method


	Method InitBasic:TMovieFlagDefinition(flagID:int, data:TData)
		'init with flagID so popularity (created there) gets this ID too 
		Super.InitBasic(flagID, data)
		
		return self
	End Method
	
End Type