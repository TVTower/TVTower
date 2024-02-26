SuperStrict
Import "game.broadcast.audience.bmx"
Import "game.broadcast.audienceattraction.bmx"
Import "game.broadcastmaterial.base.bmx"


'Das TAudienceResultBase ist sowas wie das zusammengefasste Ergebnis einer
'TBroadcast- und/oder TAudienceMarketCalculation-Berechnung.
'Sie enthaelt keine Zusatzdaten (ChannelSurfer etc), diese Klasse nutzen
'um Quoten zu "archivieren"
Type TAudienceResultBase {_exposeToLua="selected"}
	'Optional: Die Id des Spielers zu dem das Result gehört.
	Field PlayerId:Int
	'time of the broadcast this result belongs to
	Field Time:Long
	'the broadcast material used to calculate this audience result
	Field broadcastMaterial:TBroadcastMaterial
	'outage marker (programme was not sent?)
	Field broadcastOutage:Int = False
	'actually reached audience (so the result which counts and is displayed)
	Field Audience:TAudience {_exposeToLua}
	'market of all people who have a TV and are thus capable of watching something
	Field WholeMarket:TAudience
	'Die Gesamtzuschauerzahl die in dieser Stunde den TV an hat!
	'Also 100%-Quote! Summe aus allen Exklusiven, Flow-Leuten und Zappern
	Field PotentialAudience:TAudience


	Method New()
		Reset()
	End Method


	Method CopyFrom:TAudienceResultBase(other:TAudienceResultBase)
		if other
			PlayerId = other.PlayerId
			Time = other.Time
			broadcastMaterial = other.broadcastMaterial
			Audience = other.Audience
			WholeMarket = other.WholeMarket
			PotentialAudience = other.PotentialAudience
		endif

		return self
	End Method


	Method Reset()
		Audience = New TAudience
		WholeMarket = New TAudience
		PotentialAudience = New TAudience
	End Method


	'returns the average audienceresult for the given results
	Function CreateAverage:TAudienceResultBase(audienceResultBases:TAudienceResultBase[])
		local result:TAudienceResultBase = new TAudienceResultBase
		if audienceResultBases.length = 0 then return result
		'if audienceResultBases.length = 1 then return audienceResultBases[0]

		For local audienceResultBase:TAudienceResultBase = EachIn audienceResultBases
			result.Audience.Add(audienceResultBase.Audience)
			result.WholeMarket.Add(audienceResultBase.WholeMarket)
			result.GetPotentialAudience().Add(audienceResultBase.GetPotentialAudience())
		Next

		If audienceResultBases.length > 1
			result.Audience.Divide(audienceResultBases.length)
			result.WholeMarket.Divide(audienceResultBases.length)
			result.GetPotentialAudience().Divide(audienceResultBases.length)
		Endif
		
		return result
	End Function


	Method GetTitle:string()
		If broadcastOutage Then Return GetLocale("BROADCASTING_OUTAGE")
		If broadcastMaterial Then Return broadcastMaterial.GetTitle()
		return ""
	End Method


	Method GetPotentialAudience:TAudience() {_exposeToLua}
		if not PotentialAudience then PotentialAudience = new TAudience
		return PotentialAudience
	End Method


	'instead of storing "audienceQuote" as field (bigger savegames)
	'we can create it on the fly
	'returns audience quote relative to MaxAudience of that time
	'ATTENTION: to fetch the effective total audiencequote use
	'           "GetWeightedAverage()" instead of "GetAverage()" as the
	'           target groups are not equally weighted.
	Method GetAudienceQuote:TAudience() {_exposeToLua}
		if not Audience then return new TAudience
		
		'quote = audience / maxAudience
		return Audience.Copy().Divide( GetPotentialAudience() )
	End Method


	'returns the percentage (0-1.0) of reached audience compared to
	'potentially reachable audience (in front of TV at that moment)
	Method GetAudienceQuotePercentage:Float(gender:int=-1) {_exposeToLua}
		if gender = -1
			Local sum1:Float = Audience.GetTotalSum()
			Local sum2:Float = GetPotentialAudience().GetTotalSum()
			if sum1 = 0 or sum2 = 0 then Return 0
			'more exact until we use some "math library" for floats
			return sum1 / sum2
			'return GetAudienceQuote().GetWeightedAverage()
		else
			Local sum1:Float = Audience.GetGenderSum(gender)
			Local sum2:Float = GetPotentialAudience().GetGenderSum(gender)
			if sum1 = 0 or sum2 = 0 then Return 0
			return sum1 / sum2
		endif
	End Method


	'instead of storing "potentialAudienceQuote" as field we can
	'create it on the fly
	'returns the quote of PotentialAudience. What percentage switched
	'on the TV and checked the programme. Base is WholeMarket
	'ATTENTION: to fetch the effective total audiencequote use
	'           "GetWeightedAverage()" instead of "GetAverage()" as the
	'           target groups are not equally weighted.
	Method GetPotentialAudienceQuote:TAudience() {_exposeToLua}
		'no need to calculate a quote if the audience itself is 0 already
		'-> avoids "nan"-values when dividing with "0.0f" values
		If GetPotentialAudience().GetTotalSum() = 0 then return new TAudience

		'potential quote = potential audience / whole market
		return GetPotentialAudience().Copy().Divide(WholeMarket)
	End Method


	'returns the percentage (0-1.0) of practically reachable audience
	'(switched on the TV) compared to technically reachable audience
	'(within range of the broadcast area)
	Method GetPotentialAudienceQuotePercentage:Float(gender:int=-1) {_exposeToLua}
		if gender = -1
			'more exact until we use some "math library" for floats
			return GetPotentialAudience().GetTotalSum() / WholeMarket.GetTotalSum()
			'return GetAudienceQuote().GetWeightedAverage()
		else
			return GetPotentialAudience().GetGenderSum(gender) / WholeMarket.GetGenderSum(gender)
		endif
	End Method


	'returns the quote of reached audience to WholeMarket.
	'What percentage of all people having a TV watched the programme
	'ATTENTION: to fetch the effective total audience quote use
	'           "GetWeightedAverage()" instead of "GetAverage()" as the
	'           target groups are not equally weighted.
	Method GetWholeMarketAudienceQuote:TAudience() {_exposeToLua}
		'no need to calculate a quote if the audience itself is 0 already
		'-> avoids "nan"-values when dividing with "0.0f" values
		If not Audience or Audience.GetTotalSum() = 0 then return new TAudience

		'total quote = audience / whole market
		return Audience.Copy().Divide(WholeMarket)
	End Method


	'returns the percentage (0-1.0) of reached audience (switched on TV
	'and watching your channel) compared to technically reachable audience
	'(within range of the broadcast area)
	Method GetWholeMarketAudienceQuotePercentage:Float(gender:int=-1) {_exposeToLua}
		if gender = -1
			'more exact until we use some "math library" for floats
			return Audience.GetTotalSum() / WholeMarket.GetTotalSum()
			'return GetWholeMarketAudienceQuote().GetWeightedAverage()
		else
			return Audience.GetGenderSum(gender) / WholeMarket.GetGenderSum(gender)
		endif
	End Method



	Method ToString:String()
		local result:string = ""
		if Audience
			result :+ int(Audience.GetGenderSum(TVTPersonGender.MALE))
			result :+ "/"
			result :+ int(Audience.GetGenderSum(TVTPersonGender.FEMALE))
		else
			result :+ "--"
		endif

		result :+ "  /  "
		if PotentialAudience
			result :+ int(PotentialAudience.GetGenderSum(TVTPersonGender.MALE))
			result :+ "/"
			result :+ int(PotentialAudience.GetGenderSum(TVTPersonGender.FEMALE))
		else
			result :+ "--"
		endif
		result :+ " / "

		if WholeMarket
			result :+ int(WholeMarket.GetGenderSum(TVTPersonGender.MALE))
			result :+ "/"
			result :+ int(WholeMarket.GetGenderSum(TVTPersonGender.FEMALE))
		else
			result :+ "--"
		endif

		result :+ "  "
		local l:int = result.length
		result :+ " Q:"+GetAudienceQuote().ToStringAverage()

		if Audience
			result :+ "~n" + Rset("", l)
			result :+ " A:" + Audience.ToString()
		endif
		if PotentialAudience
			result :+ "~n" + Rset("", l)
			result :+ "PM:" + PotentialAudience.ToString()
		endif
		if WholeMarket
			result :+ "~n" + Rset("", l)
			result :+ "WM:" + WholeMarket.ToString()
		endif
		return result
	End Method
End Type




'Das TAudienceResult erweitert die Basis um weitere Daten
'die aber nicht von allen Elementen benoetigt werden
Type TAudienceResult extends TAudienceResultBase {_exposeToLua="selected"}
	'Die ursprüngliche Attraktivität des Programmes, vor der
	'Kunkurrenzsituation
	Field AudienceAttraction:TAudienceAttraction
	'how to modify basic attractivity of the programme
	'based on the current market competition
	Field competitionAttractionModifier:TAudience

	'Die reale Zuschauerquote, die aber noch nicht verwendet wird.
	'Field MarketShare:Float

	'override with same content - so it calls "this" Reset, not Super.Reset()
	Method New()
		Reset()
	End Method


	Method Reset()
		Super.Reset()
	End Method


	Method ToAudienceResultBase:TAudienceResultBase(audienceResult:TAudienceResult)
		local base:TAudienceResultBase = new TAudienceResultBase
		base.PlayerId = self.PlayerId
		base.Time = self.Time
		base.broadcastMaterial = self.broadcastMaterial
		base.Audience = self.Audience
		base.PotentialAudience = self.PotentialAudience
		base.WholeMarket = self.WholeMarket
		return base
	End Method


	Method AddResult(res:TAudienceResult)
		WholeMarket.Add(res.WholeMarket)
		PotentialAudience.Add(res.PotentialAudience)
		Audience.Add(res.Audience)

		AudienceAttraction = res.AudienceAttraction 'Ist immer gleich, deswegen einfach zuweisen
	End Method
End Type
