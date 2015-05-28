SuperStrict
Import "game.gameobject.bmx"
Import "game.broadcast.genredefinition.base.bmx"
Import "game.broadcast.audienceattraction.bmx"
Import "game.broadcast.sequencecalculation.bmx"
Import "game.publicimage.bmx"


'Base type for programmes, advertisements...
Type TBroadcastMaterial	extends TNamedGameObject {_exposeToLua="selected"}
	Field state:int				= 0		'by default the state is "normal"
	Field materialType:int		= 0		'original material type (may differ to usage!)
	Field usedAsType:int		= 0		'the type this material is used for (programme as adspot -> trailer)
	Field useableAsType:int		= 0		'the type this material can be used for (so we can forbid certain ads as tvshow etc)

	Field programmedHour:int	= -1	'time at which the material is planned to get send
	Field programmedDay:int		= -1

	Field currentBlockBroadcasting:int		{_exposeToLua} '0 = läuft nicht; 1 = 1 Block; 2 = 2 Block; usw.

	'states a program can be in
	Const STATE_NORMAL:int		= 0
	Const STATE_OK:int			= 1
	Const STATE_FAILED:int		= 2
	Const STATE_RUNNING:int		= 3
	'types of broadcastmaterial
	Const TYPE_UNKNOWN:int		= 1
	Const TYPE_PROGRAMME:int	= 2
	Const TYPE_ADVERTISEMENT:int= 4
	Const TYPE_NEWS:int			= 8
	Const TYPE_NEWSSHOW:int		= 16


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


	Method GetBlocks:int(broadcastType:int=0) {_exposeToLua}
		Return 1
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
End Type


Type TBroadcastMaterialDefaultImpl extends TBroadcastMaterial {_exposeToLua="selected"}
	'default implementation	
	Method GenrePopularityMod:Float(genreDefinition:TGenreDefinitionBase)
		Return Max(-0.5, Min(0.5, genreDefinition.Popularity.Popularity / 100)) 'Popularity => Wert zwischen -50 und +50
	End Method
	
	'default implementation
	Method GenreTargetGroupMod:TAudience(genreDefinition:TGenreDefinitionBase)
		'Zwischenlösung bis alle sumgestellt
		Return genreDefinition.AudienceAttraction.Copy().DivideFloat(2).CutBordersFloat(-0.6, 0.6)
		'Return genreDefinition.AudienceAttraction.Copy() - Später		
		'Return genreDefinition.AudienceAttraction.Copy().MultiplyFloat(1.2).SubtractFloat(0.6).CutBordersFloat(-0.6, 0.6)
	End Method
	
	'default implementation
	Method GetTrailerMod:TAudience()
		Return TAudience.CreateAndInitValue(0)
	End Method	
	
	'default implementation
	Method GetMiscMod:TAudience(hour:Int)
		Return TAudience.CreateAndInitValue(0)
	End Method
	
	'default implementation
	Method GetPublicImageMod:TAudience()
		local pubImage:TPublicImage = GetPublicImageCollection().Get(owner)
		If not pubImage Then Throw TNullObjectExceptionExt.Create("The programme '" + GetTitle() + "' has an owner without publicimage.")
	
		Local result:TAudience = pubImage.GetAttractionMods()
		result.MultiplyFloat(0.35)
		result.SubtractFloat(0.35)
		result.CutBordersFloat(-0.35, 0.35)
		Return result
	End Method	
	
	'default implementation
	Method GetQualityOverTimeEffectMod:Float(quality:Float, block:Int )
		If (block = 1) Then Return 0			
		If (quality < 0.5)
			Return Max(-0.2, Min(0.1, ((quality - 0.5)/3) * (block - 1)))
		Else
			Return Max(-0.2, Min(0.1, ((quality - 0.5)/6) * (block - 1)))
		EndIf	
	End Method
	
	'default implementation
	Method GetGenreTimeMod:Float(genreDefinition:TGenreDefinitionBase, hour:Int)
		Return genreDefinition.TimeMods[hour] - 1 'Genre/Zeit-Mod
	End Method
	
	'default implementation
	Method GetLuckMod:TAudience()
		Return TAudience.CreateAndInitValue(0)
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
			borderMin = TAudience.CreateAndInitValue(-0.2).Add(genreDefinition.AudienceAttraction.Copy().DivideFloat(10)) '-2 - -0.7
		Else
			seqMod = TAudience.CreateAndInitValue(1)
			borderMax = TAudience.CreateAndInitValue(0.15)
			borderMin = TAudience.CreateAndInitValue(-0.15)
		EndIf
		ret = seqCal.GetSequenceDefault(seqMod, seqMod)
		ret.CutBorders(borderMin, borderMax)
		Return ret
	End Method
	
	Method SetSequenceCalculationPredecessorShare(seqCal:TSequenceCalculation, audienceFlow:Int)
		If audienceFlow
			seqCal.PredecessorShareOnShrink  = TAudience.CreateAndInitValue(0.3)
			seqCal.PredecessorShareOnRise = TAudience.CreateAndInitValue(0.2)
		Else
			seqCal.PredecessorShareOnShrink  = TAudience.CreateAndInitValue(0.4)
			seqCal.PredecessorShareOnRise = TAudience.CreateAndInitValue(0.2)
		End If
	End Method
	
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False )
		Return GetAudienceAttractionInternal(hour, block, lastMovieBlockAttraction, lastNewsBlockAttraction, withSequenceEffect, withLuckEffect )
	End Method		
	
	Method GetAudienceAttractionInternal:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False )
		Local result:TAudienceAttraction = New TAudienceAttraction
		
		result.BroadcastType = Self.materialType
		Local genreDefinition:TGenreDefinitionBase = GetGenreDefinition()
		If genreDefinition
			result.Genre = genreDefinition.GenreId
			result.GenreDefinition = genreDefinition
		EndIf

		if owner <= 0 Then Throw TNullObjectExceptionExt.Create("The programme '" + GetTitle() + "' has no owner.")
		if block <= 0 and usedAsType = TYPE_PROGRAMME Then Throw TNullObjectExceptionExt.Create("GetAudienceAttractionInternal: Invalid block param: '" + block + ".")

		If block = 1 Or Not lastMovieBlockAttraction Then
			'1 - Qualität des Programms
			result.Quality = GetQuality()

			'2 - Mod: Genre-Popularität / Trend
			If genreDefinition
				result.GenrePopularityMod = GenrePopularityMod(genreDefinition)
			EndIf

			'3 - Genre <> Zielgruppe
			If genreDefinition
				result.GenreTargetGroupMod = GenreTargetGroupMod(genreDefinition)
			EndIf

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

		'7 - Stetige Auswirkungen der Film-Quali. Gute Filme bekommen mehr Attraktivität, schlechte Filme animieren eher zum Umschalten
		result.QualityOverTimeEffectMod = GetQualityOverTimeEffectMod(result.Quality, block)

		'8 - Genres <> Sendezeit
		If genreDefinition
			result.GenreTimeMod = GetGenreTimeMod(genreDefinition, hour)
		EndIf

		'9 - Zufall
		If withLuckEffect Then result.LuckMod = GetLuckMod()

		result.Recalculate()

		'10 - Audience Flow
		result.AudienceFlowBonus = GetAudienceFlowBonus(block, result, lastMovieBlockAttraction, lastNewsBlockAttraction) 		

		result.Recalculate()

		'11 - Sequence
		If withSequenceEffect Then
			result.SequenceEffect = GetSequenceEffect(block, genreDefinition, lastNewsBlockAttraction, result, lastMovieBlockAttraction)
			result.Recalculate()
		EndIf

		Return result
	End Method	
End Type