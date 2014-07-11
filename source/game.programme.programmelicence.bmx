Rem
	====================================================================
	ProgrammeLicence data - basics of broadcastable programme
	====================================================================
EndRem
SuperStrict
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "game.gameobject.bmx"
Import "game.broadcastmaterial.base.bmx"
Import "game.programme.programmedata.bmx"
Import "game.player.finance.bmx"
Import "basefunctions.bmx" 'CreateEmptyImage()


'licence of for movies, series and so on
Type TProgrammeLicence Extends TNamedGameObject {_exposeToLua="selected"}
	Field title:string			= ""
	Field description:string	= ""
	Field licenceType:int		= 1					'type of that programmelicence
	Field attractiveness:Float	= -1				'Wird nur in der Lua-KI verwendet um die Lizenzen zu bewerten
	Field data:TProgrammeData				{_exposeToLua}
	Field latestPlannedEndHour:int = -1				'the latest hour-(from-start) one of the planned programmes ends
	Field parentLicence:TProgrammeLicence			'series are parent of episodes
	Field subLicences:TProgrammeLicence[]			'other licences this licence covers
	Field cacheTextOverlay:TImage 			{nosave}
	Field cacheTextOverlayMode:string = ""	{nosave}	'for which mode the text was cached

	Global licences:TList		= CreateList()		'holding all programme licences
	Global collections:TList	= CreateList()		'holding only licences of special packages containing multiple movies/series
	Global movies:TList			= CreateList()		'holding only movie licences
	Global series:TList			= CreateList()		'holding only series licences

	Global ignoreUnreleasedProgrammes:int	= TRUE	'hide movies of 2012 when in 1985?
	Global _filterReleaseDateStart:int		= 1900
	Global _filterReleaseDateEnd:int		= 2100

	const TYPE_UNKNOWN:int		= 1
	const TYPE_EPISODE:int		= 2
	const TYPE_SERIES:int		= 4
	const TYPE_MOVIE:int		= 8
	const TYPE_COLLECTION:int	= 16



	Function Create:TProgrammeLicence(title:String, description:String, licenceType:int=1)
		Local obj:TProgrammeLicence =New TProgrammeLicence
		obj.title		= title
		obj.description	= description
		obj.licenceType	= licenceType

		Return obj
	End Function


	'directly connect the licence to a programmeData
	Method AddData:int(data:TProgrammeData)
		self.data = data
		self.licenceType = data.programmeType

		'we got direct content - so add that licence to the global list
		'a) exception are episodes...they have to get fetched through the series head
		'if not isEpisode() and not licences.contains(self) then licences.addLast(self)

		'b) store all licences to enable collections of episodes from multiple series/seasons
		if not licences.contains(self) then licences.addLast(self)

		'only "Movies" are stored separately,
		'episodes are listed in a series which gets added
		'during adding of episodes
		if isMovie()
			'print "AddData: movie " + data.getTitle()
			if not movies.contains(self) then movies.addLast(self)
		endif

		'shouldn't be needed: set type to the one of programmedata
		'data.licenceType = data.programmeType


		return TRUE
	End Method


	Method GetReferenceID:int() {_exposeToLua}
		'return own licence id as referenceID - programme.id is not
		'possible for collections/series
		return self.ID
	End Method


	Method GetData:TProgrammeData() {_exposeToLua}
		'if not self.data then print "[ERROR] data for TProgrammeLicence with title: ~q"+title+"~q is missing."
		return self.data
	End Method


	Method GetSubLicenceCount:int() {_exposeToLua}
		return subLicences.length
	End Method


	Method GetSubLicenceAtIndex:TProgrammeLicence(arrayIndex:int=1) {_exposeToLua}
		if arrayIndex > subLicences.length or arrayIndex < 0 then return null
		return subLicences[arrayIndex]
	End Method


	Method AddSubLicence:int(licence:TProgrammeLicence)
		'only do this if "series" does not have own data...
		'but as they can contain a "general description", we allow it
		'as soon as a licence is connected to a programmeData, adding
		'sublicences is not allowed
		'if self.getData() then return FALSE

		'movies and episodes need "data", without we skip that licence
		if licence.isType(TYPE_MOVIE | TYPE_EPISODE) and not licence.getData() then return FALSE

		'print "AddSubLicence "+self.licenceType+" "+self.getTitle()+"  adding title="+licence.getTitle()

		'if the licence has no special type up to now...
		if licence.isType(TYPE_UNKNOWN)
			'we got content - so add the current licence to the global list
			if not licences.contains(self) then licences.addLast(self)
		endif

		'a series episode is added to a series licence
		'-> has data and is of correct type (checked at begin of method)
		if licence.isType(TYPE_EPISODE)
			'set the current licence to type "series"
			self.licenceType = TYPE_SERIES

			'add series licence as parent for this episode
			licence.parentLicence = self

			'add series if not done yet
			if not series.contains(self) then series.addLast(self)
		endif

		'a series is added to a licence (series-heads do not have data) -> gets a collection
		if licence.isType(TYPE_SERIES) then self.licenceType = TYPE_COLLECTION
		'licence is a movie
		if licence.isType(TYPE_MOVIE) then self.licenceType = TYPE_COLLECTION

		'add collections to their list
		if self.isType(TYPE_MOVIE) and not collections.contains(self) then collections.addLast(self)

		'resize array of sublicences first, then add licence
		subLicences = subLicences[.. subLicences.length+1]
		subLicences[subLicences.length-1] = licence
		Return TRUE
	End Method


	Method isType:int(licenceType:int) {_exposeToLua}
		return (self.licenceType & licenceType)
	End Method

	Method isSeries:int() {_exposeToLua}
		return (self.licenceType & self.TYPE_SERIES)
	End Method

	Method isEpisode:int() {_exposeToLua}
		return (self.licenceType & self.TYPE_EPISODE)
	End Method

	Method isMovie:int() {_exposeToLua}
		return (self.licenceType & self.TYPE_MOVIE)
	End Method

	Method isCollection:int() {_exposeToLua}
		return (self.licenceType & self.TYPE_COLLECTION)
	End Method

	Function setIgnoreUnreleasedProgrammes(ignore:int=TRUE, releaseStart:int=1900, releaseEnd:int=2100)
		ignoreUnreleasedProgrammes = ignore
		_filterReleaseDateStart = releaseStart
		_filterReleaseDateEnd = releaseEnd
	End Function


	'override default method to add sublicences
	Method SetOwner:int(owner:int=0)
		self.owner = owner
		'do the same for all children
		For local licence:TProgrammeLicence = eachin subLicences
			licence.SetOwner(owner)
		Next
		return TRUE
	End Method


	Method Sell:int()
		local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(owner,-1)
		if not finance then return False

		finance.SellProgrammeLicence(getPrice(), self)

		'set unused again
		SetOwner(0)

		return TRUE
	End Method


	'buy means pay and set owner, but in players collection only if left the room!!
	Method Buy:Int(playerID:Int=-1)
		local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(playerID, -1)
		if not finance then return False

		If finance.PayProgrammeLicence(getPrice(), self)
			SetOwner(playerID)
			Return TRUE
		EndIf
		Return FALSE
	End Method


	Method GetParentLicence:TProgrammeLicence() {_exposeToLua}
		if not self.parentLicence then return self
		return self.parentLicence
	End Method


	Method GetSubLicencePosition:int(licence:TProgrammeLicence) {_exposeToLua}
		'find my position and add 1
		For local i:int = 0 to GetSubLicenceCount() - 1
			if GetSubLicenceAtIndex(i) = licence then return i
		Next
		return 0
	End Method


	'returns the next licence of a licences parent sublicences
	Method GetNextSubLicence:TProgrammeLicence() {_exposeToLua}
		if not parentLicence then return Null

		'find my position and add 1
		local nextArrayIndex:int = parentLicence.GetSubLicencePosition(self) + 1
		'if we are at the last position, return the first one
		if nextArrayIndex >= parentLicence.GetSubLicenceCount() then nextArrayIndex = 0

		return parentLicence.GetSubLicenceAtIndex(nextArrayIndex)
	End Method


	Method isReleased:int() {_exposeToLua}
		if not self.ignoreUnreleasedProgrammes then return TRUE

		'if connected to a programme - just return our value
		if self.GetData() then return self.GetData().isReleased()

		'if licence is a collection: ask subs
		For local licence:TProgrammeLicence = eachin subLicences
			if not licence.isReleased() then return FALSE
		Next

		return TRUE
	End Method


	'returns the list to use for the given type
	'this is just important for "random" access as we could
	'also just access "progList" in all cases...
	Function _GetList:TList(programmeType:int=0)
		Select programmeType
			case TYPE_MOVIE
				return movies
			case TYPE_SERIES
				return series
			case TYPE_COLLECTION
				return collections
			default
				return licences
		End Select
	End Function


	Global warnedEmptyRandomFromList:int = False
	Function _GetRandomFromList:TProgrammeLicence(_list:TList)

		If _list = Null Then Return Null
		If _list.count() > 0
			Local Licence:TProgrammeLicence = TProgrammeLicence(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			If Licence then return Licence
		EndIf
		if not warnedEmptyRandomFromList
			TLogger.log("TProgrammeLicence._GetRandomFromList()", "list is empty (incorrect filter or not enough available licences?)", LOG_DEBUG | LOG_WARNING | LOG_DEV, TRUE)
			warnedEmptyRandomFromList = true
		endif
		Return Null
	End Function


	Function Get:TProgrammeLicence(id:Int, programmeType:int=0)
		local list:TList = _GetList(programmeType)
		local licence:TProgrammeLicence = null

		For Local i:Int = 0 To list.Count() - 1
			Licence = TProgrammeLicence(list.ValueAtIndex(i))
			if Licence and Licence.id = id Then Return Licence
		Next
		Return Null
	End Function


	Function GetRandom:TProgrammeLicence(programmeType:int=0, includeEpisodes:int=FALSE)
		'filter to entries we need
		Local Licence:TProgrammeLicence
		Local sourceList:TList = _GetList(programmeType)
		Local resultList:TList = CreateList()

		For Licence = EachIn sourceList
			'ignore if filtered out
			If Licence.owner <> 0 or not Licence.isReleased() Then continue
			'ignoring episodes
			If not includeEpisodes and Licence.isEpisode() Then continue

			'if available (unbought, released..), add it to candidates list
			resultList.addLast(Licence)
		Next

		Return _GetRandomFromList(resultList)
	End Function


	Function GetRandomWithPrice:TProgrammeLicence(MinPrice:int=0, MaxPrice:Int=-1, programmeType:int=0, includeEpisodes:int=FALSE)
		'filter to entries we need
		Local Licence:TProgrammeLicence
		Local sourceList:TList = _GetList(programmeType)
		Local resultList:TList = CreateList()

		For Licence = EachIn sourceList
			'ignore if filtered out
			If Licence.owner <> 0 or not Licence.isReleased() Then continue
			'ignoring episodes
			If not includeEpisodes and Licence.isEpisode() Then continue

			'skip if to expensive
			if MaxPrice > 0 and Licence.getPrice() > MaxPrice then continue

			'if available (unbought, released..), add it to candidates list
			If Licence.getPrice() >= MinPrice Then resultList.addLast(Licence)
		Next
		Return _GetRandomFromList(resultList)
	End Function


	Function GetRandomWithGenre:TProgrammeLicence(genre:Int=0, programmeType:int=0, includeEpisodes:int=FALSE)
		Local Licence:TProgrammeLicence
		Local sourceList:TList = _GetList(programmeType)
		Local resultList:TList = CreateList()

		For Licence = EachIn sourceList
			'ignore if filtered out
			If Licence.owner <> 0 or not Licence.isReleased() Then continue
			'ignoring episodes
			If not includeEpisodes and Licence.isEpisode() Then continue

			'if available (unbought, released..), add it to candidates list
			If Licence.GetData()
				if Licence.GetData().getGenre() = genre Then resultList.addLast(Licence)
			else
				local foundGenreInSubLicence:int = FALSE
				for local subLicence:TProgrammeLicence = eachin Licence.subLicences
					if foundGenreInSubLicence then continue
					if subLicence.GetData() and subLicence.GetData().getGenre() = genre
						resultList.addLast(Licence)
						foundGenreInSubLicence = TRUE
					endif
				Next
			endif
		Next
		Return _GetRandomFromList(resultList)
	End Function


	Method setPlanned:int(latestHour:int=-1)
		if latestHour >= 0
			'set to maximum
			self.latestPlannedEndHour = Max(latestHour, self.latestPlannedEndHour)
		else
			'reset
			self.latestPlannedEndHour = -1
		endif
	End Method


	'instead of asking the programmeplan about each licence
	'we cache that information directly within the programmeplan
	Method isPlanned:int() {_exposeToLua}
		if self.GetData()
			if (self.latestPlannedEndHour>=0) then return TRUE
			'if self is not planned - ask if parent is set to planned
			'do not use this for series if used in the programmePlanner-view
			'to "emphasize" planned programmes
			'if self.parentLicence then return self.parentLicence.isPlanned()
		endif

		For local licence:TProgrammeLicence = eachin subLicences
			if licence.isPlanned() then return TRUE
		Next
		return FALSE
	End Method


	'returns the genre of a licence - if a group, the one used the most
	'often is returned
	Method GetGenre:int() {_exposeToLua}
		if self.GetData() then return self.GetData().GetGenre()

		local genres:int[]
		local bestGenre:int=0
		For local licence:TProgrammeLicence = eachin subLicences
			local genre:int = licence.GetGenre()
			if genre > genres.length-1 then genres = genres[..genre+1]
			genres[genre]:+1
		Next
		For local i:int = 0 to genres.length-1
			if genres[i] > bestGenre then bestGenre = i
		Next

		return bestGenre
	End Method


	Method GetQuality:Float() {_exposeToLua}
		'licence is connected to a programme
		if GetData() and (isType(TYPE_MOVIE) or isType(TYPE_EPISODE))
			return GetData().GetQuality()
		endif

		'if licence is a collection: ask subs
		local quality:int = 0
		For local licence:TProgrammeLicence = eachin subLicences
			quality :+ licence.GetQuality()
		Next

		if subLicences.length > 0 then return quality / subLicences.length
		return 0.0
	End Method


	Method GetTitle:string() {_exposeToLua}
		return self.title
	End Method


	Method GetDescription:string() {_exposeToLua}
		return self.description
	End Method


	'returns the avg topicality of a licence (package)
	Method GetTopicality:Int() {_exposeToLua}
		'licence connected to a single programme
		If GetSubLicenceCount() = 0 then return GetData().GetTopicality()

		'licence for a package or series
		Local value:int
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetTopicality()
		Next

		if subLicences.length > 0 then return floor(value / subLicences.length)
		return 0
	End Method


	Method GetPrice:Int() {_exposeToLua}
		'licence connected to a single programme
		If GetSubLicenceCount() = 0 then return GetData().GetPrice()

		'licence for a package or series
		Local value:Float
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetPrice()
		Next
		value :* 0.75

		Return value
	End Method


	Method CutTrailerEfficiency:float()
		'maximum is 100% efficiency (never shown before)
		local efficiency:float = 1.0
		'each air during the last 24 hrs decreases by 5%

	End Method


	Method ShowSheet:Int(x:Int,y:Int, align:int=0, showMode:int=0)
		'set default mode
		if showMode = 0 then showMode = TBroadcastMaterial.TYPE_PROGRAMME

		if KeyManager.IsDown(KEY_LALT) or KeyManager.IsDown(KEY_RALT)
			if showMode = TBroadcastMaterial.TYPE_PROGRAMME
				showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT
			else
				showMode = TBroadcastMaterial.TYPE_PROGRAMME
			endif
		Endif


		if showMode = TBroadcastMaterial.TYPE_PROGRAMME
			if isSeries()
				ShowSeriesSheet(x, y, align)
			else
				ShowSingleSheet(x, y, align)
			endif
		'trailermode
		elseif showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT
			ShowTrailerSheet(x, y, align)
		endif
	End Method


	Method DrawSeriesSheetTextOverlay(x:int, y:int, w:int, h:int)
		'reset cache
		if cacheTextOverlayMode <> "SERIES"
			cacheTextOverlayMode = "SERIES"
			cacheTextOverlay = null
		endif

		'===== CREATE CACHE IF MISSING =====
		if not cacheTextOverlay
			cacheTextOverlay = TFunctions.CreateEmptyImage(w, h)

			'render to image
			TBitmapFont.SetRenderTarget(cacheTextOverlay)

			Local normalFont:TBitmapFont	= GetBitmapFontManager().baseFont
			Local dY:Int = 0

			SetColor 0,0,0
			GetBitmapFontManager().basefontBold.drawBlock(GetTitle(), 10, 11, 278, 20)
			normalFont.drawBlock(self.GetSubLicenceCount()+" "+GetLocale("MOVIE_EPISODES") , 10, 34, 278, 20) 'prints programmedescription on moviesheet
			dy :+ 22

			If data.xrated <> 0 Then normalFont.drawBlock(GetLocale("MOVIE_XRATED") , 240 , dY+34 , 50, 20) 'prints pg-rating

			normalFont.drawBlock(GetLocale("MOVIE_DIRECTOR")+":", 10 , dY+135, 280, 16)
			normalFont.drawBlock(GetLocale("MOVIE_SPEED")		, 222, dY+187, 280, 16)
			normalFont.drawBlock(GetLocale("MOVIE_CRITIC")		, 222, dY+210, 280, 16)
			normalFont.drawBlock(GetLocale("MOVIE_BOXOFFICE")	, 222, dY+233, 280, 16)
			normalFont.drawBlock(data.GetDirectorsString()		, 10 +5+ Int(normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":")) , dY+135, 280-15-normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":"), 16) 	'prints director
			if data.GetActorsString() <> ""
				normalFont.drawBlock(GetLocale("MOVIE_ACTORS")+":", 10 , dY+148, 280, 32)
				normalFont.drawBlock(data.GetActorsString()		, 10 +5+ Int(normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":")), dY+148, 280-15-normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":"), 32) 	'prints actors
			endif
			normalFont.drawBlock(data.GetGenreString()			, 78 , dY+35 , 150, 16) 	'prints genre
			normalFont.drawBlock(data.country					, 10 , dY+35 , 150, 16)		'prints country

			If data.genre <> data.GENRE_CALLINSHOW
				'TODO: add sponsorship display handling here
				normalFont.drawBlock(data.year					, 36 , dY+35 , 150, 16) 	'prints year
				normalFont.drawBlock(data.GetDescription()		, 10,  dy+54 , 282, 71) 'prints programmedescription on moviesheet
			Else
				normalFont.drawBlock(data.GetDescription()		, 10,  dy+54 , 282, 51) 'prints programmedescription on moviesheet
				'convert back cents to euros and round it
				'value is "per 1000" - so multiply with that too
				local revenue:string = int(1000 * data.GetPerViewerRevenue())+" "+CURRENCYSIGN
				normalFont.drawBlock(getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), 10,  dy+106 , 278, 20) 'prints programmedescription on moviesheet
			EndIf

			'set back to screen Rendering
			TBitmapFont.SetRenderTarget(null)
		endif

		'===== DRAW CACHE =====
		DrawImage(cacheTextOverlay, x, y)
	End Method


	Method ShowSeriesSheet:Int(x:Int,y:Int, align:int=0)
		local data:TProgrammeData		= GetData()
		'given in series head too but we want to use the "avg"
		'so we add all episodes data and divide by episodecount -> average
		Local widthbarSpeed:Float			= 0
		Local widthbarReview:Float			= 0
		Local widthbarOutcome:Float			= 0
		Local widthbarTopicality:Float		= 0
		Local widthbarMaxTopicality:Float	= 0

		local episodeCount:float = 0.0
		For local licence:TProgrammeLicence = eachin subLicences
			episodeCount:+1.0
			widthbarSpeed 			:+ licence.GetData().speed
			widthbarReview			:+ licence.GetData().review
			widthbarOutcome			:+ licence.GetData().Outcome
			widthbarTopicality		:+ licence.GetData().topicality
			widthbarMaxTopicality	:+ licence.GetData().GetMaxTopicality()
		Next
		if episodeCount > 0
			widthbarSpeed			= widthbarSpeed / episodeCount / 255.0
			widthbarReview			= widthbarReview / episodeCount / 255.0
			widthbarOutcome			= widthbarOutcome/ episodeCount / 255.0
			widthbarTopicality		= widthbarTopicality / episodeCount / 255.0
			widthbarMaxTopicality	= widthbarMaxTopicality / episodeCount / 255.0
		endif


		local asset:TSprite = GetSpriteFromRegistry("gfx_datasheets_series")
		if align = 1 then x :- asset.area.GetW()

		'===== DRAW PROGRAMMED HINT =====
		if owner > 0 and IsPlanned()
			local warningX:int = x
			local warningY:int = 0
			local warningW:int = 0
			warningY = asset.area.GetH()
			warningW = asset.area.GetW()
			warningY :-15 'minus shadow
			if align = 1 then warningX :- warningW
			SetAlpha 0.5
			SetColor 255,235,110
			DrawRect(warningX+20, y + warningY, warningW-40, 30)
			SetAlpha 0.75
			GetBitmapFontManager().basefontBold.drawBlock("Programm im Sendeplan!", warningX+20, y+warningY+15, warningW-40, 20, new TVec2D.Init(ALIGN_CENTER), TColor.clWhite, 2, 1, 0.5)
			SetAlpha 1.0
			SetColor 255,255,255
		endif

		'===== DRAW SHEET BACKGROUND =====
		asset.Draw(x,y)

		'===== DRAW STATIC TEXTS =====
		DrawSeriesSheetTextOverlay(x, y, asset.area.GetW(), asset.area.GetH())

		'===== DRAW DYNAMIC TEXTS =====
		Local normalFont:TBitmapFont	= GetBitmapFontManager().baseFont
		SetColor 0,0,0
		normalFont.drawBlock(GetLocale("MOVIE_TOPICALITY")  , x+84, y+281, 40, 16)
		normalFont.drawBlock(GetLocale("MOVIE_BLOCKS")+": "+data.GetBlocks(), x+10, y+281, 100, 16)

		local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(owner, -1)
		if not finance or finance.canAfford(getPrice())
			normalFont.drawBlock(GetPrice(), x+240, y+281, 120, 20)
		else
			normalFont.drawBlock(GetPrice(), x+240, y+281, 120, 20, null, TColor.Create(200,0,0))
		endif
		SetColor 255,255,255

		'===== DRAW BARS =====
		If widthbarSpeed   >0.01 Then GetSpriteFromRegistry("gfx_datasheets_bar").DrawResized(new TRectangle.Init(x+13, y+22+188, widthbarSpeed*200  , 10))
		If widthbarReview  >0.01 Then GetSpriteFromRegistry("gfx_datasheets_bar").DrawResized(new TRectangle.Init(x+13, y+22+210, widthbarReview*200 , 10))
		If widthbarOutcome >0.01 Then GetSpriteFromRegistry("gfx_datasheets_bar").DrawResized(new TRectangle.Init(x+13, y+22+232, widthbarOutcome*200, 10))
		SetAlpha 0.3
		If widthbarMaxTopicality>0.01 Then GetSpriteFromRegistry("gfx_datasheets_bar").DrawResized(new TRectangle.Init(x+115, y+280, widthbarMaxTopicality*100, 10))
		SetAlpha 1.0
		If widthbarTopicality>0.01 Then GetSpriteFromRegistry("gfx_datasheets_bar").DrawResized(new TRectangle.Init(x+115, y+280, widthbarTopicality*100, 10))
	End Method


	Method DrawSingleSheetTextOverlay(x:int, y:int, w:int, h:int)
		'reset cache
		if cacheTextOverlayMode <> "SINGLE"
			cacheTextOverlayMode = "SINGLE"
			cacheTextOverlay = null
		endif

		'===== CREATE CACHE IF MISSING =====
		if not cacheTextOverlay
			cacheTextOverlay = TFunctions.CreateEmptyImage(w, h)

			'render to image
			TBitmapFont.SetRenderTarget(cacheTextOverlay)

			Local normalFont:TBitmapFont	= GetBitmapFontManager().baseFont

			If data.xrated <> 0 Then normalFont.drawBlock(GetLocale("MOVIE_XRATED") , 240 , 34 , 50, 20) 'prints pg-rating

			normalFont.drawBlock(GetLocale("MOVIE_DIRECTOR")+":", 10 , 135, 280, 16)
			normalFont.drawBlock(GetLocale("MOVIE_SPEED")       , 222, 187, 280, 16)
			normalFont.drawBlock(GetLocale("MOVIE_CRITIC")      , 222, 210, 280, 16)
			normalFont.drawBlock(GetLocale("MOVIE_BOXOFFICE")   , 222, 233, 280, 16)
			normalFont.drawBlock(data.GetDirectorsString()      , 10 +5+ Int(normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":")) , 135, 280-15-normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":"), 16) 	'prints director
			if data.GetActorsString() <> ""
				normalFont.drawBlock(GetLocale("MOVIE_ACTORS")+":"  , 10 , 148, 280, 32)
				normalFont.drawBlock(data.GetActorsString()		, 10 +5+ Int(normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":")), 148, 280-15-normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":"), 32) 	'prints actors
			endif
			normalFont.drawBlock(data.GetGenreString()		, 78 , 35 , 150, 16) 	'prints genre
			normalFont.drawBlock(data.country				, 10 , 35 , 150, 16)		'prints country

			If data.genre <> TProgrammeData.GENRE_CALLINSHOW
				normalFont.drawBlock(data.year				, 36 , 35 , 150, 16) 	'prints year
				normalFont.drawBlock(data.GetDescription()	, 10,  54 , 282, 71) 'prints programmedescription on moviesheet
			Else
				normalFont.drawBlock(data.GetDescription()	, 10,  54 , 282, 51) 'prints programmedescription on moviesheet

				'convert back cents to euros and round it
				'value is "per 1000" - so multiply with that too
				local revenue:string = int(1000 * data.GetPerViewerRevenue())+" "+CURRENCYSIGN
				normalFont.drawBlock(getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), 10,  106 , 278, 20) 'prints programmedescription on moviesheet
			EndIf


			'set back to screen Rendering
			TBitmapFont.SetRenderTarget(null)
		endif

		'===== DRAW CACHE =====
		DrawImage(cacheTextOverlay, x, y)
	End Method


	Method ShowSingleSheet:Int(x:Int,y:Int, align:int=0)
		local data:TProgrammeData		= GetData()
		Local widthbarSpeed:Float		= Float(data.speed / 255.0)
		Local widthbarReview:Float		= Float(data.review / 255.0)
		Local widthbarOutcome:Float		= Float(data.Outcome/ 255.0)
		Local widthbarTopicality:Float	= Float(data.topicality / 255.0)
		Local widthbarMaxTopicality:Float= Float(data.GetMaxTopicality() / 255.0)
		Local normalFont:TBitmapFont	= GetBitmapFontManager().baseFont

		Local dY:Int = 0
		local asset:TSprite = null
		if data.isMovie()
			asset = GetSpriteFromRegistry("gfx_datasheets_movie")
		else
			asset = GetSpriteFromRegistry("gfx_datasheets_series")
		endif


		if owner > 0 'and GetPlayerCollection().Get().figure.inRoom
			'only if planend and in archive
			if self.IsPlanned() ' and GetPlayerCollection().Get().figure.inRoom.name = "archive"
				local warningX:int = x
				local warningY:int = asset.area.GetH()
				local warningW:int = asset.area.GetW()
				warningY :-15 'minus shadow
				if align = 1 then warningX :- warningW
				SetAlpha 0.5
				SetColor 255,235,110
				DrawRect(warningX+20, y + warningY, warningW-40, 30)
				SetAlpha 0.75
				GetBitmapFontManager().basefontBold.drawBlock("Programm im Sendeplan!", warningX+20, y+warningY+15, warningW-40, 20, new TVec2D.Init(ALIGN_CENTER), TColor.clWhite, 2, 1, 0.5)
				SetAlpha 1.0
				SetColor 255,255,255
			endif
		endif

		If data.isMovie()
			if align = 1 then x :- GetSpriteFromRegistry("gfx_datasheets_movie").area.GetW()
			GetSpriteFromRegistry("gfx_datasheets_movie").Draw(x,y)
			SetColor 0,0,0
			GetBitmapFontManager().basefontBold.drawBlock(GetTitle(), x + 10, y + 11, 278, 20)
		Else
			if align = 1 then x :- GetSpriteFromRegistry("gfx_datasheets_series").area.GetW()

			GetSpriteFromRegistry("gfx_datasheets_series").Draw(x,y)
			SetColor 0,0,0
			'episode display
			GetBitmapFontManager().basefontBold.drawBlock(parentLicence.GetTitle(), x + 10, y + 11, 278, 20)
			normalFont.drawBlock("(" + (parentLicence.GetSubLicencePosition(self)+1) + "/" + parentLicence.GetSubLicenceCount() + ") " + data.GetTitle(), x + 10, y + 34, 278, 20)  'prints programmedescription on moviesheet

			dy :+ 22
		EndIf

		'===== DRAW STATIC TEXTS =====
		DrawSingleSheetTextOverlay(x, y + dy, asset.area.GetW(), asset.area.GetH() - dy)

		'===== DRAW DYNAMIC TEXTS =====
		SetColor 0,0,0
		normalFont.drawBlock(GetLocale("MOVIE_TOPICALITY")  , x+84, y+281, 40, 16)
		normalFont.drawBlock(GetLocale("MOVIE_BLOCKS")+": "+data.GetBlocks(), x+10, y+281, 100, 16)

		local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(owner, -1)
		if not finance or finance.canAfford(getPrice())
			normalFont.drawBlock(GetPrice(), x+240, y+281, 120, 20)
		else
			normalFont.drawBlock(GetPrice(), x+240, y+281, 120, 20, null, TColor.Create(200,0,0))
		endif
		SetColor 255,255,255

		'===== DRAW BARS =====
		If widthbarSpeed   >0.01 Then GetSpriteFromRegistry("gfx_datasheets_bar").DrawResized(new TRectangle.Init(x+13, y+dY+188, widthbarSpeed*200  , 10))
		If widthbarReview  >0.01 Then GetSpriteFromRegistry("gfx_datasheets_bar").DrawResized(new TRectangle.Init(x+13, y+dY+210, widthbarReview*200 , 10))
		If widthbarOutcome >0.01 Then GetSpriteFromRegistry("gfx_datasheets_bar").DrawResized(new TRectangle.Init(x+13, y+dY+232, widthbarOutcome*200, 10))

		SetAlpha 0.3
		If widthbarMaxTopicality>0.01 Then GetSpriteFromRegistry("gfx_datasheets_bar").DrawResized(new TRectangle.Init(x+115, y+280, widthbarMaxTopicality*100, 10))
		SetAlpha 1.0
		If widthbarTopicality>0.01 Then GetSpriteFromRegistry("gfx_datasheets_bar").DrawResized(new TRectangle.Init(x+115, y+280, widthbarTopicality*100, 10))
	End Method


	Method ShowTrailerSheet:Int(x:Int,y:Int, align:int=0)
		Local normalFont:TBitmapFont	= GetBitmapFontManager().baseFont

		if align = 1 then x :- GetSpriteFromRegistry("gfx_datasheets_specials").area.GetW()
		GetSpriteFromRegistry("gfx_datasheets_specials").Draw(x,y)
		SetColor 0,0,0
		GetBitmapFontManager().basefontBold.drawBlock(GetTitle(), x + 10, y + 11, 278, 20)
		normalFont.drawBlock("Programmvorschau / Trailer", x + 10, y + 34, 278, 20)

		normalFont.drawBlock(getLocale("MOVIE_TRAILER")   , x+10, y+55, 278, 60)
		normalFont.drawBlock(GetLocale("MOVIE_TOPICALITY"), x+222, y+131,  40, 16)
		SetColor 255,255,255

		SetAlpha 0.3
		GetSpriteFromRegistry("gfx_datasheets_bar").DrawResized(new TRectangle.Init(x+13, y+131, 200, 10))
		SetAlpha 1.0
		if data.trailerTopicality > 0.1 then GetSpriteFromRegistry("gfx_datasheets_bar").DrawResized(new TRectangle.Init(x+13, y+131, data.trailerTopicality*200, 10))
	End Method


	'===== AI-LUA HELPER FUNCTIONS =====

	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		Return Self.attractiveness
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method SetAttractiveness(value:Float) {_exposeToLua}
		Self.attractiveness = value
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method GetPricePerBlock:Int() {_exposeToLua}
		'licence is connected to a programme
		if GetData() then return GetPrice() / GetData().GetBlocks()

		'if licence is a collection: ask subs
		local ppB:int = 0
		local ppBcount:int = 0
		For local licence:TProgrammeLicence = eachin subLicences
			ppB:+ licence.GetPricePerBlock()
			ppBcount:+1
		Next
		if ppBcount > 0 then Return ppB/ppBcount
		Return 0
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method GetQualityLevel:Int() {_exposeToLua}
		'licence is connected to a programme
		if GetData()
			Local quality:Int = Self.GetData().GetQuality() * 100
			If quality > 20
				Return 5
			ElseIf quality > 15
				Return 4
			ElseIf quality > 10
				Return 3
			ElseIf quality > 5
				Return 2
			Else
				Return 1
			EndIf
		endif

		'if licence is a collection: ask subs
		local quality:int = 0
		For local licence:TProgrammeLicence = eachin subLicences
			quality :+ licence.GetQualityLevel()
		Next

		if subLicences.length > 0 then return quality / subLicences.length
		return 1
	End Method
	'===== END AI-LUA HELPER FUNCTIONS =====
End Type
