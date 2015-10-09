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

	'weight of the news slots
	CONST NEWS_WEIGHT_1:float = 0.45
	CONST NEWS_WEIGHT_2:float = 0.35
	CONST NEWS_WEIGHT_3:float = 0.2


	Function Create:TNewsShow(title:String="", owner:int=0, newsA:TBroadcastMaterial, newsB:TBroadcastMaterial, newsC:TBroadcastMaterial)
		Local obj:TNewsShow = New TNewsShow
		obj.news[0] = newsA
		obj.news[1] = newsB
		obj.news[2] = newsC
		obj.owner = owner 'cannot use newsA.owner as newsA may be empty...
		obj.title = title

		obj.setMaterialType(TVTBroadcastMaterialType.NEWSSHOW)
		'by default a freshly created programme is of its own type
		obj.setUsedAsType(TVTBroadcastMaterialType.ADVERTISEMENT)

		Return obj
	End Function


	'override
	Method SourceHasBroadcastFlag:int(flag:Int) {_exposeToLua}
		for local n:TNews = EachIn news
			if n.SourceHasBroadcastFlag(flag) then return True
		Next
		return False
	End Method


	Method IsControllable:int() {_exposeToLua}
		For local n:TNews = EachIn news
			if not n.IsControllable() then return False
		Next
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

		'adjust topicality relative to possible audience 
		local audienceResult:TAudienceResult = TAudienceResult(audienceData)

		local newsSlot:int 
		for local i:int = 0 to 2
			local newsEntry:TBroadcastMaterial = news[i]
			if not newsEntry then continue

			newsEntry.FinishBroadcasting(day, hour, minute, audienceData)

			local news:TNews = TNews(newsEntry)
			if news
				'adjust trend/popularity
				local popData:TData = new TData
				popData.AddNumber("attractionQuality", audienceResult.AudienceAttraction.Quality)
				popData.AddNumber("audienceSum", audienceResult.Audience.GetTotalSum())
				popData.AddNumber("broadcastTopAudience", GetBroadcastManager().GetCurrentBroadcast().GetTopAudience())

				Local popularity:TGenrePopularity = news.newsEvent.GetGenreDefinition().GetPopularity()
if popularity
				popularity.FinishBroadcastingNews(popData, i+1)
else
	TLogger.Log("FinishBroadcastingNews", "Popularity inexistent.", LOG_ERROR)
	debugstop
endif
			endif

		Next
	End Method


	'returns the audienceAttraction for a newsShow (3 news)
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False )
		Local resultAudienceAttr:TAudienceAttraction = New TAudienceAttraction
		resultAudienceAttr.BroadcastType = TVTBroadcastMaterialType.NEWSSHOW
'RONNY: removed Genre (contained in genreDefinition if set
'		resultAudienceAttr.Genre = -1
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

		for local i:int = 0 to 2
			'RONNY @Manuel: Todo - "Filme" usw. vorbereiten/einplanen
			'               es koennte ja jemand "Trailer" in die News
			'               verpacken - siehe RTL2 und Co.
			Local currentNews:TNews = TNews(news[i])
			'skip empty slots
			If not currentNews Then continue
			
			'fix broken (old) savegame-information
			if currentNews.usedAsType = 0
				currentNews.setUsedAsType(TVTBroadcastMaterialType.NEWS)
			endif

			Local tempAudienceAttr:TAudienceAttraction = currentNews.GetAudienceAttraction(hour, block, lastMovieBlockAttraction, lastNewsBlockAttraction, withSequenceEffect, withLuckEffect)			

			'different weight for news slots
			If i = 0 Then resultAudienceAttr.AddAttraction(tempAudienceAttr.MultiplyAttrFactor(NEWS_WEIGHT_1))
			If i = 1 Then resultAudienceAttr.AddAttraction(tempAudienceAttr.MultiplyAttrFactor(NEWS_WEIGHT_2))
			If i = 2 Then resultAudienceAttr.AddAttraction(tempAudienceAttr.MultiplyAttrFactor(NEWS_WEIGHT_3))

			local title:string = "--"
			if currentNews then title = currentNews.GetTitle() 
			'print owner+")  news"+i+":  " +tempAudienceAttr.ToString() +"   " + title +"  usedAs:"+usedAsType

		Next
		'print owner+")  newsA:  " + resultAudienceAttr.ToString()
		Return resultAudienceAttr
	End Method


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

		If TNews(news[0]) Then quality :+ TNews(news[0]).GetQuality() * NEWS_WEIGHT_1
		If TNews(news[1]) Then quality :+ TNews(news[1]).GetQuality() * NEWS_WEIGHT_2
		If TNews(news[2]) Then quality :+ TNews(news[2]).GetQuality() * NEWS_WEIGHT_3

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
		'by default a freshly created programme is of its own type
		obj.setUsedAsType(TVTBroadcastMaterialType.NEWS)
		
		Return obj
	End Function


	'override
	Method SourceHasBroadcastFlag:int(flag:Int) {_exposeToLua}
		return newsEvent.HasBroadcastFlag(flag)
	End Method


	Method GetHappenedTime:Double()
		If happenedTime = - 1 Then happenedTime = newsEvent.happenedTime
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
		Local audienceResult:TAudienceResult = TAudienceResult(audienceData)
		newsEvent.CutTopicality( GetTopicalityCutModifier(audienceResult.GetWholeMarketAudienceQuotePercentage() ) )

		newsEvent.SetTimesBroadcasted( newsEvent.GetTimesBroadcasted(owner) + 1, owner )
	End Method


	Method SetSequenceCalculationPredecessorShare(seqCal:TSequenceCalculation, audienceFlow:Int)
		seqCal.PredecessorShareOnShrink = new TAudience.InitValue(0.4, 0.4) '0.5
		seqCal.PredecessorShareOnRise = new TAudience.InitValue(0.4, 0.4) '0.5
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
		Local quality:Float = newsEvent.GetQuality()
		'extra bonus for first broadcast 
		If newsEvent.GetTimesBroadcasted() = 0 Then quality :* 1.10
		Return MathHelper.Clamp(quality, 0.01, 0.99)
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


	'override
	Method GetGenreDefinition:TGenreDefinitionBase()
		Return newsEvent.GetGenreDefinition()
	End Method
	

	'===== AI-LUA HELPER FUNCTIONS =====

	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		return newsEvent.GetAttractiveness()
	End Method
	'===== END AI-LUA HELPER FUNCTIONS =====
End Type
