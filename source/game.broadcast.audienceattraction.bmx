SuperStrict
Import "game.broadcast.audience.bmx"
Import "game.broadcast.genredefinition.base.bmx"


'class represents attractivity of a broadcast (it is content of TAudience)
'It also contains additional information on how it is calculated (for
'statistics, debugging and recalculation)
Type TAudienceAttraction Extends TAudience {_exposeToLua="selected"}
	'types: -1 (outage), 1 (movie, 2 (news)
	Field BroadcastType:Int
	'=== SEMISTATIC ===
	'(things changing with additional broadcasts like "perceived Quality")
	'quality: 0 - 100
	Field Quality:Float
	Field TrailerMod:TAudience

	'=== STATIC mods ==
	'(based on broadcast material itself)
	Field GenreTargetGroupMod:TAudience
	Field FlagsTargetGroupMod:TAudience
	Field targetGroupAttractivityMod:TAudience
	Field GenreTimeMod:Float

	'=== DYNAMIC mods ==
	'(based on broadcast time / popularity / modifiers )
	Field GenreMod:Float = 1.0
	Field GenrePopularityMod:Float = 1.0
	Field CastMod:Float = 1.0
	Field FlagsMod:Float = 1.0
	Field FlagsPopularityMod:Float = 1.0
	Field PublicImageMod:TAudience
	Field MiscMod:TAudience
	Field QualityOverTimeEffectMod:Float
	Field LuckMod:TAudience
	Field TargetGroupAttractivity:TAudience

	Field AudienceFlowBonus:TAudience
	Field SequenceEffect:TAudience

	Field BaseAttraction:TAudience
	Field FinalAttraction:TAudience
	Field PublicImageAttraction:TAudience

	Field GenreDefinition:TGenreDefinitionBase
	'boolean, outage = 1
	Field Malfunction:Int

	Global luckModEnabled:int = True

	Const MODINFLUENCE_GENREPOPULARITY:Float = 0.25
	Const MODINFLUENCE_FLAGPOPULARITY:Float = 0.25
	Const MODINFLUENCE_TRAILER:Float = 0.50
	Const MODINFLUENCE_GENRETARGETGROUP:Float = 0.95
	Const MODINFLUENCE_FLAGTARGETGROUP:Float = 0.95
	Const MODINFLUENCE_MISC:Float = 1.0
	Const MODINFLUENCE_CAST:Float = 0.20


	Method Set:TAudienceAttraction(gender:int, children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float) override
		Super.Set(gender, children, teenagers, HouseWives, employees, unemployed, manager, pensioners)
		Return self
	End Method


	Method Set:TAudienceAttraction(valueMale:Float, valueFemale:Float)
		Super.Set(valueMale, valueFemale)
		return self
	End Method
	

	Method InitGenderValue:TAudienceAttraction(valueMale:float, valueFemale:float)
		audienceFemale = new SAudienceBase(valueFemale)
		audienceMale = new SAudienceBase(valueMale)
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
		Self.Set(attraction)
		Return Self
	End Method


	Method AddAttraction:TAudienceAttraction(audienceAttr:TAudienceAttraction)
		If Not audienceAttr Then Return Self
		Self.Add(audienceAttr)
		Quality	:+ audienceAttr.Quality
		CastMod :+ audienceAttr.CastMod
		If GenreTargetGroupMod Then GenreTargetGroupMod.Add(audienceAttr.GenreTargetGroupMod)
		GenreMod :+ audienceAttr.GenreMod
		GenrePopularityMod :+ audienceAttr.GenrePopularityMod
		GenreTimeMod :+ audienceAttr.GenreTimeMod
		If FlagsTargetGroupMod Then FlagsTargetGroupMod.Add(audienceAttr.FlagsTargetGroupMod)
		FlagsMod :+ audienceAttr.FlagsMod
		FlagsPopularityMod :+ audienceAttr.FlagsPopularityMod
		If targetGroupAttractivityMod Then targetGroupAttractivityMod.Add(audienceAttr.targetGroupAttractivityMod)
		If PublicImageMod Then PublicImageMod.Add(audienceAttr.PublicImageMod)
		If TrailerMod Then TrailerMod.Add(audienceAttr.TrailerMod)
		If MiscMod Then MiscMod.Add(audienceAttr.MiscMod)
		If AudienceFlowBonus Then AudienceFlowBonus.Add(audienceAttr.AudienceFlowBonus)
		QualityOverTimeEffectMod :+ audienceAttr.QualityOverTimeEffectMod
		If LuckMod Then MiscMod.Add(audienceAttr.LuckMod)
		If AudienceFlowBonus Then AudienceFlowBonus.Add(audienceAttr.AudienceFlowBonus)

		If targetGroupAttractivity Then targetGroupAttractivity.Add(audienceAttr.targetGroupAttractivity)

		'If NewsShowBonus Then NewsShowBonus.Add(audienceAttr.NewsShowBonus)
		If SequenceEffect Then SequenceEffect.Add(audienceAttr.SequenceEffect)
		If BaseAttraction Then BaseAttraction.Add(audienceAttr.BaseAttraction)
		If FinalAttraction Then FinalAttraction.Add(audienceAttr.FinalAttraction)
		If PublicImageAttraction Then PublicImageAttraction.Add(audienceAttr.PublicImageAttraction)

		Return Self
	End Method


	Method MultiplyAttrFactor:TAudienceAttraction(factor:float)
		Self.Multiply(factor)

		Quality	:* factor
		CastMod :* factor
		If GenreTargetGroupMod Then GenreTargetGroupMod.Multiply(factor)
		GenreMod :* factor
		GenrePopularityMod :* factor
		GenreTimeMod :* factor
		If FlagsTargetGroupMod Then FlagsTargetGroupMod.Multiply(factor)
		FlagsPopularityMod :* factor
		If targetGroupAttractivityMod Then targetGroupAttractivityMod.Multiply(factor)
		If PublicImageMod Then PublicImageMod.Multiply(factor)
		If TrailerMod Then TrailerMod.Multiply(factor)
		If MiscMod Then MiscMod.Multiply(factor)
		If AudienceFlowBonus Then AudienceFlowBonus.Multiply(factor)
		QualityOverTimeEffectMod :* factor
		If LuckMod Then LuckMod.Multiply(factor)
		'If NewsShowBonus Then NewsShowBonus.Multiply(factor)
		if targetGroupAttractivity then targetGroupAttractivity.Multiply(factor)
		If SequenceEffect Then SequenceEffect.Multiply(factor)
		If BaseAttraction Then BaseAttraction.Multiply(factor)
		If FinalAttraction Then FinalAttraction.Multiply(factor)
		If PublicImageAttraction Then PublicImageAttraction.Multiply(factor)
		If AudienceFlowBonus Then AudienceFlowBonus.Multiply(factor)

		Return Self
	End Method


	'time depending value, cannot be used for "base attractivity"
	'(which is used by Follow-Up-Blocks)
	Method GetGenreAttractivity:TAudience()
		local result:TAudience = new TAudience.Set(1,1)
		'adjust by genre-time-attractivity: 0.0 - 2.0
		result.Multiply(GenreTimeMod)
		'adjust by

		'limit to 0-x
		result.CutMinimum(0)
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
		_effectiveGenreTargetGroupMod.Multiply(GenrePopularityMod * GenreMod)
		_effectiveGenreTargetGroupMod.Subtract(1)
		_effectiveGenreTargetGroupMod.Multiply(MODINFLUENCE_GENRETARGETGROUP)
		_effectiveGenreTargetGroupMod.Add(1)
		Local _effectiveFlagsTargetGroupMod:TAudience = FlagsTargetGroupMod.Copy()
		_effectiveFlagsTargetGroupMod.Multiply(FlagsPopularityMod * FlagsMod)
		_effectiveFlagsTargetGroupMod.Subtract(1)
		_effectiveFlagsTargetGroupMod.Multiply(MODINFLUENCE_FLAGTARGETGROUP)
		_effectiveFlagsTargetGroupMod.Add(1)
		 
		Local result:TAudience = New TAudience.Set(1, 1)
		result.Multiply( _effectiveGenreTargetGroupMod )
		result.Multiply( _effectiveFlagsTargetGroupMod )

		result.Multiply( targetGroupAttractivityMod )

		'0 = no attractivity, 1 = no adjustment, 2 = totally like it
		result.CutBorders(0, 2.0)

		Return result
	End Method
	

	Method Recalculate()
		'=== FINAL CALCULATION ===
		Local result:TAudience = New TAudience
		'start with an attraction of "100%"
		result.Add(1.0)

		'quality: 0.0 - 1.0, influence: 100%
		result.Multiply( Quality )


		targetGroupAttractivity = GetTargetGroupAttractivity()
		If targetGroupAttractivity Then result.Multiply( targetGroupAttractivity )
'print "GetTargetGroupAttractivity: " + targetGroupAttractivity.ToString()
'end
		'trailer bonus: 0 - 1.0, influence: 50%
		'add +1 so it becomes a multiplier
		'"multiply" because it "increases" existing interest
		'(people more likely watch this programme)
		If TrailerMod Then result.Multiply( TrailerMod.Copy().Multiply(MODINFLUENCE_TRAILER).Add(1.0) )


		If MiscMod Then result.Multiply( MiscMod.Copy().Multiply(MODINFLUENCE_MISC) )


		result.Multiply(1.0 + (CastMod-1.0) * MODINFLUENCE_CAST)

	
		'store the current attraction for the publicImage-calculation
		Self.PublicImageAttraction = result.Copy()
		Self.PublicImageAttraction.Add(1).Multiply(Quality)


		If PublicImageMod Then result.Multiply( PublicImageMod.Copy().Add(1.0) )


		'if QualityOverTimeEffectMod Then result.AddFloat(QualityOverTimeEffectMod)


		If luckModEnabled and LuckMod Then result.Add(LuckMod)


		If AudienceFlowBonus Then result.Add(AudienceFlowBonus)


		'store for later use (audience flow etc.)
		Self.BaseAttraction = result.Copy()


		local genreAttractivity:TAudience = GetGenreAttractivity()
		if genreAttractivity then result.Multiply( genreAttractivity )


		if SequenceEffect Then result.Add(SequenceEffect)


		'avoid negative attraction values or values > 100%
		'-> else you could have a negative audience
		result.CutBorders(0.0, 1.0)
		Self.FinalAttraction = result
		Self.Set(result)
	End Method


	Method DebugPrint()
		print " 0. START:     1 "
		print " 1. QUALITY:   * " + Quality

		targetGroupAttractivity = GetTargetGroupAttractivity() 
		If targetGroupAttractivity
			print " 2. TGROUPATT: * " + targetGroupAttractivity.ToStringAverage()
		Else
			print " 2. TGROUPATT: -/-"
		EndIf

		If TrailerMod
			print " 3. TRAILER:   * " + TrailerMod.Copy().Multiply(MODINFLUENCE_TRAILER).Add(1).ToStringAverage()
		Else
			print " 3. TRAILER:   -/- "
		endif

		if MiscMod
			print " 4. MISC:      + " + MiscMod.ToStringAverage()
		Else
			print " 4. MISC:      -/-"
		endif

		print " 5. CASTMOD:      + " + CastMod

		If PublicImageMod
			print " 6. IMAGE:     * " + PublicImageMod.Copy().Add(1.0).ToStringAverage()
		Else
			print " 6. IMAGE:     -/-"
		endif

		If QualityOverTimeEffectMod
			print "(7. QOVERTIME: + " + QualityOverTimeEffectMod+" )"
		Else
			print " (7. QOVERTIME: -/-)"
		EndIf

		If luckModEnabled and LuckMod
			print " 8. LUCK:      + " + LuckMod.ToStringAverage()
		Else
			if not luckModEnabled
				print " 8. LUCK:      disabled"
			else
				print " 8. LUCK:      -/-"
			endif
		EndIf

		If AudienceFlowBonus
			print " 9. AUD.FLOW:  + " + AudienceFlowBonus.ToStringAverage()
		Else
			print " 9. AUD.FLOW:  + -/-"
		EndIf

		Local genreAttractivity:TAudience = GetGenreAttractivity()
		If genreAttractivity
			print "10. GENREATT:  * " + genreAttractivity.ToStringAverage()
		Else
			print "10. GENREATT:  -/-"
		EndIf

		If SequenceEffect
			print "11. SEQUENCE:  + " + SequenceEffect.ToStringAverage()
		Else
			print "11. SEQUENCE:  + -/-"
		EndIf


		if FinalAttraction
			print "12. RES        = " + FinalAttraction.ToStringAverage()
		else
			print "12. RES        = -/-"
		endif
	End Method


	Method CopyStaticBaseAttraction:TAudienceAttraction()
		local c:TAudienceAttraction = new TAudienceAttraction
		c.CopyStaticBaseAttractionFrom(self)
		return c
	End Method


	Method CopyStaticBaseAttractionFrom(otherAudienceAttraction:TAudienceAttraction)
		'ATTENTION: we _copy_ the objects instead of referencing it
		'Why?:
		'broadcastmaterial "TNewsShow" is modifying the attraction by
		'multiplying them for each slot (1-3) with a factor. When using
		'references, we also lower the effects of the "surrounding"
		'programme (eg movieBlock1 news movieBlock2)
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

		If otherAudienceAttraction.FinalAttraction
			FinalAttraction = otherAudienceAttraction.FinalAttraction.Copy()
		Else
			FinalAttraction = Null
		EndIf
	End Method


	Method CopyDynamicBaseAttractionFrom(otherAudienceAttraction:TAudienceAttraction)
		'ATTENTION: we _copy_ the objects instead of referencing it
		'Why?:
		'broadcastmaterial "TNewsShow" is modifying the attraction by
		'multiplying them for each slot (1-3) with a factor. When using
		'references, we also lower the effects of the "surrounding"
		'programme (eg movieBlock1 news movieBlock2)

		'float values do not need a copy (*1 is done to avoid ambiguity if changing
		'one of the objects - eg. float to TAudience)
		Quality = otherAudienceAttraction.Quality * 1
		CastMod = otherAudienceAttraction.CastMod * 1
		GenrePopularityMod = otherAudienceAttraction.GenrePopularityMod * 1
		FlagsPopularityMod = otherAudienceAttraction.FlagsPopularityMod * 1

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
