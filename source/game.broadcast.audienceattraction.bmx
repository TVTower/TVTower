SuperStrict
Import "game.broadcast.audience.bmx"
Import "game.broadcast.genredefinition.base.bmx"


'Diese Klasse repräsentiert die Programmattraktivität (Inhalt von TAudience)
'Sie beinhaltet aber zusätzlich die Informationen wie sie berechnet wurde (für Statistiken, Debugging und Nachberechnungen) unf für was sieht steht.
Type TAudienceAttraction Extends TAudience
	Field BroadcastType:Int '-1 = Sendeausfall; 1 = Film; 2 = News
	Field Quality:Float				'0 - 100
	Field GenrePopularityMod:Float	'
	Field GenreTargetGroupMod:TAudience
	Field TargetGroupGenderMod:TAudience
	Field PublicImageMod:TAudience
	Field TrailerMod:TAudience
	Field MiscMod:TAudience
	Field QualityOverTimeEffectMod:Float
	Field GenreTimeMod:Float
	Field LuckMod:TAudience

	Field AudienceFlowBonus:TAudience
	Field SequenceEffect:TAudience

	Field BaseAttraction:TAudience
	Field FinalAttraction:TAudience
	Field PublicImageAttraction:TAudience

	Field Genre:Int
	Field GenreDefinition:TGenreDefinitionBase
	Field Malfunction:Int '1 = Sendeausfall


	Method Init:TAudienceAttraction(gender:int, children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float)
		Super.Init(gender, children, teenagers, HouseWives, employees, unemployed, manager, pensioners)
		Return self
	End Method


	Method InitValue:TAudienceAttraction(valueMale:Float, valueFemale:Float)
		Super.InitValue(valueMale, valueFemale)
		return self
	End Method
	

	Method InitGenderValue:TAudienceAttraction(valueMale:float, valueFemale:float)
		GetAudienceMale().InitValue(valueMale)
		GetAudienceFemale().InitValue(valueFemale)
		return self
	End Method


	Method SetPlayerId(playerId:Int)
		Self.Id = playerId
		Self.BaseAttraction.Id = playerId
		Self.FinalAttraction.Id = playerId
		Self.PublicImageAttraction.Id = playerId
	End Method


	Method SetFixAttraction:TAudienceAttraction(attraction:TAudience)
		Self.BaseAttraction = attraction.Copy()
		Self.FinalAttraction = attraction.Copy()
		Self.PublicImageAttraction = attraction.Copy()
		Self.SetValuesFrom(attraction)
		Return Self
	End Method


	Method AddAttraction:TAudienceAttraction(audienceAttr:TAudienceAttraction)
		If Not audienceAttr Then Return Self
		Self.Add(audienceAttr)

		Quality	:+ audienceAttr.Quality
		GenrePopularityMod	:+ audienceAttr.GenrePopularityMod
		If GenreTargetGroupMod Then GenreTargetGroupMod.Add(audienceAttr.GenreTargetGroupMod)
		If PublicImageMod Then PublicImageMod.Add(audienceAttr.PublicImageMod)
		If TrailerMod Then TrailerMod.Add(audienceAttr.TrailerMod)
		If MiscMod Then MiscMod.Add(audienceAttr.MiscMod)
		If AudienceFlowBonus Then AudienceFlowBonus.Add(audienceAttr.AudienceFlowBonus)
		QualityOverTimeEffectMod :+ audienceAttr.QualityOverTimeEffectMod
		GenreTimeMod :+ audienceAttr.GenreTimeMod
		If LuckMod Then MiscMod.Add(audienceAttr.LuckMod)
		If AudienceFlowBonus Then AudienceFlowBonus.Add(audienceAttr.AudienceFlowBonus)

		'If NewsShowBonus Then NewsShowBonus.Add(audienceAttr.NewsShowBonus)
		If SequenceEffect Then SequenceEffect.Add(audienceAttr.SequenceEffect)
		If BaseAttraction Then BaseAttraction.Add(audienceAttr.BaseAttraction)
		If FinalAttraction Then FinalAttraction.Add(audienceAttr.FinalAttraction)
		If PublicImageAttraction Then PublicImageAttraction.Add(audienceAttr.PublicImageAttraction)

		Return Self
	End Method


	Method MultiplyAttrFactor:TAudienceAttraction(factor:float)
		Self.MultiplyFloat(factor)

		Quality	:* factor
		GenrePopularityMod 	:* factor
		If GenreTargetGroupMod Then GenreTargetGroupMod.MultiplyFloat(factor)
		If PublicImageMod Then PublicImageMod.MultiplyFloat(factor)
		If TrailerMod Then TrailerMod.MultiplyFloat(factor)
		If MiscMod Then MiscMod.MultiplyFloat(factor)
		If AudienceFlowBonus Then AudienceFlowBonus.MultiplyFloat(factor)
		QualityOverTimeEffectMod :* factor
		GenreTimeMod :* factor
		If LuckMod Then LuckMod.MultiplyFloat(factor)
		'If NewsShowBonus Then NewsShowBonus.MultiplyFloat(factor)
		If SequenceEffect Then SequenceEffect.MultiplyFloat(factor)
		If BaseAttraction Then BaseAttraction.MultiplyFloat(factor)
		If FinalAttraction Then FinalAttraction.MultiplyFloat(factor)
		If PublicImageAttraction Then PublicImageAttraction.MultiplyFloat(factor)
		If AudienceFlowBonus Then AudienceFlowBonus.MultiplyFloat(factor)

		Return Self
	End Method


	Method Recalculate()
		Local result:TAudience = new TAudience
		'start with an attraction of "100%"
		result.AddFloat(1.0)
'print "0. "

		result.MultiplyFloat(Quality)
'print "1. "
'print "* " +Quality
'print result.ToString()

		result.AddFloat(GenrePopularityMod)
'print "2. "
'print "+ " +GenrePopularityMod
'print result.ToString()

		result.Add(GenreTargetGroupMod)
'print "3. "
'print "+ " +GenreTargetGroupMod.ToString()
'print result.ToString()

		result.Add(TrailerMod)
'print "4. "
'print "+ " +TrailerMod.ToString()
'print result.ToString()

		result.Add(MiscMod)
'print "5. "
'print "+ " +MiscMod.ToString()
'print result.ToString()

		Self.PublicImageAttraction = result.Copy()
		Self.PublicImageAttraction.AddFloat(1)
		Self.PublicImageAttraction.MultiplyFloat(Quality)


		result.Add(PublicImageMod)
'print "6. "
'print result.ToString()

'		result.AddFloat(QualityOverTimeEffectMod)
'print "7. "
'print result.ToString()

		result.AddFloat(GenreTimeMod)
'print "8. "
'print result.ToString()

		result.Add(LuckMod)
'print "9. "
'print result.ToString()

		result.Add(AudienceFlowBonus)
'print "10. "
'print result.ToString()

		Self.BaseAttraction = result.Copy()

		'result.Add(AudienceFlowBonus)
		result.Add(SequenceEffect)
'print "11. "
'print result.ToString()

		'avoid negative attraction values or values > 100%
		'-> else you could have a negative audience
		result.CutBordersFloat(0.0, 1.0)

		Self.FinalAttraction = result
		Self.SetValuesFrom(result)
	End Method


	Method CopyBaseAttractionFrom(otherAudienceAttraction:TAudienceAttraction)
		Quality = otherAudienceAttraction.Quality
		GenrePopularityMod = otherAudienceAttraction.GenrePopularityMod

		'ATTENTION: we _copy_ the objects instead of referencing it
		'Why?:
		'broadcastmaterial "TNewsShow" is modifying the attraction by
		'multiplying them for each slot (1-3) with a factor. When using
		'references, we also lower the effects of the "surrounding"
		'programme (eg movieBlock1 news movieBlock2)
		if otherAudienceAttraction.GenreTargetGroupMod
			GenreTargetGroupMod = otherAudienceAttraction.GenreTargetGroupMod.Copy()
		else
			GenreTargetGroupMod = null
		endif
		if otherAudienceAttraction.TrailerMod
			TrailerMod = otherAudienceAttraction.TrailerMod.Copy()
		else
			TrailerMod = null
		endif
		if otherAudienceAttraction.MiscMod
			MiscMod = otherAudienceAttraction.MiscMod.Copy()
		else
			MiscMod = null
		endif
		if otherAudienceAttraction.PublicImageMod
			PublicImageMod = otherAudienceAttraction.PublicImageMod.Copy()
		else
			PublicImageMod = null
		endif
		if otherAudienceAttraction.AudienceFlowBonus
			AudienceFlowBonus = otherAudienceAttraction.AudienceFlowBonus.Copy()
		else
			AudienceFlowBonus = null
		endif
	End Method
End Type
