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

	Function CreateAndInitAttraction:TAudienceAttraction(group0:Float, group1:Float, group2:Float, group3:Float, group4:Float, group5:Float, group6:Float, subgroup0:Float, subgroup1:Float)
		Local result:TAudienceAttraction = New TAudienceAttraction
		result.SetValues(group0, group1, group2, group3, group4, group5, group6, subgroup0, subgroup1)
		Return result
	End Function

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

		result.AddFloat(GenrePopularityMod)
		result.Add(GenreTargetGroupMod)
		result.Add(TrailerMod)
		result.Add(MiscMod)
		result.AddFloat(GenreTimeMod)
'		result.AddFloat(QualityOverTimeEffectMod)

		Self.PublicImageAttraction = result.Copy()
		Self.PublicImageAttraction.AddFloat(1)
		Self.PublicImageAttraction.MultiplyFloat(Quality)

		result.Add(PublicImageMod)
		result.Add(LuckMod)
		result.MultiplyFloat(Quality)
		result.Add(AudienceFlowBonus)
		Self.BaseAttraction = result.Copy()

		'result.Add(AudienceFlowBonus)
		result.Add(SequenceEffect)

		'avoid negative attraction values or values > 100%
		'-> else you could have a negative audience
		result.CutBordersFloat(0.0, 1.0)

		Self.FinalAttraction = result
		Self.SetValuesFrom(result)
	End Method

	Method CopyBaseAttractionFrom(otherAudienceAttraction:TAudienceAttraction)
		Quality = otherAudienceAttraction.Quality
		GenrePopularityMod = otherAudienceAttraction.GenrePopularityMod
		GenreTargetGroupMod = otherAudienceAttraction.GenreTargetGroupMod
		TrailerMod = otherAudienceAttraction.TrailerMod
		MiscMod = otherAudienceAttraction.MiscMod
		PublicImageMod = otherAudienceAttraction.PublicImageMod
		AudienceFlowBonus = otherAudienceAttraction.AudienceFlowBonus
	End Method
End Type
