SuperStrict
Import "game.broadcast.audience.bmx"
Import "game.broadcast.genredefinition.base.bmx"


'Diese Klasse repräsentiert die Programmattraktivität (Inhalt von TAudience)
'Sie beinhaltet aber zusätzlich die Informationen wie sie berechnet wurde
'(für Statistiken, Debugging und Nachberechnungen) und für was sieht steht.
Type TAudienceAttraction Extends TAudience
	Field BroadcastType:Int '-1 = Sendeausfall; 1 = Film; 2 = News
	Field Quality:Float				'0 - 100
	Field GenreTargetGroupMod:TAudience
	Field GenrePopularityMod:Float = 1.0
	Field FlagsTargetGroupMod:TAudience
	Field FlagsPopularityMod:Float = 1.0
	Field targetGroupAttractivityMod:TAudience
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

	Field GenreDefinition:TGenreDefinitionBase
	Field Malfunction:Int '1 = Sendeausfall

	Const MODINFLUENCE_GENREPOPULARITY:Float = 0.25
	Const MODINFLUENCE_FLAGPOPULARITY:Float = 0.25
	Const MODINFLUENCE_TRAILER:Float = 0.25
	Const MODINFLUENCE_GENRETARGETGROUP:Float = 0.95
	Const MODINFLUENCE_FLAGTARGETGROUP:Float = 0.95


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
		If GenreTargetGroupMod Then GenreTargetGroupMod.Add(audienceAttr.GenreTargetGroupMod)
		GenrePopularityMod :+ audienceAttr.GenrePopularityMod
		If FlagsTargetGroupMod Then FlagsTargetGroupMod.Add(audienceAttr.FlagsTargetGroupMod)
		FlagsPopularityMod :+ audienceAttr.FlagsPopularityMod
		If targetGroupAttractivityMod Then targetGroupAttractivityMod.Add(audienceAttr.targetGroupAttractivityMod)
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
		If GenreTargetGroupMod Then GenreTargetGroupMod.MultiplyFloat(factor)
		GenrePopularityMod :* factor
		If FlagsTargetGroupMod Then FlagsTargetGroupMod.MultiplyFloat(factor)
		FlagsPopularityMod :* factor
		If targetGroupAttractivityMod Then targetGroupAttractivityMod.MultiplyFloat(factor)
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


	'time depending value, cannot be used for "base attractivity"
	'(which is used by Follow-Up-Blocks)
	Method GetGenreAttractivity:TAudience()
		local result:TAudience = new TAudience.InitValue(1,1)
		'adjust by genre-time-attractivity: 0.0 - 2.0
		result.MultiplyFloat(GenreTimeMod)
		'limit to 0-x
		result.CutMinimumFloat(0)
		return result
	End Method


	Method GetTargetGroupAttractivity:TAudience()
		If Not GenreTargetGroupMod Or Not FlagsTargetGroupMod Return Null
		
		'target group interest: 0 - 2.0, influence: 95%
		'tg with interest around 0 do hardly watch the broadcast!
		'tg with interest > 1.0 have a general interest in the programme,
		'regardless of the quality:
		'  ex. erotic for male teenagers
		'  ex. cartoons for children
		Local _effectiveGenreTargetGroupMod:TAudience = GenreTargetGroupMod.Copy()
		_effectiveGenreTargetGroupMod.MultiplyFloat(GenrePopularityMod)
		_effectiveGenreTargetGroupMod.SubtractFloat(1)
		_effectiveGenreTargetGroupMod.MultiplyFloat(MODINFLUENCE_GENRETARGETGROUP)
		_effectiveGenreTargetGroupMod.AddFloat(1)
		Local _effectiveFlagsTargetGroupMod:TAudience = FlagsTargetGroupMod.Copy()
		_effectiveFlagsTargetGroupMod.MultiplyFloat(FlagsPopularityMod)
		_effectiveFlagsTargetGroupMod.SubtractFloat(1)
		_effectiveFlagsTargetGroupMod.MultiplyFloat(MODINFLUENCE_FLAGTARGETGROUP)
		_effectiveFlagsTargetGroupMod.AddFloat(1)
		 
		Local result:TAudience = New TAudience.InitValue(1, 1)
		result.Multiply( _effectiveGenreTargetGroupMod )
		result.Multiply( _effectiveFlagsTargetGroupMod )


		result.Multiply( targetGroupAttractivityMod )

		result.CutMinimumFloat(0)

		Return result
	End Method
	

	Method Recalculate()
		Local tmpAudience:TAudience



		'=== FINAL CALCULATION ===


		Local result:TAudience = New TAudience
		'start with an attraction of "100%"
		result.AddFloat(1.0)

		'quality: 0.0 - 1.0, influence: 100%
		result.MultiplyFloat( Quality )


		Local targetGroupAttractivity:TAudience = GetTargetGroupAttractivity()
		If targetGroupAttractivity Then result.Multiply( targetGroupAttractivity )


		'trailer bonus: 0 - 1.0, influence: 25%
		'add +1 so it gets a multiplier
		'"multiply" because it "increases" existing interest
		'(people more likely watch this programme)
		If TrailerMod Then result.Multiply( TrailerMod.Copy().MultiplyFloat(MODINFLUENCE_TRAILER).AddFloat(1) )


		If MiscMod Then result.Add(MiscMod)


		'store the current attraction for the publicImage-calculation
		Self.PublicImageAttraction = result.Copy()
		Self.PublicImageAttraction.AddFloat(1).MultiplyFloat(Quality)


		If PublicImageMod Then result.Multiply( PublicImageMod.Copy().AddFloat(1.0) )


		'if QualityOverTimeEffectMod Then result.AddFloat(QualityOverTimeEffectMod)


		If LuckMod Then result.Add(LuckMod)


		If AudienceFlowBonus Then result.Add(AudienceFlowBonus)


		'store for later use (audience flow etc.)
		Self.BaseAttraction = result.Copy()


		local genreAttractivity:TAudience = GetGenreAttractivity()
		if genreAttractivity then result.Multiply( GetGenreAttractivity() )


		if SequenceEffect Then result.Add(SequenceEffect)


		'avoid negative attraction values or values > 100%
		'-> else you could have a negative audience
		result.CutBordersFloat(0.0, 1.0)

		Self.FinalAttraction = result
		Self.SetValuesFrom(result)
	End Method


	Method DebugPrint()
		print " 0. START:     1 "
		print " 1. QUALITY:   * " + Quality

		local targetGroupAttractivity:TAudience = GetTargetGroupAttractivity() 
		If targetGroupAttractivity
			print " 2. TGROUPATT: * " + targetGroupAttractivity.ToStringAverage()
		Else
			print " 2. TGROUPATT: -/-"
		EndIf

		If TrailerMod
			print " 3. TRAILER:   * " + TrailerMod.Copy().MultiplyFloat(MODINFLUENCE_TRAILER).AddFloat(1).ToStringAverage()
		Else
			print " 3. TRAILER:   -/- "
		endif

		if MiscMod
			print " 4. MISC:      + " + MiscMod.ToStringAverage()
		Else
			print " 4. MISC:      -/-"
		endif

		If PublicImageMod
			print " 5. IMAGE:     * " + PublicImageMod.Copy().AddFloat(1.0).ToStringAverage()
		Else
			print " 5. IMAGE:     -/-"
		endif

		If QualityOverTimeEffectMod
			print "(6. QOVERTIME: + " + QualityOverTimeEffectMod+" )"
		Else
			print " (6. QOVERTIME: -/-)"
		EndIf

		If LuckMod
			print " 7. LUCK:      + " + LuckMod.ToStringAverage()
		Else
			print " 7. LUCK:      -/-"
		EndIf

		If AudienceFlowBonus
			print " 8. AUD.FLOW:  + " + AudienceFlowBonus.ToStringAverage()
		Else
			print " 8. AUD.FLOW:  + -/-"
		EndIf

		Local genreAttractivity:TAudience = GetGenreAttractivity()
		If genreAttractivity
			print " 9. GENREATT:  * " + genreAttractivity.ToStringAverage()
		Else
			print " 9. GENREATT:  -/-"
		EndIf

		If SequenceEffect
			print "10. SEQUENCE:  + " + SequenceEffect.ToStringAverage()
		Else
			print "10. SEQUENCE:  + -/-"
		EndIf



		print "11. RES        = " + FinalAttraction.ToStringAverage()
	End Method


	Method CopyBaseAttractionFrom(otherAudienceAttraction:TAudienceAttraction)
		'ATTENTION: we _copy_ the objects instead of referencing it
		'Why?:
		'broadcastmaterial "TNewsShow" is modifying the attraction by
		'multiplying them for each slot (1-3) with a factor. When using
		'references, we also lower the effects of the "surrounding"
		'programme (eg movieBlock1 news movieBlock2)

		'float values do not need a copy (*1 is done to avoid ambiguity if changing
		'one of the objects)
		Quality = otherAudienceAttraction.Quality * 1
		GenrePopularityMod = otherAudienceAttraction.GenrePopularityMod * 1
		FlagsPopularityMod = otherAudienceAttraction.FlagsPopularityMod * 1


		If otherAudienceAttraction.targetGroupAttractivityMod
			targetGroupAttractivityMod = otherAudienceAttraction.targetGroupAttractivityMod.Copy()
		Else
			targetGroupAttractivityMod = Null
		EndIf

		If otherAudienceAttraction.GenreTargetGroupMod
			GenreTargetGroupMod = otherAudienceAttraction.GenreTargetGroupMod.Copy()
		Else
			GenreTargetGroupMod = Null
		EndIf
		If otherAudienceAttraction.FlagsTargetGroupMod
			FlagsTargetGroupMod = otherAudienceAttraction.FlagsTargetGroupMod.Copy()
		Else
			FlagsTargetGroupMod = Null
		EndIf
		If otherAudienceAttraction.TrailerMod
			TrailerMod = otherAudienceAttraction.TrailerMod.Copy()
		else
			TrailerMod = Null
		EndIf
		If otherAudienceAttraction.MiscMod
			MiscMod = otherAudienceAttraction.MiscMod.Copy()
		Else
			MiscMod = Null
		EndIf
		If otherAudienceAttraction.PublicImageMod
			PublicImageMod = otherAudienceAttraction.PublicImageMod.Copy()
		Else
			PublicImageMod = Null
		EndIf
		If otherAudienceAttraction.AudienceFlowBonus
			AudienceFlowBonus = otherAudienceAttraction.AudienceFlowBonus.Copy()
		Else
			AudienceFlowBonus = Null
		EndIf
	End Method
End Type
