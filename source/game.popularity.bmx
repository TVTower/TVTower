Import Brl.LinkedList
Import "Dig/base.util.event.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "game.modifier.base.bmx"


Type TPopularityManager
	Field Popularities:TMap = CreateMap()
	Field updateInterval:int = 720	'update every x minutes (720 = 12*60)
	Field updateTimeLeft:int = 720	'time till next update (in game minutes)
	Global _instance:TPopularityManager


	Function GetInstance:TPopularityManager()
		if not _instance then _instance = new TPopularityManager
		return _instance
	End Function


	Method Initialize:int()
		'reset list
		Popularities = CreateMap()
	End Method


	Method GetByGUID:TPopularity(GUID:String)
		Return TPopularity(Popularities.ValueForKey(GUID))
	End Method


	'call this once a game minute
	Method Update:Int(triggerEvent:TEventBase)
		updateTimeLeft :- 1
		'do not update until interval is gone
		if updateTimeLeft > 0 then return FALSE

		'print "TPopularityManager: Updating popularities"
		For Local popularity:TPopularity = EachIn Self.Popularities.Values()
			popularity.UpdatePopularity()
			popularity.AdjustTrendDirectionRandomly()
			popularity.UpdateTrend()
			'print " - referenceGUID "+popularity.referenceGUID + ":  P: " + popularity.Popularity + " - L: " + popularity.LongTermPopularity + " - T: " + popularity.Trend + " - S: " + popularity.Surfeit
		Next
		'reset time till next update
		updateTimeLeft = updateInterval
	End Method


	Method RemovePopularity(popularity:TPopularity)
		Popularities.Remove(popularity.referenceGUID.ToLower())
	End Method


	Method AddPopularity(popularity:TPopularity)
		Popularities.insert(popularity.referenceGUID.ToLower(), popularity)
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetPopularityManager:TPopularityManager()
	Return TPopularityManager.GetInstance()
End Function




Type TPopularity
	Field referenceGUID:string
	Field LongTermPopularity:Float				'Zu welchem Wert entwickelt sich die Popularität langfristig ohne den Spielereinfluss (-50 bis +50)
	Field Popularity:Float						'Wie populär ist das Element. Ein Wert üblicherweise zwischen -50 und +100 (es kann aber auch mehr oder weniger werden...)
	Field Trend:Float							'Wie entwicklet sich die Popularität
	Field Surfeit:Int							'1 = Übersättigung des Trends
	Field SurfeitCounter:Int					'Wenn bei 3, dann ist er übersättigt

	Field LongTermPopularityLowerBound:Int		'Untere Grenze der LongTermPopularity
	Field LongTermPopularityUpperBound:Int		'Obere Grenze der LongTermPopularity

	Field SurfeitLowerBoundAdd:Int				'Surfeit wird erreicht, wenn Popularity > (LongTermPopularity + SurfeitUpperBoundAdd)
	Field SurfeitUpperBoundAdd:Int				'Surfeit wird zurückgesetzt, wenn Popularity <= (LongTermPopularity + SurfeitLowerBoundAdd)
	Field SurfeitTrendMalus:Int					'Für welchen Abzug sorgt die Übersättigung
	Field SurfeitCounterUpperBoundAdd:Int		'Wie viel darf die Popularity über LongTermPopularity um angezählt zu werden?

	Field TrendLowerBound:Int					'Untergrenze für den Bergabtrend
	Field TrendUpperBound:Int					'Obergrenze für den Bergauftrend
	Field TrendAdjustDivider:Int				'Um welchen Teiler wird der Trend angepasst?
	Field TrendRandRangLower:Int				'Untergrenze für Zufallsänderungen des Trends
	Field TrendRandRangUpper:Int				'Obergrenze für Zufallsänderungen des Trends

	Field ChanceToChangeCompletely:Int			'X%-Chance das sich die LongTermPopularity komplett wendet
	Field ChanceToChange:Int					'X%-Chance das sich die LongTermPopularity um einen Wert zwischen ChangeLowerBound und ChangeUpperBound ändert
	Field ChanceToAdjustLongTermPopulartiy:Int	'X%-Chance das sich die LongTermPopularity an den aktuellen Populartywert + Trend anpasst

	Field ChangeLowerBound:Int					'Untergrenze für Wertänderung wenn ChanceToChange eintritt
	Field ChangeUpperBound:Int					'Obergrenze für Wertänderung wenn ChanceToChange eintritt

	'Field LogFile:TLogFile

	Function Create:TPopularity(referenceGUID:string, popularity:Float = 0.0, longTermPopularity:Float = 0.0)
		Local obj:TPopularity = New TPopularity
		obj.referenceGUID = referenceGUID
		obj.SetPopularity(popularity)
		obj.SetLongTermPopularity(longTermPopularity)
		'obj.LogFile = TLogFile.Create("Popularity Log", "PopularityLog" + referenceGUID + ".txt")
		Return obj
	End Function


	'Die Popularität wird üblicherweise am Ende des Tages aktualisiert, entsprechend des gesammelten Trend-Wertes
	Method UpdatePopularity()
		Popularity = Popularity + Trend
		If Popularity > LongTermPopularityUpperBound Then 'Über dem absoluten Maximum
			'Popularity = RandRange(LongTermPopularityUpperBound - 5, LongTermPopularityUpperBound + 5)
			If Popularity > LongTermPopularityUpperBound + SurfeitUpperBoundAdd Then
				StartSurfeit()
			Elseif Surfeit = 0 Then
				SurfeitCounter = SurfeitCounter + 1 'Wird angezählt
			Endif
		Elseif Popularity < LongTermPopularityLowerBound Then 'Unter dem absoluten Minimum
			Popularity = RandRange(LongTermPopularityLowerBound - 5, LongTermPopularityLowerBound + 5)
			SetLongTermPopularity(LongTermPopularity + RandRange(0, 15))
		Elseif Popularity > (LongTermPopularity + SurfeitUpperBoundAdd) Then 'Über dem Langzeittrend
			If Surfeit = 0 Then
				SurfeitCounter = SurfeitCounter + 1 'Wird angezählt
			Endif
		Elseif Popularity <= (LongTermPopularity + SurfeitLowerBoundAdd) Then 'Unter dem Langzeittrend
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

	'Passt die LongTermPopularity mit einigen Wahrscheinlichkeiten an oder ändert sie komplett
	Method AdjustTrendDirectionRandomly()
		If RandRange(1,100) <= ChanceToChangeCompletely Then '2%-Chance das der langfristige Trend komplett umschwenkt
			SetLongTermPopularity(RandRange(LongTermPopularityLowerBound, LongTermPopularityUpperBound))
		ElseIf RandRange(1,100) <= ChanceToChange Then '10%-Chance das der langfristige Trend umschwenkt
			SetLongTermPopularity(LongTermPopularity + RandRange(ChangeLowerBound, ChangeUpperBound))
		Elseif RandRange(1,100) <= ChanceToAdjustLongTermPopulartiy Then '25%-Chance das sich die langfristige Popularität etwas dem aktuellen Trend/Popularität anpasst
			SetLongTermPopularity(LongTermPopularity + ((Popularity-LongTermPopularity)/2) + Trend)
		Endif
	End Method


	'Der Trend wird am Anfang des Tages aktualisiert, er versucht die Populartiy an die LongTermPopularity anzugleichen.
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


	'Jede Ausstrahlung dieses Genres steigert den Trend, es sei denn es ist bereits eine Übersättigung ist eingetreten.
	Method ChangeTrend(changeValue:Float, adjustLongTermPopulartiy:float=0)
		If Surfeit Then
			Trend = Trend - changeValue
		Else
			Trend = Trend + changeValue
		Endif

		If adjustLongTermPopulartiy <> 0 Then
			SetLongTermPopularity(LongTermPopularity + adjustLongTermPopulartiy)
		Endif
	End Method


	Method SetPopularity(value:float)
		Popularity = value
	End Method


	Method SetLongTermPopularity(value:float)
		LongTermPopularity = Max(LongTermPopularityLowerBound, Min(LongTermPopularityUpperBound, value))
	End Method
End Type




Type TGameModifierPopularity_ModifyPopularity extends TGameModifierBase
	Field popularityGUID:string = ""
	Field valueMin:int = 0
	Field valueMax:int = 0
	Field modifyProbability:int = 100
	

	Function CreateFromData:TGameModifierPopularity_ModifyPopularity(data:TData, index:string="")
		if not data then return null

		'local source:TNewsEvent = TNewsEvent(data.get("source"))
		local popularityGUID:string = data.GetString("guid"+index, data.GetString("guid", ""))
		if popularityGUID = "" then return Null

		local obj:TGameModifierPopularity_ModifyPopularity = new TGameModifierPopularity_ModifyPopularity
		obj.valueMin = data.GetInt("valueMin"+index, 0)
		obj.valueMax = data.GetInt("valueMax"+index, 0)
		obj.modifyProbability = data.GetInt("probability"+index)

		return obj
	End Function
	
	
	Method ToString:string()
		local name:string = data.GetString("name", "default")
		return "TGameModifierPopularity_ModifyPopularity ("+name+")"
	End Method


	'override to trigger a specific news
	Method RunFunc:int(params:TData)
		'skip if probability is missed
		if modifyProbability <> 100 and RandRange(0, 100) > triggerProbability then return False

		local popularity:TPopularity = GetPopularityManager().GetByGUID(popularityGUID)
		if not popularity
			TLogger.Log("TGameModifierPopularity_ModifyPopularity", "cannot find popularity to trigger: "+popularityGUID, LOG_ERROR)
			return false
		endif
		local changeBy:int = RandRange(valueMin, valueMax)
		popularity.ChangeTrend( changeBy )
		print "changed trend: "+changeBy

		return True
	End Method
End Type
