SuperStrict
Import "game.broadcast.audience.bmx"
Import "game.broadcast.audienceattraction.bmx"


'Das TAudienceResult ist sowas wie das zusammengefasste Ergebnis einer
'TBroadcast- und/oder TAudienceMarketCalculation-Berechnung.
Type TAudienceResult
	Field PlayerId:Int										'Optional: Die Id des Spielers zu dem das Result gehört.
	Field Hour:Int											'Zu welcher Stunde gehört das Result
	Field Title:String										'Der Titel des Programmes

	Field WholeMarket:TAudience	= New TAudience				'Der Gesamtmarkt: Also wenn alle die einen TV haben.
	Field PotentialMaxAudience:TAudience = New TAudience	'Die Gesamtzuschauerzahl die in dieser Stunde den TV angeschaltet hat! Also 100%-Quote! Summe aus allen Exklusiven, Flow-Leuten und Zappern
	Field Audience:TAudience = New TAudience				'Die Zahl der Zuschauer die erreicht wurden. Sozusagen das Ergenis das zählt und angezeigt wird.

	Field ChannelSurferToShare:TAudience = New TAudience	'Summe der Zapper die es zu verteilen gilt (ist nicht gleich eines ChannelSurferSum)

	Field AudienceAttraction:TAudienceAttraction			'Die ursprüngliche Attraktivität des Programmes, vor der Kunkurrenzsituation
	Field EffectiveAudienceAttraction:TAudience				'Die effektive Attraktivität des Programmes auf Grund der Konkurrenzsituation

	'Werden beim Refresh berechnet
	Field AudienceQuote:TAudience							'Die Zuschauerquote, relativ zu MaxAudienceThisHour
	Field PotentialMaxAudienceQuote:TAudience				'Die Quote von PotentialMaxAudience. Wie viel Prozent schalten ein und checken das Programm. Basis ist WholeMarket

	'Field MarketShare:Float								'Die reale Zuschauerquote, die aber noch nicht verwendet wird.


	Method AddResult(res:TAudienceResult)
		WholeMarket.Add(res.WholeMarket)
		PotentialMaxAudience.Add(res.PotentialMaxAudience)
		ChannelSurferToShare.Add(res.ChannelSurferToShare)
		Audience.Add(res.Audience)

		AudienceAttraction = res.AudienceAttraction 'Ist immer gleich, deswegen einfach zuweisen
	End Method


	'Berechnet die Quoten neu. Muss mindestens einmal aufgerufen werden.
	Method Refresh()
		Audience.FixGenderCount()
		PotentialMaxAudience.FixGenderCount()

		AudienceQuote = Audience.Copy()
		AudienceQuote.Divide(PotentialMaxAudience)

		PotentialMaxAudienceQuote = PotentialMaxAudience.Copy()
		PotentialMaxAudienceQuote.Divide(WholeMarket)
	End Method


	Method ToString:String()
		local result:string = ""
		if Audience then result :+ int(Audience.GetSum()) else result :+ "--"
		result :+ " / "
		if PotentialMaxAudience then result :+ int(PotentialMaxAudience.GetSum()) else result :+ "--"
		result :+ " / "
		if WholeMarket then result :+ int(WholeMarket.GetSum()) else result :+ "--"
		result :+ "   Q: "
		if AudienceQuote then result :+ AudienceQuote.ToStringAverage() else result :+ "--"

		return result
	End Method
End Type