SuperStrict
Import "game.gameobject.bmx"
Import "game.broadcast.genredefinition.base.bmx"
Import "game.broadcast.audienceattraction.bmx"
Import "game.broadcast.sequencecalculation.bmx"
Import "game.publicimage.bmx"


'Base type for programmes, advertisements...
Type TBroadcastMaterial	extends TNamedGameObject {_exposeToLua="selected"}
	Field flags:int = 0
	'by default the state is "normal"
	Field state:int = 0
	'original material type (may differ to usage!)
	Field materialType:int = 0
	'the type this material is used for (programme as adspot -> trailer)
	Field usedAsType:int= 0
	'the type this material can be used for (so we can forbid certain ads as tvshow etc)
	Field useableAsType:int = 0

	'time at which the material is planned to get send
	Field programmedHour:int = -1
	Field programmedDay:int	= -1

	'0 = läuft nicht; 1 = 1 Block; 2 = 2 Block; usw.
	Field currentBlockBroadcasting:int {_exposeToLua}

	'states a program can be in
	Const STATE_NORMAL:int		= 0
	Const STATE_OK:int			= 1
	Const STATE_FAILED:int		= 2
	Const STATE_RUNNING:int		= 3


	Method SourceHasBroadcastFlag:int(flag:Int) abstract {_exposeToLua}


	Method IsControllable:int()
		return True
	End Method


	Method hasFlag:Int(flag:Int) {_exposeToLua}
		Return flags & flag
	End Method


	Method setFlag(flag:Int, enable:Int=True)
		If enable
			flags :| flag
		Else
			flags :& ~flag
		EndIf
	End Method


	'needed for all extending objects
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False ) Abstract
	
	'needed for all extending objects
	Method GetQuality:Float() Abstract {_exposeToLua}	


	'what to earn for each viewers in euros?
	'ex.: returning 0.15 means:
	'     for 1.000     viewers I earn 150,00 Euro
	'     for 2.000     viewers I earn 300,00 Euro
	'     for 1.000.000 viewers I earn 150.000,00 Euro and so on
	'so better keep the values low
	Method GetBaseRevenue:Float() {_exposeToLua}
		return 0.0
	End Method


	'get the title
	Method GetDescription:string() {_exposeToLua}
		Return "NO DESCRIPTION"
	End Method


	'get the title
	Method GetTitle:string() {_exposeToLua}
		Return "NO TITLE"
	End Method


	Method GetProgrammeFlags:int() {_exposeToLua}
		Return 0
	End Method
	

	Method GetBlocks:int(broadcastType:int=0) {_exposeToLua}
		Return 1
	End Method


	Method GetTopicalityCutModifier:float( audienceQuote:float = 0.5 ) {_exposeToLua}
		'by default, all broadcasted news would cut their topicality by
		'100% when broadcasted on 100% audience watching
		'but instead of a linear growth, we use the logistical influence
		'to grow fast at the beginning (near 0%), and
		'to grow slower at the end (near 100%)

		rem
		"keepRate" for given quote
		Quote  Strength 3  Strength 2  Strength 1 
		0      1.0000      1.0000      1.0000
		0.01                           0.9903
		0.02                           0.9807
		0.04                           0.9619
		0.06                           0.9434
		0.08                           0.9253
		0.1    0.7435      0.8214      0.9075
		0.2    0.5540      0.6755      0.8239
		0.3    0.4138      0.5561      0.7481
		0.4    0.3100      0.4582      0.6791
		0.5    0.2329      0.3776      0.6163
		0.6    0.1753      0.3112      0.5588
		0.7    0.1319      0.2561      0.5061
		0.8    0.0990      0.2102      0.4576
		0.9    0.0737      0.1718      0.4131
		endrem

		'we do want to know what to keep, not what to cut (-> 1.0-x)
		'strength is 1
		return 1.0 - THelper.LogisticalInfluence_Euler(audienceQuote, 1)
	End Method
	

	Method isType:int(typeID:int) {_exposeToLua}
		return self.materialType = typeID
	End Method


	Method isUsedAsType:int(typeID:int) {_exposeToLua}
		return self.usedAsType = typeID
	End Method


	Method setMaterialType:int(typeID:int=0)
		self.materialType = typeID
		self.useableAsType :| typeID
	End Method


	Method setUsedAsType:int(typeID:int=0)
		if typeID > 0
			self.usedAsType = typeID
			self.useableAsType :| typeID
		else
			self.usedAsType = materialType
		endif
	End Method


	Method setState:int(state:int)
		self.state = state
	End Method


	Method isState:int(state:int) {_exposeToLua}
		if self.state = state then return TRUE
		return FALSE
	End Method


	'by default this is the normal ID, but could be the contracts id or so...
	Method GetReferenceID:int() {_exposeToLua}
		return self.id
	End Method


	Method BeginBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		self.SetState(self.STATE_RUNNING)
	End Method


	Method FinishBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		'print "finished broadcasting of: "+GetTitle()
	End Method


	Method BreakBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		'print "finished broadcasting a block of: "+GetTitle()
	End Method


	Method ContinueBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		'print "continue broadcasting the next block of: "+GetTitle()
	End Method


	'returns whether a programme is programmed for that given day
	Method IsProgrammedForDay:int(day:int)
		if programmedDay = -1 then return FALSE
		'starting at given day
		if programmedDay = day then return TRUE
		'started day before and running that day too?
		if programmedDay = day-1 and getBlocks() + programmedHour > 24 then return TRUE
		return FALSE
	End Method


	'returns whether the programme is programmed at all
	Method IsProgrammed:int(day:int=-1)
		if programmedDay = -1 then return FALSE
		if programmedHour = -1 then return FALSE
		return TRUE
	End Method


	'overrideable default-drawer
	Method ShowSheet:int(x:int,y:int,align:int=0)
		'
	End Method

	Method GetGenreDefinition:TGenreDefinitionBase()
		Return Null
	End Method

	Method GetFlagDefinition:TGenreDefinitionBase()
		Return Null
	End Method
End Type


Type TBroadcastMaterialDefaultImpl extends TBroadcastMaterial {_exposeToLua="selected"}
	'default implementation	
	'limited to 0 - 2.0, 1.0 means "no change"
	Method GetGenrePopularityMod:Float(definition:TGenreDefinitionBase)
		'Popularity ranges from -50 to 100 (no absolute "unpopular for
		'everyone" possible)
		'add 1 to get a value between 0 - 2
		Return 1.0 + MathHelper.Clamp(definition.GetPopularity().Popularity / 100.0, -1.0, 1.0 )
	End Method

	
	'default implementation
	'limited to 0 - 2.0, 1.0 means "no change"
	Method GetGenreTargetGroupMod:TAudience(definition:TGenreDefinitionBase)

		'multiply with 0.5 to scale "-2 to +2" down to "-1 to +1"
		'add 1 to get a value between 0 - 2
		Return definition.AudienceAttraction.Copy().MultiplyFloat(0.5).AddFloat(1.0).CutBordersFloat(0, 2.0)
	End Method
	

	'default implementation	
	'return a value between -1.0 - 1.0
	Method GetFlagPopularityMod:Float(definition:TGenreDefinitionBase)
		'Popularity ranges from -50 to 100 (no absolute "unpopular for
		'everyone" possible)
		'add 1 to get a value between 0 - 2
		Return 1.0 + MathHelper.Clamp(definition.GetPopularity().Popularity / 100.0, -1.0, 1.0 )
	End Method

	
	'default implementation
	'limited to 0 - 2.0, 1.0 means "no change"
	Method GetFlagTargetGroupMod:TAudience(definition:TGenreDefinitionBase)
		'multiply with 0.5 to scale "-2 to +2" down to "-1 to +1"
		'add 1 to get a value between 0 - 2
		Return definition.AudienceAttraction.Copy().MultiplyFloat(0.5).AddFloat(1.0).CutBordersFloat(0, 2.0)
	End Method

	Method GetTargetGroupAttractivityMod:TAudience()
		Return New TAudience.InitValue(1, 1)
	End Method
	
	'default implementation
	'return a value between 0 - 1.0
	'describes how much of a potential trailer-bonus of 100% was reached
	Method GetTrailerMod:TAudience()
		Return new TAudience.InitValue(0, 0)
	End Method	

	
	'default implementation
	Method GetMiscMod:TAudience(hour:Int)
		Return new TAudience.InitValue(0, 0)
	End Method

	
	'default implementation
	Method GetPublicImageMod:TAudience()
		local pubImage:TPublicImage = GetPublicImageCollection().Get(owner)
		If not pubImage Then Throw TNullObjectExceptionExt.Create("The programme '" + GetTitle() + "' has an owner without publicimage.")

		'multiplication-value
		Local result:TAudience = pubImage.GetAttractionMods()
		result.MultiplyFloat(0.35)
		result.SubtractFloat(0.35)
		result.CutBordersFloat(-0.35, 0.35)
		Return result
	End Method	

	
	'default implementation
	Method GetQualityOverTimeEffectMod:Float(quality:Float, block:Int )
		If (block <= 1) Then Return 0			
		If (quality < 0.5)
			Return MathHelper.Clamp( ((quality - 0.5)/3) * (block - 1), -0.2, 0.1)
		Else
			Return MathHelper.Clamp( ((quality - 0.5)/6) * (block - 1), -0.2, 0.1)
		EndIf	
	End Method
	

	'default implementation
	Method GetGenreTimeMod:Float(definition:TGenreDefinitionBase, hour:Int)
		Return MathHelper.Clamp(definition.TimeMods[hour], 0, 2)
	End Method

	
	'default implementation
	Method GetLuckMod:TAudience()
		Return new TAudience.InitValue(0, 0)
	End Method

	
	'default implementation
	Method GetAudienceFlowBonus:TAudience(block:Int, result:TAudienceAttraction, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction)
		If lastMovieBlockAttraction And lastMovieBlockAttraction.AudienceFlowBonus Then
			Return lastMovieBlockAttraction.AudienceFlowBonus.Copy().MultiplyFloat(0.25)
		Else
			Return Null
		EndIf		
	End Method


	'default implementation
	'return a value between 0 - 2.0, 1.0 means "no change"
	'takes into consideration all used flags.
	Method GetFlagsTargetGroupMod:TAudience()
		'method does not use a "definition"-param" as flags are a collection
		'of multiple definitions
		'-> in extending types we then know the flags to use...and could
		'   manually calculate things then
		Return New TAudience.InitValue(1, 1)
	End Method


	'default implementation
	'return a value between 0 - 2.0, 1.0 means "no change"
	Method GetFlagsPopularityMod:Float()
		Return 1.0
	End Method
	
	
	'default implementation
	Method GetSequenceEffect:TAudience(block:Int, genreDefinition:TGenreDefinitionBase, predecessor:TAudienceAttraction, currentProgramme:TAudienceAttraction, lastMovieBlockAttraction:TAudienceAttraction )
		Local ret:TAudience
		Local seqCal:TSequenceCalculation = New TSequenceCalculation
		seqCal.Predecessor = predecessor
		seqCal.Successor = currentProgramme

		SetSequenceCalculationPredecessorShare(seqCal, (block = 1 And lastMovieBlockAttraction))		

		Local seqMod:TAudience
		Local borderMax:TAudience
		Local borderMin:TAudience
		
		If genreDefinition
			seqMod = genreDefinition.AudienceAttraction.Copy().DivideFloat(1.3).MultiplyFloat(0.4).AddFloat(0.75) '0.75 - 1.15
			borderMax = genreDefinition.AudienceAttraction.Copy().DivideFloat(10).AddFloat(0.1).CutBordersFloat(0.1, 0.2)
			borderMin = new TAudience.InitValue(-0.2, -0.2).Add(genreDefinition.AudienceAttraction.Copy().DivideFloat(10)) '-2 - -0.7
		Else
			seqMod = new TAudience.InitValue(1, 1)
			borderMax = new TAudience.InitValue(0.15, 0.15)
			borderMin = new TAudience.InitValue(-0.15, -0.15)
		EndIf
		ret = seqCal.GetSequenceDefault(seqMod, seqMod)
		ret.CutBorders(borderMin, borderMax)
		Return ret
	End Method

	
	Method SetSequenceCalculationPredecessorShare(seqCal:TSequenceCalculation, audienceFlow:Int)
		If audienceFlow
			seqCal.PredecessorShareOnShrink  = new TAudience.InitValue(0.3, 0.3)
			seqCal.PredecessorShareOnRise = new TAudience.InitValue(0.2, 0.2)
		Else
			seqCal.PredecessorShareOnShrink  = new TAudience.InitValue(0.4, 0.4)
			seqCal.PredecessorShareOnRise = new TAudience.InitValue(0.2, 0.2)
		End If
	End Method

	
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False )
		Return GetAudienceAttractionInternal(hour, block, lastMovieBlockAttraction, lastNewsBlockAttraction, withSequenceEffect, withLuckEffect )
	End Method
		
	
	Method GetAudienceAttractionInternal:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False )
		Local result:TAudienceAttraction = New TAudienceAttraction
		
		result.BroadcastType = Self.materialType
		Local genreDefinition:TGenreDefinitionBase = GetGenreDefinition()
'RONNY: removed Genre
		If genreDefinition
'			result.Genre = genreDefinition.referenceId
			result.GenreDefinition = genreDefinition
		EndIf

		If owner <= 0 Then Throw TNullObjectExceptionExt.Create("The programme '" + GetTitle() + "' has no owner.")
		If block <= 0 And usedAsType = TVTBroadcastMaterialType.PROGRAMME Then Throw TNullObjectExceptionExt.Create("GetAudienceAttractionInternal: Invalid block param: '" + block + ".")

		'begin of a programme, begin of broadcast - or news show
		If block = 1 Or Not lastMovieBlockAttraction Or usedAsType = TVTBroadcastMaterialType.NEWS
			'1 - Qualität des Programms/Newsevents
			result.Quality = GetQuality()

			If genreDefinition
				'Popularity of the programme/news-genre (PAID-flag for ads)
				result.GenrePopularityMod = GetGenrePopularityMod(genreDefinition)
				'Genre-targetgroup-fit
				result.GenreTargetGroupMod = GetGenreTargetGroupMod(genreDefinition)
			EndIf

			result.FlagsPopularityMod = GetFlagsPopularityMod()
			result.FlagsTargetGroupMod = GetFlagsTargetGroupMod()
			
			'a modifier of the targetgroup attractivity (mix of genre popularity and
			'targetgroup-fit)
			result.targetGroupAttractivityMod = GetTargetGroupAttractivityMod()


			'4 - Trailer
			result.TrailerMod = GetTrailerMod()

			'5 - Flags und anderes
			result.MiscMod = GetMiscMod(hour)

			'6 - Image
			result.PublicImageMod = GetPublicImageMod()
		Else
			'COPY, not reference the childelements to avoid news manipulating
			'movie-attraction-data ... if done on "reference base" keep
			'paying attention to this when modifying the attraction
			result.CopyBaseAttractionFrom(lastMovieBlockAttraction)
		Endif

		'7 - Stetige Auswirkungen der Film-Quali.
		'    Gute Filme bekommen mehr Attraktivität, schlechte Filme
		'    animieren eher zum Umschalten
		'good movies increase "perceived" quality on subsequent blocks
		'bad movies loose on block 2,3...
		result.QualityOverTimeEffectMod = GetQualityOverTimeEffectMod(result.Quality, block)

		'8 - Genres <> Sendezeit
		If genreDefinition
			result.GenreTimeMod = GetGenreTimeMod(genreDefinition, hour)
		EndIf

		'9 - Zufall
		If withLuckEffect Then result.LuckMod = GetLuckMod()

		'calculate intermediary result for AudienceFlowBonus-calculation
		result.Recalculate()

		'10 - Audience Flow
		result.AudienceFlowBonus = GetAudienceFlowBonus(block, result, lastMovieBlockAttraction, lastNewsBlockAttraction) 		

		'11 - Sequence
		If withSequenceEffect
			result.Recalculate()
			result.SequenceEffect = GetSequenceEffect(block, genreDefinition, lastNewsBlockAttraction, result, lastMovieBlockAttraction)
		EndIf


		'calculate final result
		result.Recalculate()

		Return result
	End Method	
End Type