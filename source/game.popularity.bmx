Import Brl.LinkedList
Import "Dig/base.util.event.bmx"
Import "Dig/base.util.mersenne.bmx"



Type TPopularityManager
	Field Popularities:TList = CreateList()
	Field updateInterval:int = 720	'update every x minutes (720 = 12*60)
	Field updateTimeLeft:int = 720	'time till next update (in game minutes)
	Field _initialized:int = FALSE
	Global _instance:TPopularityManager


	Function GetInstance:TPopularityManager()
		if not _instance then _instance = new TPopularityManager
		return _instance
	End Function


	'reinitializes the manager
	Method Reset()
		_initialized = FALSE
		Initialize()
	End Method


	Method Initialize:int()
		if _initialized then return TRUE

		'reset list
		Popularities = CreateList()

		_initialized = TRUE
	End Method


	'call this once a game minuted
	Method Update:Int(triggerEvent:TEventBase)
		updateTimeLeft :- 1
		'do not update until interval is gone
		if updateTimeLeft > 0 then return FALSE

		'print "TPopularityManager: Updating popularities"
		For Local popularity:TPopularity = EachIn Self.Popularities
			popularity.UpdatePopularity()
			popularity.AdjustTrendDirectionRandomly()
			popularity.UpdateTrend()
			'print " - cId "+popularity.ContentId + ":  P: " + popularity.Popularity + " - L: " + popularity.LongTermPopularity + " - T: " + popularity.Trend + " - S: " + popularity.Surfeit
		Next
		'reset time till next update
		updateTimeLeft = updateInterval
	End Method


	Method RemovePopularity(popularity:TPopularity)
		Popularities.Remove(popularity)
	End Method


	Method AddPopularity(popularity:TPopularity)
		Popularities.addLast(popularity)
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetPopularityManager:TPopularityManager()
	Return TPopularityManager.GetInstance()
End Function




Type TPopularity
	Field ContentId:Int
	Field LongTermPopularity:Float				'Zu welchem Wert entwickelt sich die Popularität langfristig ohne den Spielereinfluss (-50 bis +50)
	Field Popularity:Float						'Wie populär ist das Genre. Ein Wert üblicherweise zwischen -50 und +100 (es kann aber auch mehr oder weniger werden...)
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

	Function Create:TPopularity(contentId:Int, popularity:Float = 0.0, longTermPopularity:Float = 0.0)
		Local obj:TPopularity = New TPopularity
		obj.ContentId = contentId
		obj.SetPopularity(popularity)
		obj.SetLongTermPopularity(longTermPopularity)
		'obj.LogFile = TLogFile.Create("Popularity Log", "PopularityLog" + contentId + ".txt")
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