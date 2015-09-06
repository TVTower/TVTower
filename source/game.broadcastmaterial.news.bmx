SuperStrict
'for TBroadcastSequence
Import "game.broadcast.base.bmx"
Import "game.broadcast.genredefinition.news.bmx"
Import "game.broadcastmaterial.base.bmx"
'for TNewsEvent
Import "game.programme.newsevent.bmx"
Import "game.publicimage.bmx"



Type TNewsShow extends TBroadcastMaterial {_exposeToLua="selected"}
	Field news:TBroadcastMaterial[3]
	Field title:string = ""

	Function Create:TNewsShow(title:String="", owner:int=0, newsA:TBroadcastMaterial, newsB:TBroadcastMaterial, newsC:TBroadcastMaterial)
		Local obj:TNewsShow = New TNewsShow
		obj.news[0] = newsA
		obj.news[1] = newsB
		obj.news[2] = newsC
		obj.owner = owner 'cannot use newsA.owner as newsA may be empty...
		obj.title = title

		obj.setMaterialType(TVTBroadcastMaterialType.NEWSSHOW)
		
		Return obj
	End Function


	'override
	Method SourceHasFlag:int(flag:Int) {_exposeToLua}
		for local n:TNews = EachIn news
			if n.SourceHasFlag(flag) then return True
		Next
		return False
	End Method


	'override to inform contained news too
	Method BeginBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.BeginBroadcasting(day, hour, minute, audienceData)

		For local newsEntry:TBroadcastMaterial = EachIn news
			newsEntry.BeginBroadcasting(day, hour, minute, audienceData)
		Next
	End Method


	Method FinishBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.FinishBroadcasting(day, hour, minute, audienceData)

		For local newsEntry:TBroadcastMaterial = EachIn news
			newsEntry.FinishBroadcasting(day, hour, minute, audienceData)
		Next
	End Method


	'returns the audienceAttraction for a newsShow (3 news)
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False )
		Local resultAudienceAttr:TAudienceAttraction = New TAudienceAttraction
		resultAudienceAttr.BroadcastType = TVTBroadcastMaterialType.NEWSSHOW
		resultAudienceAttr.Genre = -1
		resultAudienceAttr.GenrePopularityMod = 0
		resultAudienceAttr.GenreTargetGroupMod = New TAudience
		resultAudienceAttr.PublicImageMod = New TAudience
		resultAudienceAttr.TrailerMod = New TAudience
		resultAudienceAttr.MiscMod = New TAudience
		resultAudienceAttr.AudienceFlowBonus = New TAudience
		resultAudienceAttr.SequenceEffect = New TAudience
		resultAudienceAttr.BaseAttraction = New TAudience
		resultAudienceAttr.FinalAttraction = New TAudience
		resultAudienceAttr.PublicImageAttraction = New TAudience
		resultAudienceAttr.LuckMod = New TAudience

		Local tempAudienceAttr:TAudienceAttraction = null
		for local i:int = 0 to 2
			'RONNY @Manuel: Todo - "Filme" usw. vorbereiten/einplanen
			'               es koennte ja jemand "Trailer" in die News
			'               verpacken - siehe RTL2 und Co.
			Local currentNews:TNews = TNews(news[i])
			If currentNews Then
				tempAudienceAttr = currentNews.GetAudienceAttraction(hour, block, lastMovieBlockAttraction, lastNewsBlockAttraction, withSequenceEffect, withLuckEffect)			
			Else
				tempAudienceAttr = TAudienceAttraction.CreateAndInitAttraction(0.01, 0.01, 0.01,0.01,0.01, 0.01, 0.01, 0.01, 0.01)  
			EndIf

			'different weight for news slots
			If i = 0 Then resultAudienceAttr.AddAttraction(tempAudienceAttr.MultiplyAttrFactor(0.5))
			If i = 1 Then resultAudienceAttr.AddAttraction(tempAudienceAttr.MultiplyAttrFactor(0.3))
			If i = 2 Then resultAudienceAttr.AddAttraction(tempAudienceAttr.MultiplyAttrFactor(0.2))
		Next
		Return resultAudienceAttr
	End Method
rem
	Method CalculateNewsBlockAudienceAttraction:TAudienceAttraction(news:TNews, lastMovieBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False)
		GetAudienceAttractionInternal(
	
	
		Local result:TAudienceAttraction = New TAudienceAttraction
		Local genreDefintion:TNewsGenreDefinition = null

		'1 - Qualität des Programms
		If news Then
			genreDefintion = GetNewsGenreDefinitionCollection().Get(news.GetGenre())
			result.Quality = news.GetQuality()
		Endif
		result.Quality = Max(0.01, Min(0.99, result.Quality))

		If genreDefintion Then
			'2 - Mod: Genre-Popularität / Trend
			result.GenrePopularityMod = Max(-0.5, Min(0.5, genreDefintion.Popularity.Popularity / 100)) 'Popularity => Wert zwischen -50 und +50

			'3 - Genre <> Zielgruppe
			result.GenreTargetGroupMod = genreDefintion.AudienceAttraction.Copy()
			result.GenreTargetGroupMod.MultiplyFloat(1.2)
			result.GenreTargetGroupMod.SubtractFloat(0.6)
			result.GenreTargetGroupMod.CutBordersFloat(-0.6, 0.6)
		Else
			'2 - Mod: Genre-Popularität / Trend
			result.GenrePopularityMod = 0
			'3 - Genre <> Zielgruppe
			result.GenreTargetGroupMod = TAudience.CreateAndInitValue(0)
		Endif

		'4 - Trailer
		result.TrailerMod = null

		'5 - Flags und anderes
		result.MiscMod = null

		'4 - Image
		local pubImage:TPublicImage = GetPublicImageCollection().Get(owner)
		If not pubImage Then Throw TNullObjectExceptionExt.Create("The news '" + GetTitle() + "' has an owner without publicimage.")

		'6 - Image
		result.PublicImageMod = pubImage.GetAttractionMods() '0 bis 2
		result.PublicImageMod.MultiplyFloat(0.35)
		result.PublicImageMod.SubtractFloat(0.35)
		result.PublicImageMod.CutBordersFloat(-0.35, 0.35)

		'7 - Stetige Auswirkungen der Film-Quali. Gute Filme bekommen mehr Attraktivität, schlechte Filme animieren eher zum Umschalten
		result.QualityOverTimeEffectMod = 0

		'8 - Genres <> Sendezeit
		result.GenreTimeMod = 0 'TODO

		'9 - Zufall
		If withLuckEffect Then
			result.LuckMod = TAudience.CreateAndInitValue(0)
		EndIf

		'10 - Audience Flow
		If lastMovieBlockAttraction And lastMovieBlockAttraction.AudienceFlowBonus Then
			result.AudienceFlowBonus = lastMovieBlockAttraction.AudienceFlowBonus.Copy().MultiplyFloat(0.25)
		EndIf

		result.Recalculate()

		'11 - Sequence
		If withSequenceEffect Then
			Local seqCal:TSequenceCalculation = New TSequenceCalculation
			seqCal.Predecessor = lastMovieBlockAttraction
			seqCal.Successor = result

			seqCal.PredecessorShareOnShrink  = TAudience.CreateAndInitValue(0.5)
			seqCal.PredecessorShareOnRise = TAudience.CreateAndInitValue(0.5)

			Local seqMod:TAudience
			If genreDefintion Then
				seqMod = genreDefintion.AudienceAttraction.Copy().DivideFloat(1.3).MultiplyFloat(0.4).AddFloat(0.75) '0.75 - 1.15
			Else
				seqMod = TAudience.CreateAndInitValue(1)
			EndIf

			result.SequenceEffect = seqCal.GetSequenceDefault(seqMod, seqMod)

			result.SequenceEffect.CutBordersFloat(-0.4, 0.3)
		EndIf

		result.Recalculate()

		Return result
	End Method
endrem

	'override default getter to make event id the reference id
	Method GetReferenceID:int() {_exposeToLua}
		return self.id
	End Method


	'override default
    Method GetTitle:string() {_exposeToLua}
		return title
    End Method


	'override default
    Method GetDescription:string() {_exposeToLua}
		local text:string = "Inhalt:~n"
		for local i:int = 0 to 2
			if news[i] then text = text + news[i].getTitle()+"~n"
		Next
		return text
    End Method


	Method GetQuality:Float() {_exposeToLua}
		Local quality:Float = 0.0
		local count:int = 0
		for local i:int = 0 to 2
			if TNews(news[i]) then quality:+TNews(news[i]).GetQuality();count:+1
		Next
		if count > 0 then quality :/ count

		'no minus quote
		Return Max(0, quality)
	End Method
End Type




'This object stores a players news.
Type TNews extends TBroadcastMaterialDefaultImpl {_exposeToLua="selected"}
    Field newsEvent:TNewsEvent	= Null	{_exposeToLua}
    'delay the news for a certain time (depending on the abonnement-level)
    Field publishDelay:Int = 0
    'store the event happenedTime here, so the event could get used
    'multiple times without changing the news
    Field happenedTime:Double = -1
    'modificators to this news (stored here: is individual for each player)
    'absolute: value just gets added
    'relative: fraction of base price (eg. 0.3 -> 30%)
	Field priceModRelativeNewsAgency:float = 0.0
	Field priceModAbsoluteNewsAgency:int = 0

    'the price which was paid for the news
    Field paidPrice:int = 0
    Field paid:int = 0




	Function Create:TNews(text:String="unknown", publishdelay:Int=0, useNewsEvent:TNewsEvent=Null)
		If not useNewsEvent
			useNewsEvent = GetNewsEventCollection().GetRandomAvailable()
			useNewsEvent.doHappen()
		endif

		'if no happened time is set, use the Game time
		if useNewsEvent.happenedtime <= 0 then useNewsEvent.happenedtime = GetWorldTime().GetTimeGone()

		Local obj:TNews = New TNews
		obj.publishDelay = publishdelay
		obj.newsEvent = useNewsEvent

		obj.setMaterialType(TVTBroadcastMaterialType.NEWS)
		
		Return obj
	End Function


	'override
	Method SourceHasFlag:int(flag:Int) {_exposeToLua}
		return newsEvent.HasFlag(flag)
	End Method


	Method GetHappenedTime:Double()
		if happenedTime = -1 then happenedTime = newsEvent.happenedTime
		return happenedTime
	End Method


	'override default to inform contained "newsEvent" too
	Method BeginBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.BeginBroadcasting(day, hour, minute, audienceData)

		'inform newsEvent that it gets broadcasted by a player
		newsEvent.doBeginBroadcast(owner)
	End Method


	'override
	Method FinishBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.FinishBroadcasting(day, hour, minute, audienceData)

		'inform newsEvent that it gets broadcasted by a player
		newsEvent.doFinishBroadcast(owner)

		'adjust topicality relative to possible audience 
		local audienceResult:TAudienceResult = TAudienceResult(audienceData)
		newsEvent.CutTopicality( GetTopicalityCutModifier(audienceResult.GetWholeMarketAudienceQuotePercentage()) )

		newsEvent.SetTimesBroadcasted( newsEvent.GetTimesBroadcasted(owner) + 1, owner )
	End Method


	Method SetSequenceCalculationPredecessorShare(seqCal:TSequenceCalculation, audienceFlow:Int)
		seqCal.PredecessorShareOnShrink  = TAudience.CreateAndInitValue(0.4) '0.5
		seqCal.PredecessorShareOnRise = TAudience.CreateAndInitValue(0.4) '0.5
	End Method	
	
rem
	'returns the audienceAttraction for one (single!) news
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False )
		'each potential news audience is calculated
		'as if this news is the only one in the show
		'at the end someone (the engine) has to weight the
		'audience (eg. slot1=50%, slot2=30%, slot3=20%)

		Local genreDefintion:TNewsGenreDefinition = GetNewsGenreDefinitionCollection().Get(GetGenre())
		Return genreDefintion.CalculateAudienceAttraction(self, GetWorldTime().GetHour())
	End Method
endrem

	Method GetQuality:Float() {_exposeToLua}
		local quality:float = newsEvent.GetQuality()
		'extra bonus for first broadcast 
		If newsEvent.GetTimesBroadcasted() = 0 Then quality :* 1.15		
		return Max(0.01, Min(0.99, quality))
	End Method


	'returns the price of this news
	'price differs from the (base) price of the newsEvent
	Method GetPrice:int() {_exposeToLua}
		'the price is fixed in the moment of getting bought
		if paid and paidPrice<>0 then return paidPrice

		'calculate the price including modifications
		local price:int = newsEvent.ComputeBasePrice()
		'add modificators
		price :+ priceModRelativeNewsAgency * price
		price :+ priceModAbsoluteNewsAgency
		return price
	End Method


    Method Pay:int()
		'only pay if not already done
		if not paid then paid = GetPlayerFinance(owner).PayNews(GetPrice(), self)
		'store the paid price as the price "sinks" during aging
		if paid and paidPrice = 0 then paidPrice = GetPrice()
		return paid
    End Method


	'override default getter to make event id the reference id
	Method GetReferenceID:int() {_exposeToLua}
		return newsEvent.id
	End Method


	'override default
    Method GetTitle:string() {_exposeToLua}
		return newsEvent.GetTitle()
    End Method


	'override default
    Method GetDescription:string() {_exposeToLua}
		return newsEvent.GetDescription()
    End Method


    Method GetPublishTime:int() {_exposeToLua}
		return GetHappenedTime() + publishdelay
    End Method


	Method IsReadyToPublish:Int() {_exposeToLua}
		Return (GetHappenedtime() + publishDelay <= GetWorldTime().GetTimeGone())
	End Method


	Method GetGenre:int() {_exposeToLua}
		return newsEvent.genre
	End Method


	Method GetGenreString:string() {_exposeToLua}
		return TNewsEvent.GetGenreString(newsEvent.genre)
	End Method


	Method GetNewsEvent:TNewsEvent() {_exposeToLua}
		return newsEvent
	End Method


	'===== AI-LUA HELPER FUNCTIONS =====

	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		return newsEvent.GetAttractiveness()
	End Method
	'===== END AI-LUA HELPER FUNCTIONS =====
End Type
