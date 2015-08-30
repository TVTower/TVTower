SuperStrict
Import "game.broadcast.audience.bmx"
Import "game.broadcast.audienceattraction.bmx"
Import "game.broadcastmaterial.base.bmx"


'Das TAudienceResultBase ist sowas wie das zusammengefasste Ergebnis einer
'TBroadcast- und/oder TAudienceMarketCalculation-Berechnung.
'Sie enthaelt keine Zusatzdaten (ChannelSurfer etc), diese Klasse nutzen
'um Quoten zu "archivieren"
Type TAudienceResultBase
	'Optional: Die Id des Spielers zu dem das Result gehört.
	Field PlayerId:Int
	'Der Titel des Programmes
	Field Title:String
	'Zu welcher Stunde gehört das Result
	Field Hour:Int
	Field broadcastMaterial:TBroadcastMaterial
	'was it an outage (programme was not sent)?
	Field broadcastOutage:Int = False
	'Die Zahl der Zuschauer die erreicht wurden.
	'Sozusagen das Ergenis das zählt und angezeigt wird.
	Field Audience:TAudience
	'Der Gesamtmarkt: Also wenn alle die einen TV haben schauen wuerden
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
			result.GetPotentialMaxAudience().Add(audienceResultBase.GetPotentialMaxAudience())
		Next

		If audienceResultBases.length > 1
			result.Audience.DivideFloat(audienceResultBases.length)
			result.WholeMarket.DivideFloat(audienceResultBases.length)
			result.GetPotentialMaxAudience().DivideFloat(audienceResultBases.length)
		Endif
		
		return result
	End Function


	Method GetTitle:string()
		if title <> "" then return title
		if broadcastMaterial then return broadcastMaterial.GetTitle()
		return ""
	End Method


	Method GetPotentialMaxAudience:TAudience()
		if not PotentialMaxAudience then PotentialMaxAudience = new TAudience
		return PotentialMaxAudience
	End Method

	'instead of storing "audienceQuote" as field (bigger savegames)
	'we can create it on the fly
	'returns audience quote relative to MaxAudience of that time
	'ATTENTION: to fetch the effective total audiencequote use
	'           "GetWeightedAverage()" instead of "GetAverage()" as the
	'           target groups are not equally weighted.
	Method GetAudienceQuote:TAudience()
		if not Audience then return new TAudience

		'quote = audience / maxAudience
		return Audience.Copy().Divide( GetPotentialMaxAudience() )
	End Method


	'returns the percentage (0-1.0) of reached audience compared to
	'potentially reachable audience (in front of TV at that moment)
	Method GetAudienceQuotePercentage:Float()
'		return Audience.GetSum() / GetPotentialMaxAudience().GetSum()
		return GetAudienceQuote().GetSum()
	End Method
	

	'instead of storing "potentialMaxAudienceQuote" as field we can
	'create it on the fly
	'returns the quote of PotentialMaxAudience. What percentage switched
	'on the TV and checked the programme. Base is WholeMarket
	'ATTENTION: to fetch the effective total audiencequote use
	'           "GetWeightedAverage()" instead of "GetAverage()" as the
	'           target groups are not equally weighted.
	Method GetPotentialMaxAudienceQuote:TAudience()
		'no need to calculate a quote if the audience itself is 0 already
		'-> avoids "nan"-values when dividing with "0.0f" values
		If GetPotentialMaxAudience().GetSum() = 0 then return new TAudience

		'potential quote = potential audience / whole market
		return GetPotentialMaxAudience().Copy().Divide(WholeMarket)
	End Method


	'returns the percentage (0-1.0) of practically reachable audience
	'(switched on the TV) compared to technically reachable audience
	'(within range of the broadcast area)
	Method GetPotentialMaxAudienceQuotePercentage:Float()
		return GetPotentialMaxAudienceQuote().GetAverage()
	End Method


	'returns the quote of reached audience to WholeMarket.
	'What percentage of all people having a TV watched the programme
	'ATTENTION: to fetch the effective total audience quote use
	'           "GetWeightedAverage()" instead of "GetAverage()" as the
	'           target groups are not equally weighted.
	Method GetWholeMarketAudienceQuote:TAudience()
		'no need to calculate a quote if the audience itself is 0 already
		'-> avoids "nan"-values when dividing with "0.0f" values
		If not Audience or Audience.GetSum() = 0 then return new TAudience

		'total quote = audience / whole market
		return Audience.Copy().Divide(WholeMarket)
	End Method


	'returns the percentage (0-1.0) of reached audience (switched on TV
	'and watching your channel) compared to technically reachable audience
	'(within range of the broadcast area)
	Method GetWholeMarketAudienceQuotePercentage:Float()
		return GetWholeMarketAudienceQuote().GetAverage()
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
		base.broadcastMaterial = self.broadcastMaterial
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