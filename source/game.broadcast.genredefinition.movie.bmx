SuperStrict
Import "Dig/base.util.registry.bmx"
Import "game.broadcast.genredefinition.base.bmx"
Import "game.popularity.bmx"
Import Collections.HashMap


Extern
    Global bbStringsAllocCount:ULong="bbStringsAllocCount"
    Global bbStringsFreeCount:ULong="bbStringsFreeCount"
    Global bbGCAllocCount:ULong="bbGCAllocCount"
End Extern
Global MovieGenreDefinitionCollectionAllocs:ULong = 0

Type TMovieGenreDefinitionCollection
	Field definitions:TMovieGenreDefinition[]
	Field flagDefinitions:TIntMap = new TIntMap
	Global _instance:TMovieGenreDefinitionCollection
	Field combined:THashMap<Int, TMovieGenreDefinition>  = New THashMap<Int, TMovieGenreDefinition> {nosave}
	'Field combined:TStringMap = new TStringMap {nosave}


	Function GetInstance:TMovieGenreDefinitionCollection()
		if not _instance then _instance = new TMovieGenreDefinitionCollection
		return _instance
	End Function


	Method Initialize()
		'reset previously created ones
		'this removes eg. popularity links so it reconnects correctly
		For local def:TGenreDefinitionBase = EachIn definitions
			def.Reset()
		Next
		For local def:TGenreDefinitionBase = EachIn flagDefinitions.Values()
			def.Reset()
		Next

		'disabled: leads to duplicate entries if other objects link
		'          to this definitions directly (instead of "GUID")
		'clear old definitions
		'definitions = new TMovieGenreDefinition[0]
		'flagDefinitions = new TMovieFlagDefinition[0]

		'override existing ones with _new_ values (might change balancing!)

		Local genreMap:TMap = TMap(GetRegistry().Get("genres"))
		if not genreMap then Throw "Registry misses ~qgenres~q."
		For Local map:TMap = EachIn genreMap.Values()
			local mapData:TData = new TData.Init(map)
			local definitionReferenceID:int = mapData.GetInt("id")
			Local definition:TMovieGenreDefinition = Get([definitionReferenceID])
			if not definition then definition = New TMovieGenreDefinition

			definition.LoadFromMap(map)
			Set(definition.referenceId, definition)
		Next

		Local flagsMap:TMap = TMap(GetRegistry().Get("flags"))
		if not flagsMap then Throw "Registry misses ~qflags~q."
		For Local map:TMap = EachIn flagsMap.Values()
			local mapData:TData = new TData.Init(map)
			local definitionReferenceID:int = mapData.GetInt("id")
			Local definition:TMovieFlagDefinition = GetFlag(definitionReferenceID)
			if not definition then definition = New TMovieFlagDefinition

			definition.LoadFromMap(map)
			SetFlag(definition.referenceId, definition)
		Next
		combined.clear()
	End Method


	Method Set:int(id:int=-1, definition:TMovieGenreDefinition)
		If definitions.length <= id Then definitions = definitions[..id+1]
		definitions[id] = definition
	End Method


	Method Get:TMovieGenreDefinition(ids:Int[])
		If ids.length = 1
			Local id:Int = ids[0]
			If id < 0 or id >= definitions.length Then return Null
			Return definitions[id]
		Else
			Local key:String = ",".join(ids)
			Local keyHash:Int = key.HashCode()
			
			Return GetCombined(keyHash, ids, key)
		EndIf
	End Method
rem
	Method Get:TMovieGenreDefinition(mainID:Int, subIDs:Int[])
		If subIDs.length = 0
			If mainID < 0 or mainID >= definitions.length Then return Null
			Return definitions[mainID]
		Else
			Local key:String = ",".Join(subIDs)
			if mainID >= 0
				if key Then key = mainID + "," + mainID
			Local keyHash:Int = key.HashCode()
			
			Return GetCombined(keyHash, ids, key)
		EndIf
	End Method
endrem

	Method GetSingle:TMovieGenreDefinition(id:Int)
		If id < 0 or id >= definitions.length Then return Null
		Return definitions[id]
	End Method
	
	
	Method GetCombined:TMovieGenreDefinition(keyHash:Int, ids:Int[] = Null, key:String = Null)
		Local result:TMovieGenreDefinition = combined[keyHash]
		If Not result
			If not key and ids.length > 0
				key = ",".Join(ids)
			EndIf
			'print "creating aggregate for key "+key
			result = createAggregatedMovieGenreDefinition(ids)
			result.SetGUID(result.GetGUIDBaseName() + "-" + key)
			combined[keyHash] = result
		EndIf
		Return result
	End Method


	Method createAggregatedMovieGenreDefinition:TMovieGenreDefinition(ids:Int[])
		Local result:TMovieGenreDefinition=new TMovieGenreDefinition
		Local all:TMovieGenreDefinition[] = new TMovieGenreDefinition[ids.length]
		Local i:Int
		Local floats:Float[ids.length]
		For i:Int = 0 Until ids.length
			all[i] = GetSingle(ids[i])
		Next
		Local main:TMovieGenreDefinition = all[0]
		result.BadFollower = main.BadFollower
		result.GoodFollower = main.GoodFollower
		'TODO this is not yet optimal
		'popularity is based on the main popularity
		'creating and consistently maintaining an aggregated popularity 
		'would be an enormous effort
		result.referenceID = main.referenceID
		result._popularity = main.GetPopularity()

		result.castAttributes = CreateMap()
		result.focusPointPriorities = CreateMap()
		For i:Int = 0 Until ids.length
			collectKeys(all[i].castAttributes, result.castAttributes)
			collectKeys(all[i].focusPointPriorities, result.focusPointPriorities)
		Next

		'audience attraction
		result.AudienceAttraction = main.AudienceAttraction.Copy()
		Local att:TAudience = result.AudienceAttraction

		Select all.length
			Case 1
				addWeighted(main.castAttributes, result.castAttributes, 1.0, 0.0)

				addWeighted(main.focusPointPriorities, result.focusPointPriorities, 1.0, 1.0)

				'attraction already copied
			Case 2
				addWeighted(main.castAttributes, result.castAttributes, 0.75, 0.0)
				addWeighted(all[1].castAttributes, result.castAttributes, 0.25, 0.0)

				addWeighted(main.focusPointPriorities, result.focusPointPriorities, 0.75, 1.0)
				addWeighted(all[1].focusPointPriorities, result.focusPointPriorities, 0.25, 1.0)

				att.Multiply(0.75).add(attr(all[1],0.25))
			Case 3
				addWeighted(main.castAttributes, result.castAttributes, 0.6, 0.0)
				addWeighted(all[1].castAttributes, result.castAttributes, 0.25, 0.0)
				addWeighted(all[2].castAttributes, result.castAttributes, 0.15, 0.0)

				addWeighted(main.focusPointPriorities, result.focusPointPriorities, 0.6, 1.0)
				addWeighted(all[1].focusPointPriorities, result.focusPointPriorities, 0.25, 1.0)
				addWeighted(all[2].focusPointPriorities, result.focusPointPriorities, 0.15, 1.0)

				att.Multiply(0.6).add(attr(all[1],0.25)).add(attr(all[2],0.15))
			Default 'genre 5 and later are ignored
				addWeighted(main.castAttributes, result.castAttributes, 0.6, 0.0)
				addWeighted(all[1].castAttributes, result.castAttributes, 0.20, 0.0)
				addWeighted(all[2].castAttributes, result.castAttributes, 0.12, 0.0)
				addWeighted(all[3].castAttributes, result.castAttributes, 0.08, 0.0)

				addWeighted(main.focusPointPriorities, result.focusPointPriorities, 0.6, 1.0)
				addWeighted(all[1].focusPointPriorities, result.focusPointPriorities, 0.20, 1.0)
				addWeighted(all[2].focusPointPriorities, result.focusPointPriorities, 0.12, 1.0)
				addWeighted(all[3].focusPointPriorities, result.focusPointPriorities, 0.08, 1.0)

				att.Multiply(0.6).add(attr(all[1],0.20)).add(attr(all[2],0.12)).add(attr(all[2],0.08))
		End Select

		'speed
		For i:Int = 0 Until ids.length
			floats[i] = all[i].SpeedMod
			result.SpeedMod = weighted(floats)
		Next
		'outcome
		For i:Int = 0 Until ids.length
			floats[i] = all[i].outcomeMod
			result.outcomeMod = weighted(floats)
		Next
		'review
		For i:Int = 0 Until ids.length
			floats[i] = all[i].ReviewMod
			result.ReviewMod = weighted(floats)
		Next
		'refresh
		For i:Int = 0 Until ids.length
			floats[i] = all[i].RefreshMod
			result.RefreshMod = weighted(floats)
		Next
		'wearoff
		For i:Int = 0 Until ids.length
			floats[i] = all[i].WearoffMod
			result.WearoffMod = weighted(floats)
		Next

		'timeMod
		result.TimeMods = result.TimeMods[..24]
		For Local hour:Int = 0 To 23
			For i:Int = 0 Until ids.length
				floats[i] = all[i].TimeMods[hour]
				result.TimeMods[hour] = weighted(floats)
			Next
		Next

		Return result

		Function weighted:Float(v:Float[])
			Select v.length
				Case 1
					Return v[0]
				Case 2
					Return 0.75 * v[0] + 0.25 * v[1]
				Case 3
					Return 0.6 * v[0] + 0.25 * v[1] + 0.15 * v[2]
				Default 'genre 5 and later are ignored
					Return 0.6 * v[0] + 0.2 * v[1] + 0.12 * v[2] + 0.08 * v[3]
			End Select
		End Function

		Function attr:TAudience(def:TMovieGenreDefinition, factor:Float)
			Return def.AudienceAttraction.Copy().Multiply(factor)
		EndFunction

		Function collectKeys(map:TMap, result:TMap)
			If map
				For Local key:String = EachIn map.Keys()
					result.insert(key, "0")
				Next
			EndIf
		EndFunction

		Function addWeighted(map:TMap, result:TMap, weight:Float, defaultValue:Float)
			Local current:Float
			Local toAddRaw:Float
			Local value:Object
			For Local key:String = EachIn result.Keys()
				current=Float(result.ValueForKey(key).ToString())
				If map
					value=map.ValueForKey(key)
					If value
						toAddRaw = Float(value.ToString())
					Else
						toAddRaw = defaultValue
					EndIF
				Else
					toAddRaw = defaultValue
				EndIf
				current:+ weight*toAddRaw
				result.insert(key, String(current))
			Next
		EndFunction
	End Method


	Method SetFlag:int(id:int=-1, definition:TMovieFlagDefinition)
		flagDefinitions.Insert(id, definition)
	End Method


	Method GetFlag:TMovieFlagDefinition(id:Int)
		Return TMovieFlagDefinition(flagDefinitions.ValueForKey(id))
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetMovieGenreDefinitionCollection:TMovieGenreDefinitionCollection()
	Return TMovieGenreDefinitionCollection.GetInstance()
End Function

Function GetMovieGenreDefinition:TMovieGenreDefinition(genreIDs:int[])
	Return TMovieGenreDefinitionCollection.GetInstance().Get(genreIDs)
End Function

Function GetSingleMovieGenreDefinition:TMovieGenreDefinition(genreID:int)
	Return TMovieGenreDefinitionCollection.GetInstance().GetSingle(genreID)
End Function

Function GetCombinedGenreDefinition:TMovieGenreDefinition(genreIDsHash:Int, genreIDs:int[] = Null)
	Return TMovieGenreDefinitionCollection.GetInstance().GetCombined(genreIDsHash, genreIDs)
End Function



Type TMovieGenreDefinition Extends TGenreDefinitionBase
	Field OutcomeMod:Float = 0.5
	Field ReviewMod:Float = 0.3
	Field SpeedMod:Float = 0.2
	Field RefreshMod:Float = 1.0
	Field WearoffMod:Float = 1.0

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
		RefreshMod = data.GetFloat("refreshMod", 1.0)
		WearoffMod = data.GetFloat("wearoffMod", 1.0)

		GoodFollower = TList(data.Get("goodFollower"))
		If GoodFollower = Null Then GoodFollower = CreateList()
		BadFollower = TList(data.Get("badFollower"))
		If BadFollower = Null Then BadFollower = CreateList()

		'might be null!
		castAttributes = TMap(data.Get("castAttributes"))
		focusPointPriorities = TMap(data.Get("focusPointPriorities"))

		'print "Load moviegenre" + referenceId + ": " + AudienceAttraction.ToString()
		'print "RefreshMod: " + RefreshMod + " | WearoffMod: " + WearoffMod + " | OutcomeMod: " + OutcomeMod + " | ReviewMod: " + ReviewMod + " | SpeedMod: " + SpeedMod

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
		if not value or not string(value) then return 1.0

		return float(string(value))
	End Method


	Method GetPopularity:TGenrePopularity()
		Local result:TGenrePopularity=TGenrePopularity(Super.GetPopularity())
		If Not result.referenceGUID
			result.referenceGUID = "moviegenre-"+referenceID
'			print "  popularity for " +referenceID +": "+ result.referenceID
		EndIf
		Return result
	End Method


	Method GetAudienceFlowMod:SAudience(followerDefinition:TGenreDefinitionBase)
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

		Return new SAudience(modValue, modValue)
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
				result.AudienceFlowBonus.Multiply(0.2)
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




'=== POPULARITY MODIFIERS ===

Type TGameModifierPopularity_ModifyMovieGenrePopularity extends TGameModifierBase
	Field genre:int
	'value is divided by 100 - so 1000 becomes 10, 50 becomes 0.5)
	Field valueMin:Float = 0
	Field valueMax:Float = 0
	Field modifyProbability:int = 100


	'override to create this type instead of the generic one
	Function CreateNewInstance:TGameModifierPopularity_ModifyMovieGenrePopularity()
		return new TGameModifierPopularity_ModifyMovieGenrePopularity
	End Function


	Method Copy:TGameModifierPopularity_ModifyMovieGenrePopularity()
		local clone:TGameModifierPopularity_ModifyMovieGenrePopularity = new TGameModifierPopularity_ModifyMovieGenrePopularity
		clone.CopyBaseFrom(self)
		clone.genre = self.genre
		clone.valueMin = self.valueMin
		clone.valueMax = self.valueMax
		clone.modifyProbability = self.modifyProbability
		return clone
	End Method


	Method Init:TGameModifierPopularity_ModifyMovieGenrePopularity(data:TData, extra:TData=null)
		if not data then return null

		local index:string = ""
		if extra and extra.GetInt("childIndex") > 0 then index = extra.GetInt("childIndex")
		genre = data.GetInt("genre"+index, data.GetInt("genre", 0))
		if genre = 0
			TLogger.Log("TGameModifierPopularity_ModifyMovieGenrePopularity", "Init() failed - no genre (>0) given.", LOG_ERROR)
			return Null
		endif

		valueMin = data.GetFloat("valueMin"+index, 0.0)
		valueMax = data.GetFloat("valueMax"+index, 0.0)
		modifyProbability = data.GetInt("probability"+index, 100)

		return self
	End Method


	Method ToString:string()
		local name:string = data.GetString("name", "default")
		return "TGameModifierPopularity_ModifyMovieGenrePopularity ("+name+")"
	End Method


	'override to trigger a specific news
	Method RunFunc:int(params:TData)
		'skip if probability is missed
		if modifyProbability <> 100 and RandRange(0, 100) > modifyProbability then return False

		local popularity:TPopularity = GetSingleMovieGenreDefinition(genre).GetPopularity()
		if not popularity
			TLogger.Log("TGameModifierPopularity_ModifyMovieGenrePopularity", "cannot find popularity of movie genre: "+genre, LOG_ERROR)
			return false
		endif
		local changeBy:Float = RandRange(int(valueMin*1000), int(valueMax*1000))/1000.0
		'does adjust the "trend" (growth direction of popularity) not
		'popularity directly
		popularity.ChangeTrend(changeBy)
		popularity.SetPopularity(popularity.popularity + changeBy)
		'print "TGameModifierPopularity_ModifyMovieGenrePopularity: changed trend for genre ~q"+genre+"~q by "+changeBy+" to " + popularity.Popularity+"."

		return True
	End Method
End Type


GetGameModifierManager().RegisterCreateFunction("ModifyMovieGenrePopularity", TGameModifierPopularity_ModifyMovieGenrePopularity.CreateNewInstance)
