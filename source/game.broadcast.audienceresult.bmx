SuperStrict
Import "game.broadcast.audience.bmx"
Import "game.broadcast.audienceattraction.bmx"


'Das TAudienceResultBase ist sowas wie das zusammengefasste Ergebnis einer
'TBroadcast- und/oder TAudienceMarketCalculation-Berechnung.
'Sie enthaelt keine Zusatzdaten (ChannelSurfer etc), diese Klasse nutzen
'um Quoten zu "archivieren"
Type TAudienceResultBase
	'Optional: Die Id des Spielers zu dem das Result gehört.
	Field PlayerId:Int
	'Zu welcher Stunde gehört das Result
	Field Hour:Int
	'Der Titel des Programmes
	Field Title:String
	'was it a outage?
	Field broadcastOutage:Int = False
	'previous audience result (so advertisement sees who watched programme)
	Field previousAudienceResult:TAudienceResultBase = Null
	'Die Zahl der Zuschauer die erreicht wurden.
	'Sozusagen das Ergenis das zählt und angezeigt wird.
	Field Audience:TAudience
	'Der Gesamtmarkt: Also wenn alle die einen TV haben.
	Field WholeMarket:TAudience
	'Die Gesamtzuschauerzahl die in dieser Stunde den TV an hat!
	'Also 100%-Quote! Summe aus allen Exklusiven, Flow-Leuten und Zappern
	Field PotentialMaxAudience:TAudience


	Method New()
		Reset()
	End Method


	Method Reset()
		Audience = New TAudience
		WholeMarket = New TAudience
		PotentialMaxAudience = New TAudience
	End Method


	'returns the average audienceresult for the given results
	Function CreateAverage:TAudienceResultBase(audienceResultBases:TAudienceResultBase[])
		local result:TAudienceResultBase = new TAudienceResultBase
		if audienceResultBases.length = 0 then return result
		'if audienceResultBases.length = 1 then return audienceResultBases[0]

		For local audienceResultBase:TAudienceResultBase = EachIn audienceResultBases
			result.Audience.Add(audienceResultBase.Audience)
			result.WholeMarket.Add(audienceResultBase.WholeMarket)
			result.PotentialMaxAudience.Add(audienceResultBase.PotentialMaxAudience)
		Next

		If audienceResultBases.length > 1
			result.Audience.DivideFloat(audienceResultBases.length)
			result.WholeMarket.DivideFloat(audienceResultBases.length)
			result.PotentialMaxAudience.DivideFloat(audienceResultBases.length)
		Endif
		
		return result
	End Function


	'instead of storing "audienceQuote" as field (bigger savegames)
	'we can create it on the fly
	'returns audience quote relative to MaxAudience of that time
	Method GetAudienceQuote:TAudience()
		if not Audience then return new TAudience

		'quote = audience / maxAudience
		return Audience.Copy().Divide(PotentialMaxAudience)
	End Method


	'instead of storing "potentialMaxAudienceQuote" as field we can
	'create it on the fly
	'returns the quote of PotentialMaxAudience. What percentage switch
	'on the TV and check the programme. Base is WholeMarket
	Method GetPotentialMaxAudienceQuote:TAudience()
		'no need to calculate a quote if the audience itself is 0 already
		'-> avoids "nan"-values when dividing with "0.0f" values
		If PotentialMaxAudience.GetSum() = 0 then return new TAudience

		'potential quote = potential audience / whole market
		return PotentialMaxAudience.Copy().Divide(WholeMarket)
	End Method


	Method ToString:String()
		local result:string = ""
		if Audience then result :+ int(Audience.GetSum()) else result :+ "--"
		result :+ " / "
		if PotentialMaxAudience then result :+ int(PotentialMaxAudience.GetSum()) else result :+ "--"
		result :+ " / "
		if WholeMarket then result :+ int(WholeMarket.GetSum()) else result :+ "--"
		result :+ "   Q: "
		result :+ GetAudienceQuote().ToStringAverage()

		return result
	End Method
End Type




'Das TAudienceResult erweitert die Basis um weitere Daten
'die aber nicht von allen Elementen benoetigt werden
Type TAudienceResult extends TAudienceResultBase
	'Summe der Zapper die es zu verteilen gilt
	'(ist nicht gleich eines ChannelSurferSum)
	Field ChannelSurferToShare:TAudience
	'Die ursprüngliche Attraktivität des Programmes, vor der
	'Kunkurrenzsituation
	Field AudienceAttraction:TAudienceAttraction
	'Die effektive Attraktivität des Programmes auf Grund der
	'Konkurrenzsituation
	Field EffectiveAudienceAttraction:TAudience

	'Die reale Zuschauerquote, die aber noch nicht verwendet wird.
	'Field MarketShare:Float

	'override with same content - so it calls "this" Reset, not Super.Reset()
	Method New()
		Reset()
	End Method


	Method Reset()
		Super.Reset()
		ChannelSurferToShare  = New TAudience
	End Method


	Method ToAudienceResultBase:TAudienceResultBase(audienceResult:TAudienceResult)
		local base:TAudienceResultBase = new TAudienceResultBase
		base.PlayerId = self.PlayerId
		base.Hour = self.Hour
		base.Title = self.Title
		base.Audience = self.Audience
		base.PotentialMaxAudience = self.PotentialMaxAudience
		base.WholeMarket = self.WholeMarket
		return base
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
	End Method
End Type