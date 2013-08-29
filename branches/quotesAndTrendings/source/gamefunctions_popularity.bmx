Type TPopularityManager
	Field Populartities:TList = CreateList()
	
	Function Create:TPopularityManager()
		Local obj:TPopularityManager = New TPopularityManager
		Return obj
	End Function
	
	Method Initialize()
	End Method

	Method Update:Int(triggerEvent:TEventBase)	
		For Local popularity:TPopulartity = EachIn Self.Populartities
			popularity.UpdatePopularity()
			popularity.AdjustTrendDirectionRandomly()
			popularity.UpdateTrend()
			'print popularity.ContentId + ": " + popularity.Popularity + " - L: " + popularity.LongTermPopularity + " - T: " + popularity.Trend + " - S: " + popularity.Surfeit
		Next		
	End Method
	
	Method AddPopularity(popularity:TPopulartity)
		Populartities.addLast(popularity)
	ENd Method
End Type


Type TPopulartity
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

	Function Create:TPopulartity(contentId:Int, populartiy:Float = 0.0, longTermPopularity:Float = 0.0)
		Local obj:TPopulartity = New TPopulartity
		obj.ContentId = contentId
		obj.SetPopularity(populartiy)
		obj.SetLongTermPopularity(longTermPopularity)
		Return obj
	End Function

	'Die Popularität wird üblicherweise am Ende des Tages aktualisiert, entsprechend des gesammelten Trend-Wertes
	Method UpdatePopularity()
		Popularity = Popularity + Trend
		If Popularity > (LongTermPopularity + SurfeitUpperBoundAdd) Then
			Surfeit = 1
			SurfeitCounter = 0
		Elseif Popularity <= (LongTermPopularity + SurfeitLowerBoundAdd) Then
			Surfeit = 0
		Elseif Popularity > (LongTermPopularity + SurfeitCounterUpperBoundAdd) Then
			SurfeitCounter = SurfeitCounter + 1 'Wird angezählt
		Else
			SurfeitCounter = 0
		Endif
		
		If SurfeitCounter > 2 Then
			Surfeit = 1
			SurfeitCounter = 0
		Endif
	End Method
	
	'Passt die LongTermPopularity mit einigen Wahrscheinlichkeiten an oder ändert sie komplett
	Method AdjustTrendDirectionRandomly()
		If RandRange(1,100) <= ChanceToChangeCompletely Then '2%-Chance das der langfristige Trend komplett umschwenkt
			SetLongTermPopularity(RandRange(LongTermPopularityLowerBound, LongTermPopularityUpperBound))
		ElseIf RandRange(1,100) <= ChanceToChange Then '10%-Chance das der langfristige Trend umschwenkt
			SetLongTermPopularity(LongTermPopularity + RandRange(ChangeLowerBound, ChangeUpperBound))
		Elseif RandRange(1,100) <= ChanceToAdjustLongTermPopulartiy Then '25%-Chance das sich die langfristige Popularität etwas dem aktuellen Trend/Popularität anpasst				
			SetLongTermPopularity(LongTermPopularity + ((Popularity-LongTermPopularity)/4) + Trend)
		Endif		
	End Method	
	
	'Der Trend wird am Anfang des Tages aktualisiert, er versucht die Populartiy an die LongTermPopularity anzugleichen.
	Method UpdateTrend()
		If (Surfeit = 1) Then
			Trend = Trend - SurfeitTrendMalus
		Else
			If (Popularity < LongTermPopularity And Trend < 0) Or (Popularity > LongTermPopularity And Trend > 0) Then
				Trend = 0
			ElseIf Trend <> 0 Then
				Trend = Trend/2
			Endif		
		
			local distance:float = (Float(LongTermPopularity) - Float(Popularity)) / TrendAdjustDivider
			Trend = Max(TrendLowerBound, Min(TrendUpperBound, Trend + distance + Float(RandRange(TrendRandRangLower, TrendRandRangUpper )/TrendAdjustDivider )))
		Endif
	End Method
	
	'Jede Ausstrahlung dieses Genres steigert den Trend, es sei denn es ist bereits eine Übersättigung ist eingetreten.
	Method ChangeTrend(changeValue:Float, adjustLongTermPopulartiy:float=0)		
		If Surfeit Then
			Trend = Trend - changeValue
		Else
			Trend = Trend + changeValue		
		Endif
		
		SetLongTermPopularity(LongTermPopularity + adjustLongTermPopulartiy)
	End Method
	
	Method SetPopularity(value:float)
		Popularity = value
	End Method	
	
	Method SetLongTermPopularity(value:float)
		LongTermPopularity = Max(LongTermPopularityLowerBound, Min(LongTermPopularityUpperBound, value))		
	End Method
End Type


Type TGenrePopulartity Extends TPopulartity
	Function Create:TGenrePopulartity(contentId:Int, populartiy:Float = 0.0, longTermPopularity:Float = 0.0)
		Local obj:TGenrePopulartity = New TGenrePopulartity
		
		obj.LongTermPopularityLowerBound		= -50
		obj.LongTermPopularityUpperBound		= 50

		obj.SurfeitLowerBoundAdd				= -30
		obj.SurfeitUpperBoundAdd				= 35
		obj.SurfeitTrendMalus					= 5
		obj.SurfeitCounterUpperBoundAdd			= 3
	
		obj.TrendLowerBound						= -10	
		obj.TrendUpperBound						= 10
		obj.TrendAdjustDivider					= 5
		obj.TrendRandRangLower					= -15
		obj.TrendRandRangUpper					= 15
		
		obj.ChanceToChangeCompletely			= 2
		obj.ChanceToChange						= 10
		obj.ChanceToAdjustLongTermPopulartiy	= 25
		
		obj.ChangeLowerBound					= -25
		obj.ChangeUpperBound					= 25	
		
		obj.ContentId = contentId
		obj.SetPopularity(populartiy)
		obj.SetLongTermPopularity(longTermPopularity)			
		
		Return obj
	End Function	
End Type