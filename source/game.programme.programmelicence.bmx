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
Import "game.broadcast.audience.bmx"
Import "game.broadcast.broadcaststatistic.bmx"
Import "basefunctions.bmx" 'CreateEmptyImage()


Type TProgrammeLicenceCollection
	'holding all programme licences
	Field licences:TList = CreateList()
	'holding only licences of special packages containing multiple
	'movies/series
	Field collections:TList	= CreateList()
	'holding only movie licences
	Field movies:TList = CreateList()
	'holding only series licences
	Field series:TList = CreateList()

	Global _instance:TProgrammeLicenceCollection


	Function GetInstance:TProgrammeLicenceCollection()
		if not _instance then _instance = new TProgrammeLicenceCollection
		return _instance
	End Function


	Method PrintMovies:int()
		print "--------- movies: "+movies.Count()
		For local movie:TProgrammeLicence = Eachin movies
			print movie.GetTitle() + "   | owner="+movie.owner
		Next
		print "---------"
	End Method


	'add a licence
	Method Add:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		if skipDuplicates and licences.contains(licence) then return False

		licences.AddLast(licence)
		return True
	End Method


	'checks if the licences list contains the given licence
	Method Contains:Int(licence:TProgrammeLicence)
		return licences.contains(licence)
	End Method


	'add a licence as movie
	Method AddMovie:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		if skipDuplicates and movies.contains(licence) then return False

		movies.AddLast(licence)
		return True
	End Method


	'checks if the movie list contains the given licence
	Method ContainsMovie:Int(licence:TProgrammeLicence)
		return movies.contains(licence)
	End Method	


	'add a licence as series
	Method AddSeries:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		if skipDuplicates and series.contains(licence) then return False
		
		series.AddLast(licence)
		return True
	End Method


	'checks if the series list contains the given licence
	Method ContainsSeries:Int(licence:TProgrammeLicence)
		return series.contains(licence)
	End Method	


	'add a licence as collection
	Method AddCollection:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		if skipDuplicates and collections.contains(licence) then return False
		
		collections.AddLast(licence)
		return True
	End Method


	'checks if the collection list contains the given licence
	Method ContainsCollection:Int(licence:TProgrammeLicence)
		return collections.contains(licence)
	End Method
	

	'returns the list to use for the given type
	'this is just important for "random" access as we could
	'also just access "progList" in all cases...
	Method _GetList:TList(programmeType:int=0)
		Select programmeType
			case TProgrammeLicence.TYPE_MOVIE
				return movies
			case TProgrammeLicence.TYPE_SERIES
				return series
			case TProgrammeLicence.TYPE_COLLECTION
				return collections
			default
				return licences
		End Select
	End Method


	Global warnedEmptyRandomFromList:int = False
	Method GetRandomFromList:TProgrammeLicence(_list:TList)

		If _list = Null Then Return Null
		If _list.count() > 0
			Local Licence:TProgrammeLicence = TProgrammeLicence(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			If Licence then return Licence
		EndIf
		if not warnedEmptyRandomFromList
			TLogger.log("TProgrammeLicence.GetRandomFromList()", "list is empty (incorrect filter or not enough available licences?)", LOG_DEBUG | LOG_WARNING | LOG_DEV, TRUE)
			warnedEmptyRandomFromList = true
		endif
		Return Null
	End Method


	Method Get:TProgrammeLicence(id:Int, programmeType:int=0)
		local list:TList = _GetList(programmeType)
		local licence:TProgrammeLicence = null

		For Local i:Int = 0 To list.Count() - 1
			Licence = TProgrammeLicence(list.ValueAtIndex(i))
			if Licence and Licence.id = id Then Return Licence
		Next
		Return Null
	End Method


	Method GetRandom:TProgrammeLicence(programmeType:int=0, includeEpisodes:int=FALSE)
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

		Return GetRandomFromList(resultList)
	End Method


	Method GetRandomWithPrice:TProgrammeLicence(MinPrice:int=0, MaxPrice:Int=-1, programmeType:int=0, includeEpisodes:int=FALSE)
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
		Return GetRandomFromList(resultList)
	End Method


	Method GetRandomWithGenre:TProgrammeLicence(genre:Int=0, programmeType:int=0, includeEpisodes:int=FALSE)
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
		Return GetRandomFromList(resultList)
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammeLicenceCollection:TProgrammeLicenceCollection()
	Return TProgrammeLicenceCollection.GetInstance()
End Function




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

	'store stats for each owner
	Field broadcastStatistics:TBroadcastStatistic[]

'	Field cacheTextOverlay:TImage 			{nosave}
'	Field cacheTextOverlayMode:string = ""	{nosave}	'for which mode the text was cached

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

		'we got direct content - so add that licence to the global
		'licence collection

		'unused:
		'a) exception are episodes...they have to get fetched through
		'   the series head
		'if not isEpisode() and not licences.contains(self) then licences.addLast(self)

		'b) store all licences to enable collections of episodes from multiple series/seasons
		GetProgrammeLicenceCollection().Add(self)

		'only "Movies" are stored separately,
		'episodes are listed in a series which gets added during adding
		'of episodes
		if isMovie() then GetProgrammeLicenceCollection().AddMovie(self)

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

		'if the licence has no special type up to now, add licence to
		'global collection
		if licence.isType(TYPE_UNKNOWN)
			GetProgrammeLicenceCollection().Add(self)
		endif

		'a series episode is added to a series licence
		'-> has data and is of correct type (checked at begin of method)
		if licence.isType(TYPE_EPISODE)
			'set the current licence to type "series"
			self.licenceType = TYPE_SERIES

			'add series licence as parent for this episode
			licence.parentLicence = self

			'add series if not done yet (check is done automatically)
			GetProgrammeLicenceCollection().AddSeries(self)
		endif

		'a series is added to a licence (series-heads do not have data) -> gets a collection
		if licence.isType(TYPE_SERIES) then self.licenceType = TYPE_COLLECTION
		'licence is a movie
		if licence.isType(TYPE_MOVIE) then self.licenceType = TYPE_COLLECTION

		'add collections to their list
		if self.isType(TYPE_MOVIE) then GetProgrammeLicenceCollection().AddCollection(self)

		'add to array of sublicences
		subLicences :+ [licence]
		Return TRUE
	End Method


	Method GetBroadcastStatistic:TBroadcastStatistic()
		local useOwner:int = owner
		if owner < 0 then useOwner = 0

		if broadcastStatistics.length <= useOwner then broadcastStatistics = broadcastStatistics[.. useOwner + 1]
		if not broadcastStatistics[useOwner] then broadcastStatistics[useOwner] = new TBroadcastStatistic

		return broadcastStatistics[useOwner]
	End Method


	Method SetBroadcastStatistic:Int(broadcastStatistic:TBroadcastStatistic)
		local useOwner:int = owner
		if owner < 0 then useOwner = 0

		if broadcastStatistics.length <= useOwner then broadcastStatistics = broadcastStatistics[.. useOwner + 1]
		broadcastStatistics[useOwner] = broadcastStatistic
		return True
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
		if self.title = "" then return GetData().GetTitle()
		return self.title
	End Method


	Method GetDescription:string() {_exposeToLua}
		if self.description = "" then return GetData().GetDescription()
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

		'round to next "1000" block
		value = Int(Floor(value / 1000) * 1000)


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
			ShowProgrammeSheet(x, y, align)
		'trailermode
		elseif showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT
			ShowTrailerSheet(x, y, align)
		endif
	End Method


	Method ShowProgrammeSheet:Int(x:Int,y:Int, align:int=0)
		local data:TProgrammeData        = GetData()
		Local fontNormal:TBitmapFont     = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont       = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont   = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)

		Local showPlannedWarning:Int = False
		Local showEarnInfo:Int = False
		
		if owner > 0 'and GetPlayerCollection().Get().figure.inRoom
			'only if planned and in archive
			if self.IsPlanned() ' and GetPlayerCollection().Get().figure.inRoom.name = "archive"
				showPlannedWarning = True
			endif
		endif

		If data.genre = data.GENRE_CALLINSHOW then showEarnInfo = True

'debug
'showPlannedWarning = True
'showEarnInfo = True

		'=== DRAW BACKGROUND ===
		local sprite:TSprite
		local currX:Int = x
		local currY:int = y
		local currTextWidth:int

		'move sheet to left when right-aligned
		if align = 1 then currX = x - GetSpriteFromRegistry("gfx_datasheet_title").area.GetW()


		sprite = GetSpriteFromRegistry("gfx_datasheet_title"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		if isEpisode() or isSeries()
			sprite = GetSpriteFromRegistry("gfx_datasheet_series"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		endif
		sprite = GetSpriteFromRegistry("gfx_datasheet_country"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_splitter"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content2"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTop"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subMovieRatings"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()


		If showEarnInfo
			sprite = GetSpriteFromRegistry("gfx_datasheet_subMessageEarn"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		EndIf

		If showPlannedWarning
			sprite = GetSpriteFromRegistry("gfx_datasheet_subMessageWarning"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		endif


		sprite = GetSpriteFromRegistry("gfx_datasheet_subMovieAttributes"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_bottom"); sprite.Draw(currX, currY)



		'=== DRAW TEXTS / OVERLAYS ====
		currY = y + 8 'so position is within "border"
		currX :+ 7 'inside
		local textColor:TColor = TColor.CreateGrey(25)
		local textLightColor:TColor = TColor.CreateGrey(75)
		local textEarnColor:TColor = TColor.Create(45,80,10)
		local textWarningColor:TColor = TColor.Create(80,45,10)
		
		if isSeries()
			'default is size "12" so resize to 13
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 18
			fontNormal.drawBlock(GetLocale("SERIES_WITH_X_EPISODES").Replace("%EPISODESCOUNT%", GetSubLicenceCount()), currX + 6, currY, 280, 15, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 16
		elseif isEpisode()
			'title of "series"
			'default is size "12" so resize to 13
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(parentLicence.GetTitle(), currX + 6, currY, 280, 16, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 18
			'episode num/max + episode title
			fontNormal.drawBlock((parentLicence.GetSubLicencePosition(self)+1) + "/" + parentLicence.GetSubLicenceCount() + ": " + data.GetTitle(), currX + 6, currY, 280, 16, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 16
		else ' = if isMovie()
			'default is size "12" so resize to 13
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 18, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 18
		endif

		'country + genre
		'country/year + genre   - for non-callin-shows
		local countryYear:String = data.country
		If data.genre <> data.GENRE_CALLINSHOW
			countryYear :+ " " + data.year
		endif
		fontNormal.drawBlock(countryYear, currX + 6, currY, 65, 16, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		fontNormal.drawBlock(data.GetGenreString(), currX + 6 + 67, currY, 215, 16, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 16

		'content description
		currY :+ 3	'description starts with offset
		fontNormal.drawBlock(data.GetDescription(), currX + 6, currY, 280, 64, null ,textColor)
		currY :+ 64 'content
		currY :+ 3	'description ends with offset

		'splitter
		currY :+ 6

		'max width of director/actors - to align their content properly
		currTextWidth = Int(fontSemiBold.getWidth(GetLocale("MOVIE_DIRECTOR")+":"))
		if data.GetActorsString() <> ""
			currTextWidth = Max(currTextWidth, Int(fontSemiBold.getWidth(GetLocale("MOVIE_ACTORS")+":")))
		endif


		currY :+ 3	'subcontent (actors/director) start with offset
		'director
		if data.GetDirectorsString() <> ""
			fontSemiBold.drawBlock(GetLocale("MOVIE_DIRECTOR")+":", currX + 6, currY, 280, 13, null, textColor)
			fontNormal.drawBlock(data.GetDirectorsString(), currX + 6 + 5 + currTextWidth, currY , 280 - 15 - currTextWidth, 15, null, textColor)
		endif
		currY :+ 13

		'actors
		if data.GetActorsString() <> ""
			fontSemiBold.drawBlock(GetLocale("MOVIE_ACTORS")+":", currX + 6 , currY, 280, 26, null, textColor)
			fontNormal.drawBlock(data.GetActorsString(), currX + 6 + 5 + currTextWidth, currY, 280 - 15 - currTextWidth, 30, null, textColor)
		endif
		currY :+ 26
		currY :+ 3 'subcontent end with offset
		currY :+ 1 'end of subcontent area

		'===== DRAW RATINGS / BARS =====
		'captions
		currY :+ 4 'offset of ratings
		fontSemiBold.drawBlock(GetLocale("MOVIE_SPEED"),      currX + 215, currY,      75, 15, null, textLightColor)
		fontSemiBold.drawBlock(GetLocale("MOVIE_CRITIC"),     currX + 215, currY + 16, 75, 15, null, textLightColor)
		fontSemiBold.drawBlock(GetLocale("MOVIE_BOXOFFICE"),  currX + 215, currY + 32, 75, 15, null, textLightColor)
		fontSemiBold.drawBlock(GetLocale("MOVIE_TOPICALITY"), currX + 215, currY + 48, 75, 15, null, textLightColor)

		'===== DRAW BARS =====

		If data.GetSpeed() > 0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1, data.GetSpeed()*200  , 10))
		If data.GetReview() > 0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1 + 16, data.GetReview()*200 , 10))
		If data.GetOutcome() > 0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1 + 32, data.GetOutcome()*200, 10))
		If data.GetMaxTopicality() > 0.01
			SetAlpha GetAlpha()*0.25
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1 + 48, data.GetMaxTopicality()*200, 10))
			SetAlpha GetAlpha()*4.0
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1 + 48, data.GetTopicality()*200, 10))
		EndIf
		currY :+ 65

		
		'=== DRAW SPECIAL MESSAGES ===
		If showEarnInfo
			'convert back cents to euros and round it
			'value is "per 1000" - so multiply with that too
			local revenue:string = TFunctions.DottedValue(int(1000 * data.GetPerViewerRevenue()))+CURRENCYSIGN
			currY :+ 4 'top content padding of that line
			fontSemiBold.drawBlock(getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), currX + 35,  currY, 245, 15, ALIGN_CENTER_CENTER, textEarnColor, 0,1,1.0,True, True)
			currY :+ 15 + 8 'lineheight + bottom content padding
		EndIf

		if showPlannedWarning
			currY :+ 4 'top content padding of that line
			fontSemiBold.drawBlock("Programm im Sendeplan!", currX + 35, currY, 245, 15, ALIGN_CENTER_CENTER, textWarningColor, 0,1,1.0,True, True)
			currY :+ 15 + 8 'lineheight + bottom content padding
		endif

		currY :+ 4 'align to content portion of that line
		'blocks
		fontBold.drawBlock(data.GetBlocks(), currX + 33, currY, 17, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)

		'repetitions
		fontBold.drawBlock(data.GetTimesAired(owner), currX + 84, currY, 22, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)

		'record
		fontBold.drawBlock(TFunctions.convertValue(GetBroadcastStatistic().GetBestAudienceResult(owner, -1).audience.GetSum(),2), currX + 140, currY, 52, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)

		
		'price
rem
	to enable this, code must be restructured (player class)
		local finance:TPlayerFinance
		'only check finances if it is no other player (avoids exposing
		'that information to us)
		if GetPlayerCollection().playerID = owner
			finance = GetPlayerFinanceCollection().Get(owner, -1)
		endif
endrem
		local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(owner, -1)
		if not finance or finance.canAfford(getPrice())
			fontBold.drawBlock(TFunctions.DottedValue(GetPrice()), currX + 227, currY, 55, 15, ALIGN_RIGHT_CENTER, textColor, 0,1,1.0,True, True)
		else
			fontBold.drawBlock(TFunctions.DottedValue(GetPrice()), currX + 227, currY, 55, 15, ALIGN_RIGHT_CENTER, TColor.Create(200,0,0), 0,1,1.0,True, True)
		endif
		currY :+ 15 + 8 'lineheight + bottom content padding

		'=== X-Rated Overlay ===
		If data.IsXRated()
			GetSpriteFromRegistry("gfx_datasheet_xrated").Draw(currX + GetSpriteFromRegistry("gfx_datasheet_title").GetWidth(), y, -1, ALIGN_RIGHT_TOP)
		Endif
	End Method

rem

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
		local data:TProgrammeData        = GetData()
		Local widthbarSpeed:Float        = data.speed / 255.0
		Local widthbarReview:Float       = data.review / 255.0
		Local widthbarOutcome:Float      = data.Outcome/ 255.0
		Local widthbarTopicality:Float   = data.topicality / 255.0
		Local widthbarMaxTopicality:Float= data.GetMaxTopicality() / 255.0
		Local fontNormal:TBitmapFont     = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont       = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont   = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)


		'=== DRAW BACKGROUND ===
		local sprite:TSprite
		local currX:Int = x + 320
		local currY:int = y
		local currTextWidth:int
		sprite = GetSpriteFromRegistry("gfx_datasheet_title"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		if not data.IsMovie()
			sprite = GetSpriteFromRegistry("gfx_datasheet_series"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		endif
		sprite = GetSpriteFromRegistry("gfx_datasheet_country"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_splitter"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content2"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTop"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subMovieRatings"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()

'		If data.genre = data.GENRE_CALLINSHOW
			sprite = GetSpriteFromRegistry("gfx_datasheet_subMessageEarn"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
'		EndIf

		sprite = GetSpriteFromRegistry("gfx_datasheet_subMovieAttributes"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_bottom"); sprite.Draw(currX, currY)



		'=== DRAW TEXTS / OVERLAYS ====
		currY = y + 7 'inside
		currX :+ 7 'inside
		local textColor:TColor = TColor.CreateGrey(25)
		local textLightColor:TColor = TColor.CreateGrey(75)
		local textEarnColor:TColor = TColor.Create(45,80,10)
		
		if data.isMovie()
			'default is size "12"
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY + 4, 278, 16, null, textColor)
			'fontBold.drawBlock(GetTitle(), currX + 6, currY + 4, 278, 16, null, textColor)
		else
			'title
			fontBold.drawBlock(parentLicence.GetTitle(), currX + 6, currY + 4, 278, 16, null, textColor)
			currY :+ 20
			'episode num/max + episode title
			fontNormal.drawBlock((parentLicence.GetSubLicencePosition(self)+1) + "/" + parentLicence.GetSubLicenceCount() + ": " + data.GetTitle(), currX + 6, currY + 11, 278, 12, null, textColor)
		endif
		currY :+ 20

		'country + genre
		'country/year + genre   - for non-callin-shows
		local countryYear:String = data.country
		If data.genre <> data.GENRE_CALLINSHOW
			countryYear :+ " " + data.year
		endif
		fontNormal.drawBlock(countryYear          , currX + 6     , currY + 2, 65, 15, null, textColor)
		fontNormal.drawBlock(data.GetGenreString(), currX + 6 + 67, currY + 2, 215, 15, null, textColor)
		currY :+ 18

		'content description
		fontNormal.drawBlock(data.GetDescription(), currX + 6, currY, 280, 65, null ,textColor)
		currY :+ 67
		currY :+ 5 'splitter
		'director
		currTextWidth = Int(fontSemiBold.getWidth(GetLocale("MOVIE_DIRECTOR")+":"))
		fontSemiBold.drawBlock(GetLocale("MOVIE_DIRECTOR")+":", currX + 6, currY + 4, 280, 15, null, textColor)
		fontNormal.drawBlock(data.GetDirectorsString()      , currX + 6 + 5 + currTextWidth, currY + 4 , 280 - 15 - currTextWidth, 15, null, textColor)
		currY :+ 15

		'actors
		if data.GetActorsString() <> ""
			currTextWidth = Int(fontSemiBold.getWidth(GetLocale("MOVIE_ACTORS")+":"))
			fontSemiBold.drawBlock(GetLocale("MOVIE_ACTORS")+":", currX + 6 , currY + 4, 280, 30, null, textColor)
			fontNormal.drawBlock(data.GetActorsString()       , currX + 6 + 5 + currTextWidth, currY + 4, 280 - 15 - currTextWidth, 30, null, textColor)
		endif
		currY :+ 30
		currY :+ 6 'to rating

		'===== DRAW RATINGS / BARS =====
		'captions
		fontSemiBold.drawBlock(GetLocale("MOVIE_SPEED"),      currX + 215, currY,      75, 15, null, textLightColor)
		fontSemiBold.drawBlock(GetLocale("MOVIE_CRITIC"),     currX + 215, currY + 17, 75, 15, null, textLightColor)
		fontSemiBold.drawBlock(GetLocale("MOVIE_BOXOFFICE"),  currX + 215, currY + 34, 75, 15, null, textLightColor)
		fontSemiBold.drawBlock(GetLocale("MOVIE_TOPICALITY"), currX + 215, currY + 51, 75, 15, null, textLightColor)

		'===== DRAW BARS =====
		If widthbarSpeed   >0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1, widthbarSpeed*200  , 10))
		If widthbarReview  >0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1 + 17, widthbarReview*200 , 10))
		If widthbarOutcome >0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1 + 34, widthbarOutcome*200, 10))
		If widthbarMaxTopicality>0.01
			SetAlpha GetAlpha()*0.25
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1 + 51, widthbarMaxTopicality*100, 10))
			SetAlpha GetAlpha()*4.0
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1 + 51, widthbarTopicality*100, 10))
		EndIf
		
		currY :+ 68




'		If data.genre = data.GENRE_CALLINSHOW
			'convert back cents to euros and round it
			'value is "per 1000" - so multiply with that too
			local revenue:string = int(1000 * data.GetPerViewerRevenue())+" "+CURRENCYSIGN
			fontSemiBold.drawBlock(getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), currX + 35,  currY + 5 , 245, 15, ALIGN_CENTER_TOP, textEarnColor)
			currY :+ 28
'		EndIf

		'blocks
		fontBold.drawBlock(data.GetBlocks(), currX + 30, currY + 3, 20, 15, ALIGN_CENTER_CENTER, textColor)

		'price
		local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(owner, -1)
		if not finance or finance.canAfford(getPrice())
			fontBold.drawBlock(TFunctions.DottedValue(GetPrice()), currX + 225, currY+3, 55, 15, ALIGN_RIGHT_CENTER, textColor)
		else
			fontBold.drawBlock(TFunctions.DottedValue(GetPrice()), currX + 225, currY+3, 55, 15, ALIGN_RIGHT_CENTER, TColor.Create(200,0,0))
		endif

		currY :+ 28


		'=== X-Rated Overlay ===
		'If data.xrated <> 0 Then fontNormal.drawBlock(GetLocale("MOVIE_XRATED") , 240 , dY+34 , 50, 20) 'prints pg-rating



		


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
			fontNormal.drawBlock("(" + (parentLicence.GetSubLicencePosition(self)+1) + "/" + parentLicence.GetSubLicenceCount() + ") " + data.GetTitle(), x + 10, y + 34, 278, 20)  'prints programmedescription on moviesheet

			dy :+ 22
		EndIf

		'===== DRAW STATIC TEXTS =====
		DrawSingleSheetTextOverlay(x, y + dy, asset.area.GetW(), asset.area.GetH() - dy)

		'===== DRAW DYNAMIC TEXTS =====
		SetColor 0,0,0
		fontNormal.drawBlock(GetLocale("MOVIE_TOPICALITY")  , x+84, y+281, 40, 16)
		fontNormal.drawBlock(GetLocale("MOVIE_BLOCKS")+": "+data.GetBlocks(), x+10, y+281, 100, 16)

'		local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(owner, -1)
		if not finance or finance.canAfford(getPrice())
			fontNormal.drawBlock(GetPrice(), x+240, y+281, 120, 20)
		else
			fontNormal.drawBlock(GetPrice(), x+240, y+281, 120, 20, null, TColor.Create(200,0,0))
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
endrem

	Method ShowTrailerSheet:Int(x:Int,y:Int, align:int=0)
		'=== DRAW BACKGROUND ===
		local sprite:TSprite
		local currX:Int = x
		local currY:int = y

		'move sheet to left when right-aligned
		if align = 1 then currX = x - GetSpriteFromRegistry("gfx_datasheet_title").area.GetW()
		
		sprite = GetSpriteFromRegistry("gfx_datasheet_title"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_series"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTop"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTopicalityRating"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_bottom"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()



		'=== DRAW TEXTS / OVERLAYS ====
		currY = y + 8 'so position is within "border"
		currX :+ 7 'inside
		local textColor:TColor = TColor.CreateGrey(25)
		local textLightColor:TColor = TColor.CreateGrey(75)
		Local fontNormal:TBitmapFont = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)

		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 18
		fontNormal.drawBlock(GetLocale("TRAILER"), currX + 6, currY, 280, 15, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 16

		'content description
		currY :+ 3	'description starts with offset
		fontNormal.drawBlock(getLocale("MOVIE_TRAILER"), currX + 6, currY, 280, 64, null ,textColor)
		currY :+ 64 'content
		currY :+ 3	'description ends with offset

		currY :+ 4 'offset of subContent

		'topicality
		fontSemiBold.drawBlock(GetLocale("MOVIE_TOPICALITY"), currX + 215, currY, 75, 15, null, textLightColor)

		if data.trailerTopicality > 0.1
			SetAlpha GetAlpha()*0.25
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1, 200, 10))
			SetAlpha GetAlpha()*4.0
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1, data.trailerTopicality*200, 10))
		endif
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
