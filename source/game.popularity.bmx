SuperStrict
Import Brl.LinkedList
Import "Dig/base.util.event.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "game.modifier.base.bmx"


Type TPopularityManager
	'managed popularities by their ID
	Field popularities:TIntMap = New TIntMap
	'managed popularities by the referenceID they use (eg of a person or so)
	Field popularityReferenceIDs:TIntMap = New TIntMap
	Field popularityReferenceGUIDs:TStringMap = New TStringMap
	'update every x minutes (720 = 12*60)
	Field updateInterval:int = 720
	'time till next update (in game minutes)
	Field updateTimeLeft:int = 720
	Global _instance:TPopularityManager


	Function GetInstance:TPopularityManager()
		if not _instance then _instance = new TPopularityManager
		return _instance
	End Function


	Method Initialize:int()
		'reset lists
		popularities.Clear()
		popularityReferenceIDs.Clear()
		popularityReferenceGUIDs.Clear()
		updateInterval = 720
		updateTimeLeft = 720
	End Method
	
	
	Method GetByReferenceID:TPopularity(ID:Int)
		Return TPopularity(popularityReferenceIDs.ValueForKey(ID))
	End Method


	Method GetByReferenceGUID:TPopularity(GUID:String)
		Return TPopularity(popularityReferenceGUIDs.ValueForKey(GUID.ToLower()))
	End Method

	
	Method GetByID:TPopularity(ID:Int)
		Return TPopularity(popularities.ValueForKey(ID))
	End Method


	'call this once a game minute
	Method Update:Int(triggerEvent:TEventBase)
		updateTimeLeft :- 1
		'do not update until interval is gone
		if updateTimeLeft > 0 then return FALSE

		'print "TPopularityManager: Updating popularities"
		For Local popularity:TPopularity = EachIn popularities.Values()
			popularity.UpdatePopularity()
			popularity.AdjustTrendDirectionRandomly()
			popularity.UpdateTrend()
			'print " - referenceGUID "+popularity.referenceGUID + ":  P: " + popularity.Popularity + " - L: " + popularity.LongTermPopularity + " - T: " + popularity.Trend + " - S: " + popularity.Surfeit
		Next
		'reset time till next update
		updateTimeLeft = updateInterval
	End Method


	Method RemovePopularity(popularity:TPopularity)
		popularities.Remove(popularity.GetID())
		popularityReferenceIDs.Remove(popularity.referenceID)
		popularityReferenceGUIDs.Remove(popularity.referenceGUID)
	End Method


	Method AddPopularity(popularity:TPopularity)
		popularities.insert(popularity.GetID(), popularity)
		If popularity.referenceID
			popularityReferenceIDs.insert(popularity.referenceID, popularity)
		EndIf
		If popularity.referenceGUID
			popularityReferenceGUIDs.insert(popularity.referenceGUID, popularity)
		EndIf
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetPopularityManager:TPopularityManager()
	Return TPopularityManager.GetInstance()
End Function




Type TPopularity
	Field ID:Int
	Field referenceID:Int
	Field referenceGUID:String
	'long term target value of the popularity without
	'player influences (-50 to +50)
	Field longTermPopularity:Float
	'popularity of the element. Value normally between
	'-50 and +100 
	Field popularity:Float
	'how popularity will develop
	Field trend:Float
	'1 = trend is oversaturated
	Field surfeit:Int
	'if this is 3 then it is over-saturated
	Field surfeitCounter:Int

	'Untere/Obere Grenze der LongTermPopularity
	Field longTermPopularityLowerBound:Int
	Field longTermPopularityUpperBound:Int

	'Surfeit wird erreicht, wenn
	'Popularity > (LongTermPopularity + SurfeitUpperBoundAdd)
	Field SurfeitLowerBoundAdd:Int
	'Surfeit wird zurückgesetzt, wenn
	'Popularity <= (LongTermPopularity + SurfeitLowerBoundAdd)
	Field SurfeitUpperBoundAdd:Int
	'Für welchen Abzug sorgt die Übersättigung
	Field SurfeitTrendMalus:Int
	'Wie viel darf die Popularity über LongTermPopularity um angezählt zu werden?
	Field SurfeitCounterUpperBoundAdd:Int

	'Untergrenze für den Bergabtrend
	Field TrendLowerBound:Int
	'Obergrenze für den Bergauftrend
	Field TrendUpperBound:Int
	'Um welchen Teiler wird der Trend angepasst?
	Field TrendAdjustDivider:Int
	'Untergrenze/Obergrenze für Zufallsänderungen des Trends
	Field TrendRandRangLower:Int
	Field TrendRandRangUpper:Int

	'X%-Chance das sich die LongTermPopularity komplett wendet
	Field ChanceToChangeCompletely:Int
	'X%-Chance das sich die LongTermPopularity um einen Wert zwischen
	'ChangeLowerBound und ChangeUpperBound ändert
	Field ChanceToChange:Int
	'X%-Chance das sich die LongTermPopularity an den aktuellen
	'Popularitywert + Trend anpasst
	Field ChanceToAdjustLongTermPopularity:Int

	'Untergrenze/Obergrenze für Wertänderung wenn ChanceToChange eintritt
	Field ChangeLowerBound:Int
	Field ChangeUpperBound:Int

	Global _lastID:Int
	
	
	Method New()
		_lastID :+ 1
		ID = _lastID
	End Method

	
	Function Create:TPopularity(referenceGUID:String, referenceID:Int, popularity:Float = 0.0, longTermPopularity:Float = 0.0)
		Local obj:TPopularity = New TPopularity
		obj.referenceGUID = referenceGUID
		obj.referenceID = referenceID
		obj.SetPopularity(popularity)
		obj.SetLongTermPopularity(longTermPopularity)
		'obj.LogFile = TLogFile.Create("Popularity Log", "PopularityLog" + referenceGUID + ".txt")
		Return obj
	End Function
	
	
	Method GetID:Int()
		return ID
	End Method


	'Die Popularität wird üblicherweise am Ende des Tages aktualisiert,
	'entsprechend des gesammelten Trend-Wertes
	Method UpdatePopularity()
		Popularity = Popularity + Trend
		'Über dem absoluten Maximum
		If Popularity > LongTermPopularityUpperBound Then
			'Popularity = RandRange(LongTermPopularityUpperBound - 5, LongTermPopularityUpperBound + 5)
			If Popularity > LongTermPopularityUpperBound + SurfeitUpperBoundAdd Then
				StartSurfeit()
			Elseif Surfeit = 0 Then
				SurfeitCounter = SurfeitCounter + 1 'Wird angezählt
			Endif
		'Unter dem absoluten Minimum
		Elseif Popularity < LongTermPopularityLowerBound Then
			Popularity = RandRange(LongTermPopularityLowerBound - 5, LongTermPopularityLowerBound + 5)
			SetLongTermPopularity(LongTermPopularity + RandRange(0, 15))
		'Über dem Langzeittrend
		Elseif Popularity > (LongTermPopularity + SurfeitUpperBoundAdd) Then
			If Surfeit = 0 Then
				SurfeitCounter = SurfeitCounter + 1 'Wird angezählt
			Endif
		'Unter dem Langzeittrend
		Elseif Popularity <= (LongTermPopularity + SurfeitLowerBoundAdd) Then
			Popularity = Popularity + RandRange(0, 5)
		Elseif Popularity < (LongTermPopularityUpperBound / 4) Then
			SurfeitCounter = 0
		Endif

		If SurfeitCounter >= SurfeitCounterUpperBoundAdd Then
			StartSurfeit()
		Elseif Surfeit = 1 And Popularity <= LongTermPopularity Then
			EndSurfeit()
		Endif

		'LogFile.AddLog(Popularity + ";" + LongTermPopularity + ";" + Trend + ";" + Surfeit + ";" + SurfeitCounter, False)
	End Method


	Method StartSurfeit()
		Surfeit = 1
		SurfeitCounter = 0
		SetLongTermPopularity(RandRange(LongTermPopularityLowerBound, 0))
	End Method


	Method EndSurfeit()
		Surfeit = 0
		SurfeitCounter = 0
		SetLongTermPopularity(Popularity + RandRange(0, 15))
	End Method


	'Passt die LongTermPopularity mit einigen Wahrscheinlichkeiten an
	'oder ändert sie komplett
	Method AdjustTrendDirectionRandomly()
		Local rnd:Int = RandRange(1,100)
		'Local oldVal:Float = longTermPopularity
		'2%-Chance das der langfristige Trend komplett umschwenkt
		If rnd <= ChanceToChangeCompletely Then
			SetLongTermPopularity(RandRange(LongTermPopularityLowerBound, LongTermPopularityUpperBound))
			'print "changing popularity completely "+referenceGUID +": "+oldVal+"->"+longTermPopularity
		'10%-Chance das der langfristige Trend umschwenkt
		ElseIf rnd <= ChanceToChange Then
			'favour small changes
			SetLongTermPopularity(LongTermPopularity + Int(GaussRandRange(ChangeLowerBound, ChangeUpperBound, 0.5, 0.25)))
			'print "changing Long Term popularity "+referenceGUID+": "+oldVal+"->"+longTermPopularity
		'25%-Chance das sich die langfristige Popularität etwas dem aktuellen Trend/Popularität anpasst
		Elseif rnd <= ChanceToAdjustLongTermPopularity Then
			SetLongTermPopularity(LongTermPopularity + ((Popularity-LongTermPopularity)/2) + Trend)
			'print "adjust trend popularity "+referenceGUID+": "+oldVal+"->"+longTermPopularity +" Pop:"+Popularity+ " Trend:"+Trend
		Endif
	End Method


	'Der Trend wird am Anfang des Tages aktualisiert, er versucht die
	'Popularity an die LongTermPopularity anzugleichen.
	Method UpdateTrend()
		If Surfeit = 1 Then
			Trend = Trend - SurfeitTrendMalus
		Else
			If (Popularity < LongTermPopularity And Trend < 0) Or (Popularity > LongTermPopularity And Trend > 0) Then
				Trend = 0
			ElseIf Trend <> 0 Then
				Trend = Trend/2
			Endif

			local distance:float = (LongTermPopularity - Popularity) / TrendAdjustDivider
			Local random:Float = Float(RandRange(TrendRandRangLower, TrendRandRangUpper ))/TrendAdjustDivider
			Trend = Max(TrendLowerBound, Min(TrendUpperBound, Trend + distance + random))
		Endif
	End Method


	'Every broadcast of a genre, every activity of a person, ...
	'adjusts the trend (except surfeit kicked in already)
	Method ChangeTrend(changeValue:Float, adjustLongTermPopularity:float=0)
		If Surfeit
			'when subtracting - this would add then...
			'Trend :- changeValue

			Trend :- Max(0, changeValue)
		Else
			Trend :+ changeValue
		Endif

		If adjustLongTermPopularity <> 0
			SetLongTermPopularity(LongTermPopularity + adjustLongTermPopularity)
		Endif
	End Method


	Method SetPopularity(value:float)
		Popularity = value
	End Method


	Method ModifyPopularity(addPercentage:Float = 0.0, addValue:Float = 0.0)
		if addPercentage <> 0.0
			Popularity :* (1.0 + addPercentage)
		endif

		Popularity :+ addValue
	End Method


	Method SetLongTermPopularity(value:float)
		LongTermPopularity = Max(LongTermPopularityLowerBound, Min(LongTermPopularityUpperBound, value))
	End Method
End Type




'=== POPULARITY MODIFIERS ===

Type TGameModifierPopularity_ModifyPopularity extends TGameModifierBase
	Field popularityReferenceID:Int = 0
	Field popularityReferenceGUID:String = 0
	Field popularityID:Int = 0
	'value is divided by 100 - so 1000 becomes 10, 50 becomes 0.5)
	Field valueMin:Float = 0
	Field valueMax:Float = 0
	Field modifyProbability:int = 100


	'override to create this type instead of the generic one
	Function CreateNewInstance:TGameModifierPopularity_ModifyPopularity()
		return new TGameModifierPopularity_ModifyPopularity
	End Function
	
	
	Method CopyFrom(other:TGameModifierPopularity_ModifyPopularity)
		popularityID = other.popularityID
		popularityReferenceID = other.popularityReferenceID
		valueMin = other.valueMin
		valueMax = other.valueMax
		modifyProbability = other.modifyProbability
	End Method
	
	
	Method Copy:TGameModifierPopularity_ModifyPopularity()
		local clone:TGameModifierPopularity_ModifyPopularity = new TGameModifierPopularity_ModifyPopularity

		clone.CopyBaseFrom(self)
		clone.CopyFrom(self)

		return clone
	End Method


	Method Init:TGameModifierPopularity_ModifyPopularity(data:TData, extra:TData=null)
		if not data then return null

		local index:string = ""
		if extra and extra.GetInt("childIndex") > 0 then index = extra.GetInt("childIndex")
		popularityID = data.GetInt("id"+index, data.GetInt("id", 0))
		popularityReferenceID = data.GetInt("referenceID"+index, data.GetInt("referenceID", 0))
		popularityReferenceGUID = data.GetString("referenceGUID"+index, data.GetString("referenceGUID", ""))
		if popularityID = 0 and popularityReferenceID = 0 and popularityReferenceGUID = ""
			TLogger.Log(ToString(), "Init() failed - no popularityID or referenceID/referenceGUID given.", LOG_ERROR)
			return Null
		endif

		valueMin = data.GetFloat("valueMin"+index, 0.0)
		valueMax = data.GetFloat("valueMax"+index, 0.0)
		modifyProbability = data.GetInt("probability"+index, 100)

		return self
	End Method


	Method ToString:string()
		local name:string = ""
		if data then name = data.GetString("name", "default")
		return "TGameModifierPopularity_ModifyPopularity ("+name+")"
	End Method
	
	
	Method GetPopularity:TPopularity()
		local popularity:TPopularity
		If popularityID > 0
			popularity = GetPopularityManager().GetByID(popularityID)
		EndIf
		If not popularity and popularityReferenceID > 0
			popularity = GetPopularityManager().GetByReferenceID(popularityReferenceID)
		ElseIf not popularity and popularityReferenceGUID
			popularity = GetPopularityManager().GetByReferenceGUID(popularityReferenceGUID)
		EndIf
		Return popularity
	End Method


	'override to change the popularity
	Method RunFunc:int(params:TData)
		'skip if probability is missed
		if modifyProbability <> 100 and RandRange(0, 100) > modifyProbability then return False

		local popularity:TPopularity = GetPopularity()
		if not popularity
			TLogger.Log(ToString(), "cannot find popularity to trigger: ID=" + popularityID + "  referenceGUID=~q" + popularityReferenceGUID + "~q   referenceID=" + popularityReferenceID, LOG_ERROR)
			return false
		endif
		local changeBy:Float = RandRange(int(valueMin*1000), int(valueMax*1000))/1000.0
		'does adjust the "trend" (growth direction of popularity) not
		'popularity directly
		popularity.ChangeTrend(changeBy)
		popularity.SetPopularity(popularity.popularity + changeBy)
		'print "TGameModifierPopularity_ModifyPopularity: changed trend for ~q"+popularityGUID+"~q by "+changeBy+" to " + popularity.Popularity+"."

		return True
	End Method
End Type


GetGameModifierManager().RegisterCreateFunction("ModifyPopularity", TGameModifierPopularity_ModifyPopularity.CreateNewInstance)
