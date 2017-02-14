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
		'reset previously created ones
		For local def:TGenreDefinitionBase = EachIn definitions
			def.Reset()
		Next
		For local def:TGenreDefinitionBase = EachIn flagDefinitions
			def.Reset()
		Next

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

Function GetMovieGenreDefinition:TMovieGenreDefinition(genreID:int)
	Return TMovieGenreDefinitionCollection.GetInstance().Get(genreID)
End Function



Type TMovieGenreDefinition Extends TGenreDefinitionBase
	Field OutcomeMod:Float = 0.5
	Field ReviewMod:Float = 0.3
	Field SpeedMod:Float = 0.2

	Field GoodFollower:TList = CreateList()
	Field BadFollower:TList = CreateList()

	'=== helpers for custom production ===
	'map: jobName_attribute=>value
	Field castAttributes:TMap = null
	'map focusPoint=>value
	Field focusPointPriorities:TMap = null


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

		'might be null!
		castAttributes = TMap(data.Get("castAttributes"))
		focusPointPriorities = TMap(data.Get("focusPointPriorities"))

		'print "Load moviegenre" + referenceId + ": " + AudienceAttraction.ToString()
		'print "OutcomeMod: " + OutcomeMod + " | ReviewMod: " + ReviewMod + " | SpeedMod: " + SpeedMod

		return self
	End Method


	Method SetCastAttribute(jobID:int, attributeID:int, value:float)
		if not castAttributes then castAttributes = CreateMap()

		castAttributes.Insert(jobID+"_"+attributeID, string(value))
	End Method
	

	Method GetCastAttribute:Float(jobID:int, attributeID:int)
		if not castAttributes then return 0.0
		local value:object = castAttributes.ValueForKey(jobID+"_"+attributeID)
		if not value or string(value)="" then return 0.0

		return float(string(value))
	End Method
	

	Method SetFocusPointPriority(focusPointID:int, value:float)
		if not focusPointPriorities then focusPointPriorities = CreateMap()
		focusPointPriorities.Insert(string(focusPointID), string(value))
	End Method

	
	Method GetFocusPointPriority:Float(focusPointID:int )
		if not focusPointPriorities then return 1.0
		local value:object = focusPointPriorities.ValueForKey(string(focusPointID))
		if not value or string(value) then return 1.0

		return float(string(value))
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

		Return new TAudience.InitValue(modValue, modValue)
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


	Method GetPopularity:TGenrePopularity()
		return TGenrePopularity(Super.GetPopularity())
	End Method
	
End Type