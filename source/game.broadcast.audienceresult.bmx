SuperStrict
Import "game.broadcast.audience.bmx"
Import "game.broadcast.audienceattraction.bmx"


'Das TAudienceResult ist sowas wie das zusammengefasste Ergebnis einer
'TBroadcast- und/oder TAudienceMarketCalculation-Berechnung.
Type TAudienceResult
	'Optional: Die Id des Spielers zu dem das Result gehört.
	Field PlayerId:Int
	'Zu welcher Stunde gehört das Result
	Field Hour:Int
	'Der Titel des Programmes
	Field Title:String

	'Der Gesamtmarkt: Also wenn alle die einen TV haben.
	Field WholeMarket:TAudience
	'Die Gesamtzuschauerzahl die in dieser Stunde den TV an hat!
	'Also 100%-Quote! Summe aus allen Exklusiven, Flow-Leuten und Zappern
	Field PotentialMaxAudience:TAudience
	'Die Zahl der Zuschauer die erreicht wurden.
	'Sozusagen das Ergenis das zählt und angezeigt wird.
	Field Audience:TAudience
	'Summe der Zapper die es zu verteilen gilt
	'(ist nicht gleich eines ChannelSurferSum)
	Field ChannelSurferToShare:TAudience
	'Die ursprüngliche Attraktivität des Programmes, vor der
	'Kunkurrenzsituation
	Field AudienceAttraction:TAudienceAttraction
	'Die effektive Attraktivität des Programmes auf Grund der
	'Konkurrenzsituation
	Field EffectiveAudienceAttraction:TAudience

	'=== werden beim Refresh berechnet ===
	'Die Zuschauerquote, relativ zu MaxAudienceThisHour
	Field AudienceQuote:TAudience
	'Die Quote von PotentialMaxAudience. Wie viel Prozent schalten ein
	'und checken das Programm. Basis ist WholeMarket
	Field PotentialMaxAudienceQuote:TAudience

	'Die reale Zuschauerquote, die aber noch nicht verwendet wird.
	'Field MarketShare:Float


	Method New()
		Reset()
	End Method


	Method Reset()
		WholeMarket = New TAudience
		PotentialMaxAudience = New TAudience
		Audience = New TAudience
		ChannelSurferToShare  = New TAudience

		AudienceQuote = Null
		PotentialMaxAudienceQuote = Null
	End Method


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

		'quote = audience / maxAudience
		AudienceQuote = Audience.Copy().Divide(PotentialMaxAudience)

		'no need to calculate a quote if the audience itself is 0 already
		'-> avoids "nan"-values when dividing with "0.0f" values
		If PotentialMaxAudience.GetSum() = 0
			PotentialMaxAudienceQuote = new TAudience
		Else
			'potential quote = potential audience / whole market
			PotentialMaxAudienceQuote = PotentialMaxAudience.Copy().Divide(WholeMarket)
		EndIf
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