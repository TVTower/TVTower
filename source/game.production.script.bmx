SuperStrict
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.util.localization.bmx"
Import "game.gameobject.bmx"
Import "game.player.finance.bmx"
Import "game.player.base.bmx"
Import "game.gameconstants.bmx" 'to access type-constants
Import "basefunctions.bmx" 'dottedValue


Type TScriptCollection Extends TGameObjectCollection
	Global _instance:TScriptCollection


	Function GetInstance:TScriptCollection()
		if not _instance then _instance = new TScriptCollection
		return _instance
	End Function


	Method Initialize:TScriptCollection()
		Super.Initialize()
		return self
	End Method


	Method GetByGUID:TScript(GUID:String)
		Return TScript( Super.GetByGUID(GUID) )
	End Method


	Method GetRandom:TScript()
		Return TScript( Super.GetRandom() )
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetScriptCollection:TScriptCollection()
	Return TScriptCollection.GetInstance()
End Function




Type TScript Extends TNamedGameObject {_exposeToLua="selected"}
	Field title:TLocalizedString
	Field description:TLocalizedString
	Field ownProduction:Int	= false
	Field scriptType:Int = 0
	Field genre:Int = 0
	'News-Genre: Medien/Technik, Politik/Wirtschaft, Showbiz, Sport, Tagesgeschehen ODER flexibel = spezielle News (10)
	Field topic:Int	= 0

	Field outcome:Float	= 0.0
	Field review:Float = 0.0
	Field speed:Float = 0.0
	Field potential:Int	= 0.0

	Field requiredDirectors:Int = 0
	Field requiredHosts:Int = 0
	Field requiredGuests:Int = 0
	Field requiredReporters:Int = 0
	Field requiredStarRoleActorMale:Int	= 0
	Field requiredStarRoleActorFemale:Int = 0
	Field requiredActorMale:Int	= 0
	Field requiredActorFemale:Int = 0
	Field requiredMusicians:Int	= 0

	'0=director, 1=host, 2=actor, 4=musician, 8=intellectual, 16=reporter(, 32=candidate)
	Field allowedGuestTypes:int	= 0

	Field requiredStudioSize:Int = 1
	Field requireAudience:Int = 0
	Field coulisseType1:Int	= -1
	Field coulisseType2:Int	= -1
	Field coulisseType3:Int = -1

	Field targetGroup:Int = -1

	Field price:Int	= 0
	Field blocks:Int = 0
	'flags contains bitwise encoded things like xRated, paid, trash ...
	Field flags:Int = 0

	'scripts of series are parent of episode scripts
	Field parentScriptGUID:string = ""
	Field subScripts:TScript[]


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


	'override
	Method GetTitle:string()
		if title then return title.Get()
		return ""
	End Method


	Method GetDescription:string()
		if description then return description.Get()
		return ""
	End Method


	'override default method to add sublicences
	Method SetOwner:int(owner:int=0)
		self.owner = owner

		'do the same for all children
		For local script:TScript = eachin subScripts
			script.SetOwner(owner)
		Next
		return TRUE
	End Method


	Method GetSubScriptCount:int() {_exposeToLua}
		return subScripts.length
	End Method


	Method GetSubScriptAtIndex:TScript(arrayIndex:int=1) {_exposeToLua}
		if arrayIndex > subScripts.length or arrayIndex < 0 then return null
		return subScripts[arrayIndex]
	End Method


	Method GetParentScript:TScript() {_exposeToLua}
		if not parentScriptGUID then return self
		return GetScriptCollection().GetByGUID(parentScriptGUID)
	End Method


	Method GetSubScriptPosition:int(script:TScript) {_exposeToLua}
		'find my position and add 1
		For local i:int = 0 to GetSubScriptCount() - 1
			if GetSubScriptAtIndex(i) = script then return i
		Next
		return 0
	End Method


	'returns the next script of a scripts parent subscripts
	Method GetNextSubScript:TScript() {_exposeToLua}
		if not parentScriptGUID then return Null

		'find my position and add 1
		local nextArrayIndex:int = GetParentScript().GetSubScriptPosition(self) + 1
		'if we are at the last position, return the first one
		if nextArrayIndex >= GetParentScript().GetSubScriptCount() then nextArrayIndex = 0

		return GetParentScript().GetSubScriptAtIndex(nextArrayIndex)
	End Method


	Method AddSubScript:int(script:TScript)
		'=== ADJUST SCRIPT TYPES ===

		'as each script is individual we easily can set the main script
		'as parent (so subscripts can ask for sibling scripts).
		script.parentScriptGUID = self.GetGUID()

		'add to array of subscripts
		subScripts :+ [script]
		Return TRUE
	End Method


	Method IsLive:int()
		return HasFlag(TVTProgrammeFlag.LIVE)
	End Method
	
	
	Method IsAnimation:Int()
		return HasFlag(TVTProgrammeFlag.ANIMATION)
	End Method
	
	
	Method IsCulture:Int()
		return HasFlag(TVTProgrammeFlag.CULTURE)
	End Method	
		
	
	Method IsCult:Int()
		return HasFlag(TVTProgrammeFlag.CULT)
	End Method
	
	
	Method IsTrash:Int()
		return HasFlag(TVTProgrammeFlag.TRASH)
	End Method
	
	Method IsBMovie:Int()
		return HasFlag(TVTProgrammeFlag.BMOVIE)
	End Method
	
	
	Method IsXRated:int()
		return HasFlag(TVTProgrammeFlag.XRATED)
	End Method


	Method IsPaid:int()
		return HasFlag(TVTProgrammeFlag.PAID)
	End Method
	

	Method GetPrice:Int() {_exposeToLua}
		'single-script
		if GetSubScriptCount() = 0 then return price

		'script for a package or scripts
		Local value:Float
		For local script:TScript = eachin subScripts
			value :+ script.GetPrice()
		Next
		value :* 0.75

		'round to next "1000" block
		value = Int(Floor(value / 1000) * 1000)

		Return value
	End Method


	'returns the genre of a script - if a group, the one used the most
	'often is returned
	Method GetGenre:int() {_exposeToLua}
		if GetSubScriptCount() = 0 then return genre

		local genres:int[]
		local bestGenre:int=0
		For local script:TScript = eachin subScripts
			local genre:int = script.GetGenre()
			if genre > genres.length-1 then genres = genres[..genre+1]
			genres[genre]:+1
		Next
		For local i:int = 0 to genres.length-1
			if genres[i] > bestGenre then bestGenre = i
		Next

		return bestGenre
	End Method


	Method GetGenreString:String(_genre:Int=-1)
		If _genre < 0 Then _genre = self.genre
		'eg. PROGRAMME_GENRE_ACTION
		Return GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetGenreStringID(_genre))
	End Method


	Method Sell:int()
		local finance:TPlayerFinance = GetPlayerFinance(owner,-1)
		if not finance then return False

		finance.SellProgrammeLicence(GetPrice(), self)

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


	Method isSeries:int() {_exposeToLua}
		return (scriptType & TVTProgrammeLicenceType.SERIES)
	End Method


	Method isEpisode:int() {_exposeToLua}
		return (scriptType & TVTProgrammeLicenceType.EPISODE)
	End Method


	Method GetBlocks:int()
		return self.blocks
	End Method




	Method ShowSheet:Int(x:Int,y:Int, align:int=0)
		Local fontNormal:TBitmapFont   = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont     = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)

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
		'country + year + genre
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

		sprite = GetSpriteFromRegistry("gfx_datasheet_subMovieAttributes"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_bottom"); sprite.Draw(currX, currY)



		'=== DRAW TEXTS / OVERLAYS ====
		currY = y + 8 'so position is within "border"
		currX :+ 7 'inside
		local textColor:TColor = TColor.CreateGrey(25)
		local textLightColor:TColor = TColor.CreateGrey(75)
		
		if isSeries()
			'default is size "12" so resize to 13
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 18
			fontNormal.drawBlock(GetLocale("SERIES_WITH_X_EPISODES").Replace("%EPISODESCOUNT%", GetSubScriptCount()), currX + 6, currY, 280, 15, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 16
		elseif isEpisode()
			'title of "series"
			'default is size "12" so resize to 13
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetParentScript().GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 18
			'episode num/max + episode title
			fontNormal.drawBlock((GetParentScript().GetSubScriptPosition(self)+1) + "/" + GetParentScript().GetSubScriptCount() + ": " + GetTitle(), currX + 6, currY, 280, 15, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 16
		else ' = if isMovie()
			'default is size "12" so resize to 13
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 18
		endif

		fontNormal.drawBlock(GetGenreString(), currX + 6 + 67, currY, 215, 16, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 16

		'content description
		currY :+ 3	'description starts with offset
		fontNormal.drawBlock(GetDescription(), currX + 6, currY, 280, 64, null ,textColor)
		currY :+ 64 'content
		currY :+ 3	'description ends with offset

		'splitter
		currY :+ 6

		'max width of director/actors - to align their content properly
		currTextWidth = Int(fontSemiBold.getWidth(GetLocale("MOVIE_DIRECTOR")+":"))
		'if data.GetActorsString() <> ""
		'	currTextWidth = Max(currTextWidth, Int(fontSemiBold.getWidth(GetLocale("MOVIE_ACTORS")+":")))
		'endif


		currY :+ 3	'subcontent (actors/director) start with offset
		'director
		if requiredDirectors > 0
			fontSemiBold.drawBlock(GetLocale("MOVIE_DIRECTOR")+":", currX + 6, currY, 280, 13, null, textColor)
			fontNormal.drawBlock(requiredDirectors, currX + 6 + 5 + currTextWidth, currY , 280 - 15 - currTextWidth, 15, null, textColor)
			currY :+ 13
		endif

		'actors
		if requiredActorMale > 0 or requiredActorFemale > 0
			fontSemiBold.drawBlock(GetLocale("MOVIE_ACTORS")+":", currX + 6 , currY, 280, 26, null, textColor)
			local str:string = ""
			if requiredActorMale > 0 then str :+ requiredActorMale+"x männlich "
			if requiredActorFemale > 0 then str :+ requiredActorFemale+"x weiblich "
			fontNormal.drawBlock(str, currX + 6 + 5 + currTextWidth, currY, 280 - 15 - currTextWidth, 30, null, textColor)
		endif
		if requiredDirectors = 0
			currY :+ 13
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
		fontSemiBold.drawBlock(GetLocale("MOVIE_POTENTIAL"),  currX + 215, currY + 48, 75, 15, null, textLightColor)

		'===== DRAW BARS =====
rem
		If data.GetSpeed() > 0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1, data.GetSpeed()*200  , 10))
		If data.GetReview() > 0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1 + 16, data.GetReview()*200 , 10))
		If data.GetOutcome() > 0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1 + 32, data.GetOutcome()*200, 10))
		If data.GetMaxTopicality() > 0.01
			SetAlpha GetAlpha()*0.25
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1 + 48, data.GetMaxTopicality()*200, 10))
			SetAlpha GetAlpha()*4.0
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1 + 48, data.GetTopicality()*200, 10))
		EndIf
endrem
		currY :+ 65

		currY :+ 4 'align to content portion of that line
		'blocks
		fontBold.drawBlock(GetBlocks(), currX + 33, currY, 17, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)

		
		'price
		local finance:TPlayerFinance
		'only check finances if it is no other player (avoids exposing
		'that information to us)
		if owner <= 0 or GetPlayerBaseCollection().playerID = owner
			finance = GetPlayerFinance(GetPlayerBaseCollection().playerID, -1)
		endif
		local canAfford:int = False
		'possessing player always can
		if GetPlayerBaseCollection().playerID = owner
			canAfford = True
		'if it is another player... just display "can afford"
		elseif owner >= 0
			canAfford = True
		'not our licence but enough money to buy
		elseif finance and finance.canAfford(GetPrice())
			canAfford = True
		endif
		
		if canAfford
			fontBold.drawBlock(TFunctions.DottedValue(GetPrice()), currX + 227, currY, 55, 15, ALIGN_RIGHT_CENTER, textColor, 0,1,1.0,True, True)
		else
			fontBold.drawBlock(TFunctions.DottedValue(GetPrice()), currX + 227, currY, 55, 15, ALIGN_RIGHT_CENTER, TColor.Create(200,0,0), 0,1,1.0,True, True)
		endif
		currY :+ 15 + 8 'lineheight + bottom content padding

		'=== X-Rated Overlay ===
		If IsXRated()
			GetSpriteFromRegistry("gfx_datasheet_xrated").Draw(currX + GetSpriteFromRegistry("gfx_datasheet_title").GetWidth(), y, -1, ALIGN_RIGHT_TOP)
		Endif

rem
		If TVTDebugInfos
			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0

			local w:int = GetSpriteFromRegistry("gfx_datasheet_title").area.GetW() - 20
			local h:int = Max(120, currY-y)
			DrawRect(currX, y, w,h)
		
			SetColor 255,255,255
			SetAlpha oldAlpha

			local textY:int = y + 5
			fontBold.draw("Programm: "+GetTitle(), currX + 5, textY)
			textY :+ 14	
			fontNormal.draw("Letzte Stunde im Plan: "+latestPlannedEndHour, currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Tempo: "+data.GetSpeed(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Kritik: "+data.GetReview(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Kinokasse: "+data.GetOutcome(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Preismodifikator: "+data.GetModifier("price"), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Qualitaet roh: "+data.GetQualityRaw()+"  (ohne Alter, Wdh.)", currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Qualitaet: "+data.GetQuality(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Aktualitaet: "+data.GetTopicality()+" von " + data.GetMaxTopicality(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Bloecke: "+data.GetBlocks(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Ausgestrahlt: "+data.GetTimesAired(owner)+"x Spieler, "+data.GetTimesAired()+"x alle", currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Quotenrekord: "+Long(GetBroadcastStatistic().GetBestAudienceResult(owner, -1).audience.GetSum())+" (Spieler), "+Long(GetBroadcastStatistic().GetBestAudienceResult(-1, -1).audience.GetSum())+" (alle)", currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Preis: "+GetPrice(), currX + 5, textY)
		Endif
endrem
	End Method
End Type