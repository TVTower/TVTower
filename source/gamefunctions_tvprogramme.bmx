Const CURRENCYSIGN:string = Chr(8364) 'eurosign

include "gamefunctions_tvprogramme_advertisements.bmx"
include "gamefunctions_tvprogramme_news.bmx"
include "gamefunctions_tvprogramme_programmes.bmx"
include "gamefunctions_tvprogramme_playerprogrammeplan.bmx"
include "gamefunctions_tvprogramme_playerprogrammecollection.bmx"




'Base type for programmes, advertisements...
Type TBroadcastMaterial	extends TOwnedGameObject {_exposeToLua="selected"}
	Field state:int				= 0		'by default the state is "normal"
	Field materialType:int		= 0		'original material type (may differ to usage!)
	Field usedAsType:int		= 0		'the type this material is used for (programme as adspot -> trailer)
	Field useableAsType:int		= 0		'the type this material can be used for (so we can forbid certain ads as tvshow etc)

	Field programmedHour:int	= -1	'time at which the material is planned to get send
	Field programmedDay:int		= -1

	Field currentBlockBroadcasting:int		{_exposeToLua} '0 = läuft nicht; 1 = 1 Block; 2 = 2 Block; usw.

	'states a program can be in
	const STATE_NORMAL:int		= 0
	const STATE_OK:int			= 1
	const STATE_FAILED:int		= 2
	const STATE_RUNNING:int		= 3
	'types of broadcastmaterial
	Const TYPE_UNKNOWN:int		= 1
	const TYPE_PROGRAMME:int	= 2
	const TYPE_ADVERTISEMENT:int= 4
	const TYPE_NEWS:int			= 8
	const TYPE_NEWSSHOW:int		= 16


	'needed for all extending objects
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction ) Abstract

	'needed for all extending objects
	Method GetQuality:Float()  {_exposeToLua}
		print "GetQuality"
	End Method


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


	Method BeginBroadcasting:int(day:int, hour:int, minute:int)
		self.SetState(self.STATE_RUNNING)
		Self.currentBlockBroadcasting = 1
	End Method


	Method FinishBroadcasting:int(day:int, hour:int, minute:int)
		'print "finished broadcasting of: "+GetTitle()
	End Method


	Method BreakBroadcasting:int(day:int, hour:int, minute:int)
		'print "finished broadcasting a block of: "+GetTitle()
	End Method


	Method ContinueBroadcasting:int(day:int, hour:int, minute:int)
		Self.currentBlockBroadcasting :+ 1
		'print "continue broadcasting the next block of: "+GetTitle()
	End Method


	'returns whether a programme is programmed for that given day
	Method IsProgrammedForDay:int(day:int=-1)
		if day=-1 then day = Game.GetDay()
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




'a person connected to a programme - directors, writers, actors...
Type TProgrammePerson
	field lastName:string	= ""
	field firstName:string	= ""
	field dayOfBirth:string	= "0000-00-00"
	field dayOfDeath:string	= "0000-00-00"
	field job:int			= 0
	field realPerson:int	= FALSE
	field ID:int			= 0

	const JOB_ACTOR:int		= 1
	const JOB_DIRECTOR:int	= 2
	const JOB_WRITER:int	= 4

	Global lastID:int		= 0
	'arrays holding all entries + already filtered (actors, directors, ...)
	'the filtered are lists for easy management, persons is array for fast search access
	Global persons:TProgrammePerson[]
	Global actors:TList		= CreateList()
	Global directors:TList	= CreateList()
	Global writers:TList	= CreateList()


	Method New()
		lastID:+1
		ID = lastID
	End Method


	Function Create:TProgrammePerson(firstName:string, lastName:string, job:int, dayOfBirth:string="", dayOfDeath:string="")
		if dayOfBirth = "" then dayOfBirth = "0000-00-00"
		if dayOfDeath = "" then dayOfDeath = "0000-00-00"

		local person:TProgrammePerson = new TProgrammePerson
		person.firstName	= firstName
		person.lastName		= lastName
		person.dayOfBirth	= dayOfBirth
		person.dayOfDeath	= dayOfDeath
		person.AddJob(job)

		'resize if needed
		if person.ID > persons.length then persons = persons[..persons.length+1]
		'add to array and corresponding list
		persons[person.ID-1] = person

		return person
	End Function


	Function Get:TProgrammePerson(id:int)
		if id > persons.length or id < 0 then return Null

		return persons[id-1]
	End Function


	Function GetByName:TProgrammePerson(firstName:string, lastName:string)
		firstName = firstName.toLower()
		lastName = lastName.toLower()

		For local person:TProgrammePerson = eachin persons
			if person.firstName.toLower() <> firstName then continue
			if person.lastName.toLower() <> lastName then continue
			return person
		Next
		return Null
	End Function


	Method GetFullName:string()
		if self.lastName<>"" then return self.firstName + " " + self.lastName
		return self.firstName
	End Method


	Method AddJob:int(job:int)
		'already done?
		if self.job & job then return FALSE

		'add job
		self.job :| job

		'add to list
		if job & JOB_ACTOR then actors.AddLast(self)
		if job & JOB_DIRECTOR then directors.AddLast(self)
		if job & JOB_WRITER then actors.AddLast(self)
	End Method
End Type





Function LoadDatabase(filename:String)
	local file:String
	local moviescount:Int
	local totalmoviescount:Int
	local seriescount:Int
	local newscount:Int
	local totalnewscount:Int
	local contractscount:Int

	local time:int = Millisecs()
	Local title:String
	Local description:String
	Local actors:String
	Local director:String
	Local land:String
	Local year:Int
	Local Genre:Int
	Local duration:Int
	Local xrated:Int
	Local price:Int
	Local review:Int
	Local speed:Int
	Local Outcome:Int
	Local livehour:Int
	local refreshModifier:float = 1.0
	local wearoffModifier:float = 1.0

	Local daystofinish:Int
	Local spotcount:Int
	Local targetgroup:Int
	Local minimage:Int
	Local minaudience:Int
	Local fixedPrice:Int
	Local profit:Int
	Local penalty:Int

	Local quality:Int


	Local xml:TXmlHelper = TXmlHelper.Create(filename)
	Local nodeParent:TxmlNode
	Local nodeChild:TxmlNode
	Local nodeEpisode:TxmlNode
	Local loadError:String = ""

	local releaseDayCounter:int = 0


	'===== IMPORT ALL MOVIES =====

	'Print "reading movies from database"
	nodeParent = xml.FindRootChild("allmovies")
	for nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
		If nodeChild.getName() <> "movie" then continue

		title       = xml.FindValue(nodeChild,"title", "unknown title")
		description = xml.FindValue(nodeChild,"description", "23")
		actors      = xml.FindValue(nodeChild,"actors", "")
		director    = xml.FindValue(nodeChild,"director", "")
		land        = xml.FindValue(nodeChild,"country", "UNK")
		year 		= xml.FindValueInt(nodeChild,"year", 1900)
		Genre 		= xml.FindValueInt(nodeChild,"genre", 0 )
		duration    = xml.FindValueInt(nodeChild,"blocks", 2)
		xrated 		= xml.FindValueInt(nodeChild,"xrated", 0)
		price 		= xml.FindValueInt(nodeChild,"price", 0)
		review 		= xml.FindValueInt(nodeChild,"critics", 0)
		speed 		= xml.FindValueInt(nodeChild,"speed", 0)
		Outcome 	= xml.FindValueInt(nodeChild,"outcome", 0)
		livehour 	= xml.FindValueInt(nodeChild,"time", 0)
		refreshModifier	= xml.FindValueFloat(nodeChild,"refreshModifier", 1.0)
		wearoffModifier	= xml.FindValueFloat(nodeChild,"wearoffModifier", 1.0)
		If duration < 0 Or duration > 12 Then duration =1

		local movieLicence:TProgrammeLicence = TProgrammeLicence.Create(title, description)
		movieLicence.AddData(TProgrammeData.Create(title,description,actors, director,land, year, releaseDayCounter mod TGame.daysPerYear, livehour, Outcome, review, speed, price, Genre, duration, xrated, refreshModifier, wearoffModifier, TProgrammeData.TYPE_MOVIE))

		releaseDaycounter:+1
		'print "film: "+title+ " " + totalmoviescount
		totalmoviescount :+ 1
	Next


	'===== IMPORT ALL SERIES INCLUDING EPISODES =====

	nodeParent = xml.FindRootChild("allseries")
	For nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
		If nodeChild.getName() <> "serie" then continue

		'load series main data - in case episodes miss data
		title       = xml.FindValue(nodeChild,"title", "unknown title")
		description = xml.FindValue(nodeChild,"description", "")
		actors      = xml.FindValue(nodeChild,"actors", "")
		director    = xml.FindValue(nodeChild,"director", "")
		land        = xml.FindValue(nodeChild,"country", "UNK")
		year 		= xml.FindValueInt(nodeChild,"year", 1900)
		Genre 		= xml.FindValueInt(nodeChild,"genre", 0)
		duration    = xml.FindValueInt(nodeChild,"blocks", 2)
		xrated 		= xml.FindValueInt(nodeChild,"xrated", 0)
		price 		= xml.FindValueInt(nodeChild,"price", -1)
		review 		= xml.FindValueInt(nodeChild,"critics", -1)
		speed 		= xml.FindValueInt(nodeChild,"speed", -1)
		Outcome 	= xml.FindValueInt(nodeChild,"outcome", -1)
		livehour 	= xml.FindValueInt(nodeChild,"time", -1)
		refreshModifier	= xml.FindValueFloat(nodeChild,"refreshModifier", 1.0)
		wearoffModifier	= xml.FindValueFloat(nodeChild,"wearoffModifier", 1.0)
		If duration < 0 Or duration > 12 Then duration =1

		'create a licence for that series - with title and series description
		local seriesLicence:TProgrammeLicence = TProgrammeLicence.Create(title, description)
		'add the "overview"-data of the series
		seriesLicence.AddData(TProgrammeData.Create(title, description, actors, director, land, year, releaseDayCounter mod TGame.daysPerYear, livehour, Outcome, review, speed, price, Genre, duration, xrated, refreshModifier, wearoffModifier, TProgrammeData.TYPE_SERIES))

		releaseDaycounter:+1
		seriescount :+ 1

		'load episodes
		Local EpisodeNum:Int = 0
		For nodeEpisode = EachIn TXmlHelper.GetNodeChildElements(nodeChild)
			If nodeEpisode.getName() = "episode"
				EpisodeNum	= xml.FindValueInt(nodeEpisode,"number", EpisodeNum+1)
				title      	= xml.FindValue(nodeEpisode,"title", title)
				description = xml.FindValue(nodeEpisode,"description", description)
				actors      = xml.FindValue(nodeEpisode,"actors", actors)
				director    = xml.FindValue(nodeEpisode,"director", director)
				land        = xml.FindValue(nodeEpisode,"country", land)
				year 		= xml.FindValueInt(nodeEpisode,"year", year)
				Genre 		= xml.FindValueInt(nodeEpisode,"genre", Genre)
				duration    = xml.FindValueInt(nodeEpisode,"blocks", duration)
				xrated 		= xml.FindValueInt(nodeEpisode,"xrated", xrated)
				price 		= xml.FindValueInt(nodeEpisode,"price", price)
				review 		= xml.FindValueInt(nodeEpisode,"critics", review)
				speed 		= xml.FindValueInt(nodeEpisode,"speed", speed)
				Outcome 	= xml.FindValueInt(nodeEpisode,"outcome", Outcome)
				livehour	= xml.FindValueInt(nodeEpisode,"time", livehour)
				refreshModifier	= xml.FindValueFloat(nodeChild,"refreshModifier", refreshModifier)
				wearoffModifier	= xml.FindValueFloat(nodeChild,"wearoffModifier", wearoffModifier)

				local episodeLicence:TProgrammeLicence = TProgrammeLicence.Create(title, description)
				episodeLicence.AddData(TProgrammeData.Create(title, description, actors, director, land, year, releaseDayCounter mod TGame.daysPerYear, livehour, Outcome, review, speed, price, Genre, duration, xrated, refreshModifier, wearoffModifier, TProgrammeData.TYPE_EPISODE))
				'add that episode to the series licence
				seriesLicence.AddSubLicence(episodeLicence)
			EndIf
		Next
	Next


	'===== IMPORT ALL ADVERTISEMENTS / CONTRACTS =====

	nodeParent = xml.FindRootChild("allads")
	For nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
		If nodeChild.getName() <> "ad" then continue

		title       = xml.FindValue(nodeChild,"title", "unknown title")
		description = xml.FindValue(nodeChild,"description", "")
		targetgroup = xml.FindValueInt(nodeChild,"targetgroup", 0)
		spotcount	= xml.FindValueInt(nodeChild,"repetitions", 1)
		minaudience	= xml.FindValueInt(nodeChild,"minaudience", 0)
		minimage	= xml.FindValueInt(nodeChild,"minimage", 0)
		fixedPrice	= xml.FindValueInt(nodeChild,"fixedprice", 0)
		profit	    = xml.FindValueInt(nodeChild,"profit", 0)
		penalty		= xml.FindValueInt(nodeChild,"penalty", 0)
		daystofinish= xml.FindValueInt(nodeChild,"duration", 1)

		new TAdContractBase.Create(title, description, daystofinish, spotcount, targetgroup, minaudience, minimage, fixedPrice, profit, penalty)
		'print "contract: "+title+ " " + contractscount
		contractscount :+ 1
	Next


	'===== IMPORT ALL NEWS INCLUDING EPISODES =====

	nodeParent		= xml.FindRootChild("allnews")
	For nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
		If nodeChild.getName() <> "news" then continue
		'load series main data
		title       = xml.FindValue(nodeChild,"title", "unknown newstitle")
		description	= xml.FindValue(nodeChild,"description", "")
		genre		= xml.FindValueInt(nodeChild,"genre", 0)
		quality		= xml.FindValueInt(nodeChild,"topicality", 0)
		price		= xml.FindValueInt(nodeChild,"price", 0)
		Local parentNewsEvent:TNewsEvent = TNewsEvent.Create(title, description, Genre, quality, price)

		'load episodes
		Local EpisodeNum:Int = 0
		For nodeEpisode = EachIn TXmlHelper.GetNodeChildElements(nodeChild)
			If nodeEpisode.getName() = "episode"
				EpisodeNum		= xml.FindValueInt(nodeEpisode,"number", EpisodeNum+1)
				title			= xml.FindValue(nodeEpisode,"title", "unknown Newstitle")
				description		= xml.FindValue(nodeEpisode,"description", "")
				genre			= xml.FindValueInt(nodeEpisode,"genre", genre)
				quality			= xml.FindValueInt(nodeEpisode,"topicality", quality)
				price			= xml.FindValueInt(nodeEpisode,"price", price)
				parentNewsEvent.AddEpisode(title,description, Genre, EpisodeNum,quality, price)
				totalnewscount :+1
			EndIf
		Next
		newscount :+ 1
		totalnewscount :+1
	Next

	TDevHelper.log("TDatabase.Load()", "found " + seriescount+ " series, "+totalmoviescount+ " movies, "+ contractscount + " advertisements, " + totalnewscount + " news. loading time: "+(Millisecs()-time)+"ms", LOG_LOADING)
End Function





'base element for list items in the programme planner
Type TGUIProgrammePlanElement extends TGUIGameListItem
	Field broadcastMaterial:TBroadcastMaterial
	Field inList:TGUISlotList
	Field lastList:TGUISlotList
	Field lastListType:int = 0
	Field lastSlot:int = 0
	Field imageBaseName:string = "pp_programmeblock1"

	Global ghostAlpha:float = 0.8

	'for hover effects
	Global hoveredElement:TGUIProgrammePlanElement = null


    Method Create:TGUIProgrammePlanElement(label:string="",x:float=0.0,y:float=0.0,width:int=120,height:int=20)
		Super.Create(label,x,y,width,height)

		return self
	End Method


	Method CreateWithBroadcastMaterial:TGUIProgrammePlanElement(material:TBroadcastMaterial, limitToState:string="")
		Create()
		SetLimitToState(limitToState)
		SetBroadcastMaterial(material)
		return self
	End Method


	Method SetBroadcastMaterial:int(material:TBroadcastMaterial = null)
		'alow simple setter without param
		if not material and broadcastMaterial then material = broadcastMaterial

		broadcastMaterial = material
		if material
			'now we can calculate the item dimensions
			Resize(Assets.GetSprite(GetAssetBaseName()+"1").area.GetW(), Assets.GetSprite(GetAssetBaseName()+"1").area.GetH() * material.getBlocks())

			'set handle (center for dragged objects) to half of a 1-Block
			self.setHandle(TPoint.Create(Assets.GetSprite(GetAssetBaseName()+"1").area.GetW()/2, Assets.GetSprite(GetAssetBaseName()+"1").area.GetH()/2))
		endif
	End Method


	Method GetBlocks:int()
		If isDragged() and not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			return broadcastMaterial.GetBlocks(broadcastMaterial.materialType)
		endif
		if lastListType > 0 then return broadcastMaterial.GetBlocks(lastListType)
		return broadcastMaterial.GetBlocks()
	End Method


	Method GetAssetBaseName:string()
		local viewType:int = 0

		'dragged and not asked during ghost mode drawing
		If isDragged() and not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			viewType = broadcastMaterial.materialType
		'ghost mode
		elseIf isDragged() and hasOption(GUI_OBJECT_DRAWMODE_GHOST) and lastListType > 0
			viewType = lastListType
		else
			viewType = broadcastMaterial.usedAsType
		endif

		if viewType = broadcastMaterial.TYPE_PROGRAMME
			imageBaseName = "pp_programmeblock"
		elseif viewType = self.broadcastMaterial.TYPE_ADVERTISEMENT
			imageBaseName = "pp_adblock"
		else 'default
			imageBaseName = "pp_programmeblock"
		endif

		return imageBaseName
	End Method


	'override default to enable splitted blocks (one left, two right etc.)
	Method containsXY:int(x:float,y:float)
		if isDragged() or broadcastMaterial.GetBlocks() = 1
			return GetScreenRect().containsXY(x,y)
		endif

		For Local i:Int = 1 To GetBlocks()
			local resultRect:TRectangle = null
			if self._parent
				resultRect = self._parent.GetScreenRect()
				'get the intersecting rectangle between parentRect and blockRect
				'the x,y-values are screen coordinates!
				resultRect = resultRect.intersectRect(GetBlockRect(i))
			else
				resultRect = GetBlockRect(i)
			endif
			if resultRect and resultRect.containsXY(x,y) then return TRUE
		Next
		return FALSE
	End Method


	Method GetBlockRect:TRectangle(block:int=1)
		local pos:TPoint = null
		'dragged and not in DrawGhostMode
		If isDragged() and not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			pos = TPoint.Create(GetScreenX(), GetScreenY())
			if block > 1
				pos.MoveXY(0, Assets.GetSprite(GetAssetBaseName()+"1").area.GetH() * (block - 1))
			endif
		else
			local startSlot:int = lastSlot
			local list:TGUISlotList = lastList
			if inList
				list = self.inList
				startSlot = self.inList.GetSlot(self)
			endif

			if list
				pos = list.GetSlotCoord(startSlot + block-1)
				pos.moveXY(list.getScreenX(), list.getScreenY())
			else
				pos = TPoint.Create(self.GetScreenX(),self.GetScreenY())
				pos.MoveXY(0, Assets.GetSprite(GetAssetBaseName()+"1").area.GetH() * (block - 1))
				'print "block: "+block+"  "+pos.GetIntX()+","+pos.GetIntY()
			endif
		endif

		return TRectangle.Create(pos.x,pos.y, self.rect.getW(), Assets.GetSprite(GetAssetBaseName()+"1").area.GetH())
	End Method



	'override default update-method
	Method Update:int()
		super.Update()

		Select broadcastMaterial.state
			case broadcastMaterial.STATE_NORMAL
					setOption(GUI_OBJECT_DRAGABLE, TRUE)
			case broadcastMaterial.STATE_RUNNING
					setOption(GUI_OBJECT_DRAGABLE, FALSE)
			case broadcastMaterial.STATE_OK
					setOption(GUI_OBJECT_DRAGABLE, FALSE)
			case broadcastMaterial.STATE_FAILED
					setOption(GUI_OBJECT_DRAGABLE, FALSE)
		End Select

		'no longer allowed to have this item dragged
		if isDragged() and not hasOption(GUI_OBJECT_DRAGABLE)
			print "RONNY: FORCE DROP"
			dropBackToOrigin()
		endif

		if not broadcastMaterial
			'print "[ERROR] TGUIProgrammePlanElement.Update: broadcastMaterial not set."
			return FALSE
		endif


		'set mouse to "hover"
		if broadcastMaterial.GetOwner() = Game.playerID and mouseover then Game.cursorstate = 1
		'set mouse to "dragged"
		if isDragged() then Game.cursorstate = 2
	End Method


	'draws the background
	Method DrawBlockBackground:int(variant:string="")

		Local titleIsVisible:Int = FALSE
		local drawPos:TPoint = TPoint.Create(GetScreenX(), GetScreenY())
		'if dragged and not in ghost mode
		If isDragged() and not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			if broadcastMaterial.state = broadcastMaterial.STATE_NORMAL Then variant = "_dragged"
		endif

		local blocks:int = GetBlocks()
		For Local i:Int = 1 To blocks
			Local _blockPosition:Int = 1
			If i > 1
				if i < blocks Then _blockPosition = 2
				if i = blocks Then _blockPosition = 3
			endif

			'draw non-dragged OR ghost
			If not isDragged() OR hasOption(GUI_OBJECT_DRAWMODE_GHOST)
				'skip invisible parts
				local startSlot:int = 0
				if self.inList
					startSlot = self.inList.GetSlot(self)
				elseif self.lastList and isDragged()
					startSlot = self.lastSlot
				else
					startSlot = self.lastSlot
				endif
				If startSlot+i-1 < 0 then continue
				if startSlot+i-1 >= 24 then continue
			endif
			drawPos = GetBlockRect(i).position

			Select _blockPosition
				case 1	'top
						'if only 1 block, use special graphics
						If blocks = 1
							Assets.GetSprite(GetAssetBaseName()+"1"+variant).Draw(GetScreenX(), GetScreenY())
						Else
							Assets.GetSprite(GetAssetBaseName()+"2"+variant).DrawClipped(drawPos, TRectangle.Create(0, 0, -1, 30))
						EndIf
						'xrated
						if TProgramme(broadcastMaterial) and TProgramme(broadcastMaterial).data.xrated
							local addPixel:int = 0
							if GetAssetBaseName() = "pp_programmeblock" then addPixel = 1
							Assets.GetSprite("pp_xrated").Draw(GetScreenX() + Assets.GetSprite(GetAssetBaseName()+"1"+variant).GetWidth() +addPixel, GetScreenY(),  -1, TPoint.Create(ALIGN_RIGHT, ALIGN_TOP))
						endif
						titleIsVisible = TRUE
				case 2	'middle
						Assets.GetSprite(GetAssetBaseName()+"2"+variant).DrawClipped(drawPos, TRectangle.Create(0, 30, -1, 15))
						drawPos.MoveXY(0,15)
						Assets.GetSprite(GetAssetBaseName()+"2"+variant).DrawClipped(drawPos, TRectangle.Create(0, 30, -1, 15))
				case 3	'bottom
						Assets.GetSprite(GetAssetBaseName()+"2"+variant).DrawClipped(drawPos, TRectangle.Create(0, 30, -1, 30))
			End Select
		Next
		return titleIsVisible
	End Method


	'draw the programmeblock inclusive text
    'zeichnet den Programmblock inklusive Text
	Method Draw:int()
		if not broadcastMaterial
			SetColor 255,0,0
			DrawRect(GetScreenX(), GetScreenY(), 150,20)
			SetColor 255,255,255
			Assets.fonts.basefontBold.Draw("no broadcastMaterial", GetScreenX()+5, GetScreenY()+3)
			return FALSE
		endif

		'If isDragged() Then state = 0
		Select broadcastMaterial.state
			case broadcastMaterial.STATE_NORMAL
					SetColor 255,255,255
			case broadcastMaterial.STATE_RUNNING
					SetColor 255,230,120
			case broadcastMaterial.STATE_OK
					SetColor 200,255,200
			case broadcastMaterial.STATE_FAILED
					SetColor 250,150,120
		End Select

		'draw the default background

		local titleIsVisible:int = DrawBlockBackground()
		SetColor 255,255,255

		'there is an hovered item
		if hoveredElement
			local oldAlpha:float = GetAlpha()
			'i am the hovered one (but not in ghost mode)
			'we could also check "self.mouseover", this way we could
			'override it without changing the objects "behaviour" (if there is one)
			if self = hoveredElement
				if not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
					SetBlend LightBlend
					SetAlpha 0.30*oldAlpha
					SetColor 120,170,255
					DrawBlockBackground()
					SetAlpha oldAlpha
					SetBlend AlphaBlend
				endif
			'i have the same licence/programme...
			elseif self.broadcastMaterial.GetReferenceID() = hoveredElement.broadcastMaterial.GetReferenceID()
				SetBlend LightBlend
				SetAlpha 0.15*oldAlpha
				'SetColor 150,150,250
				SetColor 120,170,255
				DrawBlockBackground()
				SetColor 250,255,255
				SetAlpha oldAlpha
				SetBlend AlphaBlend
			endif
			SetColor 255,255,255
		endif

		If titleIsVisible
			local useType:int = broadcastMaterial.usedAsType
			if hasOption(GUI_OBJECT_DRAWMODE_GHOST) and lastListType > 0
				useType = lastListType
			endif

			Select useType
				case broadcastMaterial.TYPE_PROGRAMME
					DrawProgrammeBlockText(TRectangle.Create(GetScreenX(), GetScreenY(), Assets.GetSprite(GetAssetBaseName()+"1").area.GetW()-1,-1))
				case broadcastMaterial.TYPE_ADVERTISEMENT
					DrawAdvertisementBlockText(TRectangle.Create(GetScreenX(), GetScreenY(), Assets.GetSprite(GetAssetBaseName()+"2").area.GetW()-4,-1))
			end Select
		endif
	End Method


	Method DrawProgrammeBlockText:int(textArea:TRectangle, titleColor:TColor=null, textColor:TColor=null)
		Local title:String			= broadcastMaterial.GetTitle()
		Local titleAppend:string	= ""
		Local text:string			= ""
		Local text2:string			= ""

		Select broadcastMaterial.materialType
			'we got a programme used as programme
			case broadcastMaterial.TYPE_PROGRAMME
				if TProgramme(broadcastMaterial)
					Local programme:TProgramme	= TProgramme(broadcastMaterial)
					text = programme.data.getGenreString()
					if programme.isSeries()
						'use the genre of the parent
						text = programme.licence.parentLicence.data.getGenreString()
						title = programme.licence.parentLicence.GetTitle()
						'uncomment if you wish episode number in title
						'titleAppend = " (" + programme.GetEpisodeNumber() + "/" + programme.GetEpisodeCount() + ")"
						text:+"-"+GetLocale("SERIES_SINGULAR")
						text2 = "Ep.: " + (programme.GetEpisodeNumber()+1) + "/" + programme.GetEpisodeCount()
					endif
				endif
			'we got an advertisement used as programme (aka Tele-Shopping)
			case broadcastMaterial.TYPE_ADVERTISEMENT
				if TAdvertisement(broadcastMaterial)
					Local advertisement:TAdvertisement = TAdvertisement(broadcastMaterial)
					text = GetLocale("INFOMERCIAL")
				endif
		End Select


		Local maxWidth:Int			= textArea.GetW()
		Local useFont:TGW_BitmapFont	= Assets.GetFont("Default", 11, ITALICFONT)
		If not titleColor Then titleColor = TColor.Create(0,0,0)
		If not textColor Then textColor = TColor.Create(50,50,50)

		'shorten the title to fit into the block
		While Assets.fonts.basefontBold.getWidth(title + titleAppend) > maxWidth And title.length > 4
			title = title[..title.length-3]+".."
		Wend
		'add eg. "(1/10)"
		title = title + titleAppend

		'draw
		Assets.fonts.basefontBold.drawBlock(title, textArea.position.GetIntX() + 5, textArea.position.GetIntY() +2, textArea.GetW() - 5, 18, null, titleColor, 0, True)
		textColor.setRGB()
		useFont.draw(text, textArea.position.GetIntX() + 5, textArea.position.GetIntY() + 17)

		useFont.draw(text2, textArea.position.GetIntX() + 138, textArea.position.GetIntY() + 17)

		SetColor 255,255,255
	End Method


	Method DrawAdvertisementBlockText(textArea:TRectangle, titleColor:TColor=null, textColor:TColor=null)
		Local title:String			= broadcastMaterial.GetTitle()
		Local titleAppend:string	= ""
		Local text:string			= "123"
		Local text2:string			= "" 'right aligned on same spot as text

		Select broadcastMaterial.materialType
			'we got an advertisement used as advertisement
			case broadcastMaterial.TYPE_ADVERTISEMENT
				If TAdvertisement(broadcastMaterial)
					Local advertisement:TAdvertisement = TAdvertisement(broadcastMaterial)
					If advertisement.isState(advertisement.STATE_FAILED)
						text = "------"
					else
						if advertisement.contract.isSuccessful()
							text = "- OK -"
						else
							text = advertisement.GetSpotNumber() + "/" + advertisement.contract.GetSpotCount()
						endif
					EndIf
				EndIf
			'we got an programme used as advertisement (aka programmetrailer)
			case broadcastMaterial.TYPE_PROGRAMME
				if TProgramme(broadcastMaterial)
					Local programme:TProgramme	= TProgramme(broadcastMaterial)
					text = GetLocale("TRAILER")
					'red corner mark should be enough to recognized X-rated
					'removing "FSK18" from text removes the bug that this text
					'does not fit into the rectangle on Windows systems
					'if programme.data.xrated then text = GetLocale("X_RATED")+"-"+text
				endif
		End Select

		'draw
		If not titleColor Then titleColor = TColor.Create(0,0,0)
		If not textColor Then textColor = TColor.Create(50,50,50)

		Assets.GetFont("Default", 10, BOLDFONT).drawBlock(title, textArea.position.GetIntX() + 3, textArea.position.GetIntY() + 2, textArea.GetW(), 18, null, TColor.CreateGrey(0), 0,1,1.0,TRUE)
		textColor.setRGB()
		Assets.GetFont("Default", 10).drawBlock(text, textArea.position.GetIntX() + 3, textArea.position.GetIntY() + 17, TextArea.GetW(), 30)
		Assets.GetFont("Default", 10).drawBlock(text2,textArea.position.GetIntX() + 3, textArea.position.GetIntY() + 17, TextArea.GetW(), 20, TPoint.Create(ALIGN_RIGHT))
		SetColor 255,255,255 'eigentlich alte Farbe wiederherstellen
	End Method


	Method DrawSheet(leftX:int=30, rightX:int=30, width:int=0)
		local sheetY:float 	= 20
		local sheetX:float 	= leftX
		local sheetAlign:int= 0
		if width = 0 then width = App.settings.GetWidth()
		'if mouse on left side of area - align sheet on right side
		if MouseManager.x < width/2
			sheetX = width - rightX
			sheetAlign = 1
		endif

		'by default nothing is shown
		'because we already have hover effects
		rem
			SetColor 0,0,0
			SetAlpha 0.2
			Local x:Float = self.GetScreenX()
			Local tri:Float[]
			if sheetAlign=0
				tri = [sheetX+20,sheetY+25,sheetX+20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
			else
				tri = [sheetX-20,sheetY+25,sheetX-20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
			endif
			DrawPoly(tri)
			SetColor 255,255,255
			SetAlpha 1.0
		endrem
		self.broadcastMaterial.ShowSheet(sheetX,sheetY, sheetAlign)
	End Method
End Type





'list to handle elements in the programmeplan (ads and programmes)
Type TGUIProgrammePlanSlotList extends TGUISlotList
	'sollten nicht gebraucht werden - die "slotpositionen" muessten auch herhalten
	'koennen
	Field zoneLeft:TRectangle		= TRectangle.Create(0, 0, 200, 350)
	Field zoneRight:TRectangle		= TRectangle.Create(300, 0, 200, 350)

	'holding the object representing a programme started a day earlier (eg. 23:00-01:00)
	'this should not get handled by panels but the list itself (only interaction is
	'drag-n-drop handling)
	Field daychangeGuiProgrammePlanElement:TGUIProgrammePlanElement

	Field slotBackground:TGW_Sprite= null
	Field blockDimension:TPoint		= null
	Field acceptTypes:int			= 0
	Field isType:int				= 0
	Global registeredGlobalListeners:int = FALSE

    Method Create:TGUIProgrammePlanSlotList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height,state)

		SetOrientation(GUI_OBJECT_ORIENTATION_VERTICAL)
		self.resize(width,height)
		self.Init("pp_programmeblock1")
		self.SetItemLimit(24)
		self._fixedSlotDimension = TRUE

		self.acceptTypes :| TBroadcastMaterial.TYPE_PROGRAMME
		self.acceptTypes :| TBroadcastMaterial.TYPE_ADVERTISEMENT
		self.isType = TBroadcastMaterial.TYPE_PROGRAMME



		SetAcceptDrop("TGUIProgrammePlanElement")
		SetAutofillSlots(FALSE)

		'===== REGISTER EVENTS =====
		'nobody was against dropping the item - so transform according to the lists type
		EventManager.registerListenerMethod("guiobject.onFinishDrop", self, "onFinishDropProgrammePlanElement", "TGUIProgrammePlanElement", self)
		'nobody was against dragging the item - so transform according to the items base type
		'attention: "drag" does not have a "receiver"-list like a drop has..
		'so we would have to check vs slot-elements here
		'that is why we just use a global listener... for all programmeslotlists (prog and ad)
		if not registeredGlobalListeners
			EventManager.registerListenerFunction("guiobject.onFinishDrag", onFinishDragProgrammePlanElement, "TGUIProgrammePlanElement")
			registeredGlobalListeners = TRUE
		endif
		return self
	End Method


	Method Init:int(spriteName:string="", displaceX:int = 0)
		self.zoneLeft.dimension.SetXY(Assets.GetSprite(spriteName).area.GetW(), 12 * Assets.GetSprite(spriteName).area.GetH())
		self.zoneRight.dimension.SetXY(Assets.GetSprite(spriteName).area.GetW(), 12 * Assets.GetSprite(spriteName).area.GetH())

		self.slotBackground = Assets.GetSprite(spriteName)

		self.blockDimension = TPoint.Create(slotBackground.area.GetW(), slotBackground.area.GetH())
		SetSlotMinDimension(blockDimension.GetIntX(), blockDimension.GetIntY())

		self.SetEntryDisplacement(slotBackground.area.GetW() + displaceX , -12 * slotBackground.area.GetH(), 12) '12 is stepping
	End Method


	'override to remove daychange-object too
	Method EmptyList:int()
		Super.EmptyList()
		if dayChangeGuiProgrammePlanElement
			dayChangeGuiProgrammePlanElement.remove()
			dayChangeGuiProgrammePlanElement = null
		endif
	End Method


	'handle successful drops of broadcastmaterial on the list
	Method onFinishDropProgrammePlanElement:int(triggerEvent:TEventBase)
		'resize that item to conform to the list
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		item.lastListType = isType
		'resizes item according to usage type
		item.broadcastMaterial.setUsedAsType(isType)

		item.SetBroadcastMaterial()

		return TRUE
	End Method


	'handle successful drags of broadcastmaterial
	Function onFinishDragProgrammePlanElement:int(triggerEvent:TEventBase)
		'resize that item to conform to the list
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		'resizes item according to usage type
		item.broadcastMaterial.setUsedAsType(item.broadcastMaterial.materialType)
		item.SetBroadcastMaterial()

		return TRUE
	End Function


	'override default behaviour for zones
	Method SetEntryDisplacement(x:float=0.0, y:float=0.0, stepping:int=1)
		super.SetEntryDisplacement(x,y,stepping)

		'move right zone according to setup
		zoneRight.position.SetX(x)
	End Method


	Method SetDayChangeBroadcastMaterial:int(material:TBroadcastMaterial, day:int=-1)
		local guiElement:TGUIProgrammePlanElement = dayChangeGuiProgrammePlanElement
		if guiElement
			'clear out old gui element
			guiElement.remove()
		else
			guiElement = new TGUIProgrammePlanElement.Create()
		endif
		'assign programme
		guiElement.SetBroadcastMaterial(material)

		'move the element to the correct position
		'1. find out when it was send:
		'   just ask the plan when the programme at "0:00" really started
		local startHour:int = 0
		local player:TPlayer = Game.GetPlayer(material.owner)
		if player
			if day < 0 then day = Game.GetDay()
			startHour = player.ProgrammePlan.GetObjectStartHour(material.materialType,day,0)
			'get a 0-23 value
			startHour = startHour mod 24
		else
			print "[ERROR] No player found for ~qprogramme~q in SetDayChangeBroadcastMaterial"
			startHour = 23 'nur als beispiel, spaeter entfernen
'			return FALSE
		endif

		'2. set the position of that element so that the "todays blocks" are starting at
		'   0:00
		local firstSlotCoord:TPoint = GetSlotOrCoord(0)
		local blocksRunYesterday:int = 24 - startHour
		guiElement.lastSlot = - blocksRunYesterday
		guiElement.rect.position.setPos(firstSlotCoord)
		'move above 0:00 (gets hidden automatically)
		guiElement.rect.position.moveXY(0, -1 * blocksRunYesterday * blockDimension.GetIntY() )

		dayChangeGuiProgrammePlanElement = guiElement


		'assign parent
		guiEntriesPanel.addChild(dayChangeGuiProgrammePlanElement)

		return TRUE
	End Method


	'override default "default accept behaviour" of onDrop
	Method onDrop:int(triggerEvent:TEventBase)
		local dropCoord:TPoint = TPoint(triggerEvent.GetData().get("coord"))
		if not dropCoord then return FALSE

		if self.containsXY(dropCoord.x, dropCoord.y)
			triggerEvent.setAccepted(true)
			'print "TGUIProgrammePlanSlotList.onDrop: coord="+dropCoord.getIntX()+","+dropCoord.getIntY()
			return TRUE
		else
			return FALSE
		endif
	End Method


	Method ContainsBroadcastMaterial:int(material:TBroadcastMaterial)
		'check special programme from yesterday
		if self.dayChangeGuiProgrammePlanElement
			if self.daychangeGuiProgrammePlanElement.broadcastMaterial = material then return TRUE
		endif

		for local i:int = 0 to self.GetSlotAmount()-1
			local block:TGUIProgrammePlanElement = TGUIProgrammePlanElement(self.GetItemBySlot(i))
			if not block then continue
			if block.broadcastMaterial = material then return TRUE
		Next
		return FALSE
	End Method


	'override default to also recognize slots occupied by prior ones
	Method GetItemBySlot:TGUIobject(slot:int)
		if slot < 0 or slot > _slots.length-1 then return Null

		'if no item is at the given slot, check prior ones
		if _slots[slot] = null
			'check regular slots
			local parentSlot:int = slot-1
			while parentSlot > 0
				if _slots[parentSlot]
					'only return if the prior one is running long enough
					' - else it also returns programmes with empty slots between
					local blocks:int = TGUIProgrammePlanElement(_slots[parentSlot]).broadcastMaterial.getBlocks(isType)
					if blocks > (slot - parentSlot) then return _slots[parentslot]
				endif
				parentSlot:-1
			wend
			'no item found in regular slots but already are at start
			'-> check special programme from yesterday (if existing it is the searched one)
			if daychangeGuiProgrammePlanElement
				local blocks:int = daychangeGuiProgrammePlanElement.broadcastMaterial.getBlocks(isType)
				'lastSlot is a negative value from 0
				'-> -3 means 3 blocks already run yesterday
				local blocksToday:int = blocks + dayChangeGuiProgrammePlanElement.lastSlot
				if blocksToday > slot then return daychangeGuiProgrammePlanElement
			endif

			return null
		endif

		return _slots[slot]
	End Method


	'overridden method to check slots after the block-slot for occupation too
	Method SetItemToSlot:int(item:TGUIobject,slot:int)
		local itemSlot:int = self.GetSlot(item)
		'somehow we try to place an item at the place where the item
		'already resides
		if itemSlot = slot then return TRUE

		local guiElement:TGUIProgrammePlanElement = TGUIProgrammePlanElement(item)
		if not guiElement then return FALSE

		'is there another item?
		local slotStart:int = slot
		local slotEnd:int = slot + guiElement.broadcastMaterial.getBlocks(isType)-1

		'to check previous ones we try to find a previous one
		'then we check if it reaches "our" slot or ends earlier
		local previousItemSlot:int = GetPreviousUsedSlot(slot)
		if previousItemSlot > -1
			local previousGuiElement:TGUIProgrammePlanElement = TGUIProgrammePlanElement(getItemBySlot(previousItemSlot))
			if previousGuiElement and previousItemSlot + previousGuiElement.GetBlocks()-1 >= slotStart
				slotStart = previousItemSlot
			endif
		endif

		for local i:int = slotStart to slotEnd
			local dragItem:TGUIProgrammePlanElement = TGUIProgrammePlanElement(getItemBySlot(i))

			'only drag an item once
			if dragItem 'and not dragItem.isDragged()
				'do not allow if the underlying item cannot get dragged
				if not dragItem.isDragable() then return FALSE

				'ask others if they want to intercept that exchange
				local event:TEventSimple = TEventSimple.Create( "guiSlotList.onBeginReplaceSlotItem", new TData.Add("source", item).Add("target", dragItem).AddNumber("slot",slot), self)
				EventManager.triggerEvent(event)

				if not event.isVeto()
					'remove the other one from the panel
					if dragItem._parent then dragItem._parent.RemoveChild(dragItem)

					'drag the other one
					dragItem.drag()
					'unset the occupied slot
					_SetSlot(i, null)

					EventManager.triggerEvent(TEventSimple.Create( "guiSlotList.onReplaceSlotItem", new TData.Add("source", item).Add("target", dragItem).AddNumber("slot",slot) , self))
				endif
				'skip slots occupied by this item
				i:+ (dragItem.broadcastMaterial.GetBlocks(isType)-1)
			endif
		Next

		'if the item is already on the list, remove it from the former slot
		_SetSlot(itemSlot, null)

		'set the item to the new slot
		_SetSlot(slot, item)

		 'panel manages it now | RON 03.01.14
		guiEntriesPanel.addChild(item)

		RecalculateElements()

		return TRUE
	End Method


	'overriden Method: so it does not accept a certain
	'kind of programme (movies - series)
	'plus it drags items in other occupied slots
	Method AddItem:int(item:TGUIobject, extra:object=null)
		local guiElement:TGUIProgrammePlanElement = TGUIProgrammePlanElement(item)
		if not guiElement then return FALSE

		'something odd happened - no material
		if not guiElement.broadcastMaterial then return FALSE
		'list does not accept type? stop adding the item.
		if not(acceptTypes & guiElement.broadcastMaterial.usedAsType) then return FALSE
		'item is not allowed to drop there ? stop adding the item.
		if not(acceptTypes & guiElement.broadcastMaterial.useableAsType) then return FALSE

		local addToSlot:int = -1
		local extraIsRawSlot:int = FALSE
		if string(extra)<>"" then addToSlot= int( string(extra) );extraIsRawSlot=TRUE

		'search for first free slot
		if _autofillSlots then addToSlot = self.getFreeSlot()
		'auto slot requested
		if extraIsRawSlot and addToSlot = -1 then addToSlot = getFreeSlot()

		'no free slot or none given? find out on which slot we are dropping
		'if possible, drag the other one and drop the new
		if addToSlot < 0
			local data:TData = TData(extra)
			if not data then return FALSE

			local dropCoord:TPoint = TPoint(data.get("coord"))
			if not dropCoord then return FALSE

			'set slot to land
			addToSlot = GetSlotByCoord(dropCoord)
			'no slot was hit
			if addToSlot < 0 then return FALSE
		endif

		'ask if an add to this slot is ok
		local event:TEventSimple =  TEventSimple.Create("guiList.TryAddItem", new TData.Add("item", item).AddNumber("slot",addToSlot) , self)
		EventManager.triggerEvent(event)
		if event.isVeto() then return FALSE

		'check underlying slots
		for local i:int = 0 to guiElement.broadcastMaterial.getBlocks(isType)-1
			'return if there is an underlying item which cannot get dragged
			local dragItem:TGUIProgrammePlanElement = TGUIProgrammePlanElement(getItemBySlot(addToSlot + i))
			if not dragItem then continue

			'check if the programme can be dragged
			'this should not be the case if the programme already run
			if not dragItem.isDragable() then print "NOT DRAGABLE UNDERLAYING";return FALSE
		Next


		'set self as the list the items is belonging to
		'this also drags underlying items if possible
		if SetItemToSlot(guiElement, addToSlot)
			guiElement.lastList = guiElement.inList
			guiElement.inList = self
			if not guiElement.lastList
				guiElement.lastList = self
				guiElement.lastListType = isType
			endif

			return TRUE
		endif
	End Method


	'override RemoveItem-Handler to include inList-property (and type check)
	Method RemoveItem:int(item:TGUIobject)
		local guiElement:TGUIProgrammePlanElement = TGUIProgrammePlanElement(item)
		if not guiElement then return FALSE

		if super.RemoveItem(guiElement)
			guiElement.lastList = guiElement.inList
			'inList is only set for manual drags
			'while a replacement-drag has no inList (and no last Slot)
			if guiElement.inList
				guiElement.lastSlot = guiElement.inList.GetSlot(self)
			else
				guiElement.lastSlot = -1
			endif

			guiElement.inList = null
			return TRUE
		else
			return FALSE
		endif
	End Method


	'override default "rectangle"-check to include splitted panels
	Method containsXY:int(x:float,y:float)
		'convert to local coord
		x :-GetScreenX()
		y :-GetScreenY()

		if zoneLeft.containsXY(x,y) or zoneRight.containsXY(x,y)
			return TRUE
		else
			return FALSE
		endif
	End Method


	Method Update:int()
		if dayChangeGuiProgrammePlanElement then dayChangeGuiProgrammePlanElement.Update()

		super.Update()
	End Method


	Method Draw:int()
		local atPoint:TPoint = GetScreenPos()
		local pos:TPoint = null
		For local i:int = 0 to _slotsState.length-1
			'skip occupied slots
			if _slots[i]
				if TGUIProgrammePlanElement(_slots[i])
					i :+ TGUIProgrammePlanElement(_slots[i]).GetBlocks()-1
					continue
				endif
			endif

			if _slotsState[i] = 0 then continue

			pos = GetSlotOrCoord(i)
			'disabled
			if _slotsState[i] = 1 then SetColor 100,100,100
			'occupied
			if _slotsState[i] = 2 then SetColor 250,150,120

			SetAlpha 0.35
			SlotBackground.Draw(atPoint.GetX()+pos.getX(), atPoint.GetY()+pos.getY())
			SetAlpha 1.0
			SetColor 255,255,255
		Next

		if dayChangeGuiProgrammePlanElement then dayChangeGuiProgrammePlanElement.draw()

		'draw ghosts...
		if not Game.DebugInfos then DrawChildren()
	End Method
End Type




Type TPlannerList
	Field openState:int		= 0		'0=enabled 1=openedgenres 2=openedmovies 3=openedepisodes = 1
	Field currentGenre:Int	=-1
	Field enabled:Int		= 0
	Field Pos:TPoint 		= TPoint.Create()
	Field gfxTape:TGW_Sprite
	Field gfxTapeBackground:TGW_Sprite
	Field tapeRect:TRectangle
	Field displaceTapes:TPoint = TPoint.Create(9,8)


	Method Init:int(x:float, y:float)
		tapeRect	= TRectangle.Create(x, y, gfxTapeBackground.area.GetW(), gfxTapeBackground.area.GetH() )
		return TRUE
	End Method


	Method getOpen:Int()
		return self.openState
	End Method
End Type




'the programmelist shown in the programmeplaner
Type TgfxProgrammelist extends TPlannerList
	Field displaceEpisodeTapes:TPoint = TPoint.Create(6,5)
	Field gfxTapeSeries:TGW_Sprite
	Field gfxTapeEpisodes:TGW_Sprite
	Field gfxTapeEpisodesBackground:TGW_Sprite
	Field genreRect:TRectangle
	Field tapeEpisodesRect:TRectangle
	Field maxGenres:int = 1
	Field hoveredSeries:TProgrammeLicence = Null
	Field hoveredLicence:TProgrammeLicence = Null
	const MODE_PROGRAMMEPLANNER:int=0	'creates a GuiProgrammePlanElement
	const MODE_ARCHIVE:int=1			'creates a GuiProgrammeLicence


	Method Create:TgfxProgrammelist(x:Int, y:Int, maxGenres:int)
		self.maxGenres				= maxGenres
		gfxTape						= Assets.getSprite("pp_cassettes_movies")
		gfxTapeBackground			= Assets.getSprite("pp_tapeBackground")
		gfxTapeSeries				= Assets.getSprite("pp_cassettes_series")
		gfxTapeEpisodes				= Assets.getSprite("pp_cassettes_episodes")
		gfxTapeEpisodesBackground	= Assets.getSprite("pp_tapeEpisodesBackground")

		'right align the list
		Pos.SetXY(x - Assets.getSprite("genres_top").area.GetW(), y)

		local genreWidth:int = Assets.getSprite("genres_top").area.GetW()
		local genreHeight:int = 0
		genreHeight:+ Assets.getSprite("genres_top").area.GetH()
		genreHeight:+ Assets.getSprite("genres_entry"+1).area.GetH()
		genreHeight:+ Assets.getSprite("genres_bottom").area.GetH()

		genreRect		= TRectangle.Create(Pos.GetX(), Pos.GetY(), genreWidth, genreHeight)

		'init tapeRect - and right align it
		self.Init(genreRect.GetX() - gfxTapeBackground.area.GetW() + 10, genreRect.GetY())

		tapeEpisodesRect= TRectangle.Create(..
								genreRect.GetX() - gfxTapeEpisodesBackground.area.GetW() + 8,..
								tapeRect.GetY() + tapeRect.GetH() + 5, ..
								gfxTapeEpisodesBackground.area.GetW(), gfxTapeEpisodesBackground.area.GetH()..
						  )

		Return self
	End Method


	Method Draw:Int()
		if not enabled then return FALSE

		'draw episodes background
		If self.openState >=3
			if currentGenre >= 0 then DrawEpisodeTapes(hoveredSeries)
		endif
		'draw tapes of current genre + episodes of a selected series
		If self.openState >=2 and currentGenre >= 0
			DrawTapes(currentgenre)
		EndIf

		'draw genre selector
		If self.openState >=1
			local currY:float = Pos.y
			local oldAlpha:float = GetAlpha()
			Assets.getSprite("genres_top").draw(Pos.x,currY)
			currY:+Assets.getSprite("genres_top").area.GetH()

			For local genres:int = 0 To self.maxGenres-1 		'21 genres
				local lineHeight:int =0
				local entryNum:string = (genres mod 2)
				if genres = 0 then entryNum = "First"

				'draw background
				Assets.getSprite("genres_entry"+entryNum).draw(Pos.x,currY)
				'draw select effect
				if genres = currentgenre
					SetBlend LightBlend
					SetAlpha 0.2*oldAlpha
					SetColor 120,170,255
					Assets.getSprite("genres_entry"+entryNum).draw(Pos.x,currY)
					SetColor 255,255,255
					SetAlpha oldAlpha
					SetBlend AlphaBlend
				endif
				'draw hover effect if hovering
				if TFunctions.MouseIn(Pos.x, currY, Assets.getSprite("genres_entry"+entryNum).area.GetW(), Assets.getSprite("genres_entry"+entryNum).area.GetH())
					SetBlend LightBlend
					SetAlpha 0.2*oldAlpha
					Assets.getSprite("genres_entry"+entryNum).draw(Pos.x,currY)
					SetAlpha oldAlpha
					SetBlend AlphaBlend
				endif

				lineHeight = Assets.getSprite("genres_entry"+entryNum).area.GetH()

				'evtl cachen?
				Local genrecount:Int = Game.getPlayer().ProgrammeCollection.GetProgrammeGenreCount(genres)

				If genrecount > 0
					Assets.fonts.baseFont.drawBlock(GetLocale("MOVIE_GENRE_" + genres) + " (" +genreCount+ ")", Pos.x + 4, Pos.y + lineHeight*genres +5, 114, 16, null, TColor.clBlack)
					SetAlpha 0.6; SetColor 0, 255, 0
					'takes 20% of fps...
					For Local i:Int = 0 To genrecount -1
						DrawLine(Pos.x + 121 + i * 2, Pos.y + 4 + lineHeight*genres - 1, Pos.x + 121 + i * 2, Pos.y + 17 + lineHeight*genres - 1)
					Next
				else
					SetAlpha 0.3
					Assets.fonts.baseFont.drawBlock(GetLocale("MOVIE_GENRE_" + genres), Pos.x + 4, Pos.y + lineHeight*genres +5, 114, 16, null, TColor.clBlack)
				EndIf
				SetAlpha 1.0
				SetColor 255, 255, 255
				currY:+ lineHeight
			Next
			Assets.getSprite("genres_bottom").draw(Pos.x,currY)
		EndIf
	End Method


	Method DrawTapes:Int(genre:Int=-1)
		local font:TGW_BitmapFont 	= Assets.getFont("Default", 10)
		local box:TRectangle	= TRectangle.Create(tapeRect.GetX(), tapeRect.GetY(), gfxTape.area.GetW(), gfxTape.area.GetH() )
		local asset:TGW_Sprite = null

		gfxTapeBackground.Draw(tapeRect.GetX(), tapeRect.GetY())

		if genre < 0 then return FALSE

		'displace all tapes - border of background
		box.MoveXY(displaceTapes.GetIntX(),displaceTapes.GetIntY())

		'first
		For Local licence:TProgrammeLicence = EachIn Game.getPlayer().ProgrammeCollection.programmeLicences
			'skip wrong genre
			If licence.GetGenre() <> genre then continue
			'choose correct asset
			If licence.isMovie() then asset = gfxtape else asset = gfxtapeseries

			'if planned - set to "running color"
			if licence.isPlanned() then SetColor 255,230,120
			'draw tape
			asset.Draw(box.GetX(), box.GetY())
			SetColor 255,255,255

			font.drawBlock(licence.GetTitle(), box.position.GetIntX() + 13, box.position.GetIntY() + 3, 139,16,null, TColor.clBlack ,0,True)

			'we are hovering a licence...
			If box.containsXY(MouseManager.x,MouseManager.y)
				SetBlend LightBlend
				SetAlpha 0.2
				asset.Draw(box.GetX(), box.GetY())
				SetAlpha 1.0
				SetBlend AlphaBlend
			endif
			box.MoveXY(0, 19)
		Next
	End Method


	Method UpdateTapes:Int(genre:Int=-1, mode:int=0)
		local box:TRectangle = TRectangle.Create(tapeRect.GetX(), tapeRect.GetY(), gfxTape.area.GetW(), gfxTape.area.GetH() )

		If genre < 0 then return FALSE

		box.MoveXY(displaceTapes.GetIntX(),displaceTapes.GetIntY())

		'we clicked somewhere - if a series was below, that variable
		'gets refilled automagically -> no need to keep it filled
'		If MOUSEMANAGER.IsClicked(1)
'			hoveredSeries = null
'		endif

		For Local licence:TProgrammeLicence = EachIn Game.getPlayer().ProgrammeCollection.programmeLicences
			'skip wrong genre
			If licence.GetGenre() <> genre then continue

			If box.containsXY(MouseManager.x,MouseManager.y)
				local doneSomething:int = FALSE
				'store for sheet-display
				hoveredLicence = licence

				If MOUSEMANAGER.IsClicked(1)
					if mode = MODE_PROGRAMMEPLANNER
						If licence.isMovie()
							'create and drag new block
							new TGUIProgrammePlanElement.CreateWithBroadcastMaterial( new TProgramme.Create(licence), "programmePlanner" ).drag()

							SetOpen(0)
							doneSomething = true
						Else
							'set the hoveredSeries so the episodes-list is drawn
							hoveredSeries = licence

							SetOpen(3)
							doneSomething = true
						EndIf
					elseif mode = MODE_ARCHIVE
						'create a dragged block
						new TGUIProgrammeLicence.CreateWithLicence(licence).drag()

						SetOpen(0)
						doneSomething = true
					endif

					'something changed, so stop looping through rest
					if doneSomething
						MOUSEMANAGER.resetKey(1)
						return TRUE
					endif
				endif
			EndIf

			box.MoveXY(0, 19)
		Next
		return FALSE
	End Method


	Method DrawEpisodeTapes:Int(seriesLicence:TProgrammeLicence)
		if not seriesLicence then return FALSE

		'draw background
		gfxTapeEpisodesBackground.Draw(tapeEpisodesRect.GetX(), tapeEpisodesRect.GetY())

		local hoveredLicence:TProgrammeLicence = null
		local box:TRectangle = TRectangle.Create(tapeEpisodesRect.GetX(), tapeEpisodesRect.GetY(), gfxTapeEpisodes.area.GetW(), gfxTapeEpisodes.area.GetH() )
		local font:TGW_BitmapFont = Assets.getFont("Default", 8)
		'displace all tapes - border of background
		box.MoveXY(displaceEpisodeTapes.GetIntX(),displaceEpisodeTapes.GetIntY())

		For Local i:Int = 0 To seriesLicence.GetSubLicenceCount()-1
			Local licence:TProgrammeLicence = TProgrammeLicence(seriesLicence.GetsubLicenceAtIndex(i))
			If not licence then continue

			'if planned - set to "running color"
			if licence.isPlanned() then SetColor 255,230,120
			'draw tape
			gfxTapeEpisodes.Draw(box.GetX(), box.GetY())
			SetColor 255,255,255

			font.drawBlock("(" + (i+1) + "/" + seriesLicence.GetSubLicenceCount() + ") " + licence.GetTitle(), box.position.GetIntX() + 10, box.position.GetIntY() + 1, 85,12, null, TColor.clBlack,0,True)

			If box.containsXY(MouseManager.x,MouseManager.y)
				SetBlend LightBlend
				SetAlpha 0.2
				gfxTapeEpisodes.Draw(box.GetX(), box.GetY())
				SetAlpha 1.0
				SetBlend AlphaBlend
			EndIf

			box.MoveXY(0, 12)
		Next

	End Method


	Method UpdateEpisodeTapes:Int(seriesLicence:TProgrammeLicence)
		Local tapecount:Int = 0
		local box:TRectangle = TRectangle.Create(tapeEpisodesRect.GetX(), tapeEpisodesRect.GetY(), gfxTapeEpisodes.area.GetW(), gfxTapeEpisodes.area.GetH() )
		'displace all tapes - border of background
		box.MoveXY(displaceEpisodeTapes.GetIntX(),displaceEpisodeTapes.GetIntY())

		For Local i:Int = 0 To seriesLicence.GetSubLicenceCount()-1
			Local licence:TProgrammeLicence = TProgrammeLicence(seriesLicence.GetsubLicenceAtIndex(i))
			If not licence then continue

			'store for sheet-display
			hoveredLicence = licence

			tapecount :+ 1
			If box.containsXY(MouseManager.x,MouseManager.y)
				If MOUSEMANAGER.IsClicked(1)
					'create and drag new block
					new TGUIProgrammePlanElement.CreateWithBroadcastMaterial( new TProgramme.Create(licence) ).drag()

					SetOpen(0)
					MOUSEMANAGER.resetKey(1)
					return TRUE
				endif
			EndIf

			box.MoveXY(0, 12)
		Next
		return FALSE
	End Method


	Method Update:int(mode:int=0)
		'gets repopulated automagically if hovered
		hoveredLicence = null

		'if not "open", do nothing (including checking right clicks)
		If not enabled then return FALSE

		'clicking on the genre selector -> select Genre
		If MOUSEMANAGER.IsClicked(1) AND TFunctions.MouseIn(Pos.x,Pos.y, Assets.getSprite("genres_entry0").area.GetW(), Assets.getSprite("genres_entry0").area.GetH()*self.MaxGenres)
			SetOpen(2)
			currentgenre = Floor((MouseManager.y - Pos.y - 1) / Assets.getSprite("genres_entry0").area.GetH())
		EndIf

		'if the genre is selected, also take care of its programmes
		If self.openState >=2
			If currentgenre >= 0 Then UpdateTapes(currentgenre, mode)
			'series episodes are only available in mode 0, so no mode-param to give
			If hoveredSeries Then UpdateEpisodeTapes(hoveredSeries)
		EndIf

		'close if clicked outside - simple mode: so big rect
		if MouseManager.isClicked(1) and 1=2
			local closeMe:int = TRUE
			'in all cases the genre selector is opened
			if genreRect.containsXY(MouseManager.x, MouseManager.y)  then closeMe = FALSE
			'check tape rect
			if openState >=2 and tapeRect.containsXY(MouseManager.x, MouseManager.y)  then closeMe = FALSE
			'check episodetape rect
			if openState >=3 and tapeEpisodesRect.containsXY(MouseManager.x, MouseManager.y)  then closeMe = FALSE

			if closeMe
				SetOpen(0)
				MouseManager.ResetKey(1)
			endif
		endif
	End Method


	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		if newState <= 1 then currentgenre=-1
		if newState <= 2 then hoveredSeries=Null
		If newState = 0 Then enabled = 0;hoveredSeries=Null;currentgenre=-1 else enabled = 1

		self.openState = newState
	End Method
End Type




'the adspot/contractlist shown in the programmeplaner
Type TgfxContractlist extends TPlannerList
	Field hoveredAdContract:TAdContract = null

	Method Create:TgfxContractlist(x:Int, y:Int)
		gfxTape				= Assets.getSprite("pp_cassettes_movies")
		gfxTapeBackground	= Assets.getSprite("pp_tapeBackground")

		Pos.SetXY(x, y)

		'init tapeRect (right aligned)
		self.Init(Pos.x - gfxTapeBackground.area.GetW(), Pos.y)

		Return self
	End Method


	Method Draw:Int()
		If enabled And self.openState >= 1
			gfxTapeBackground.Draw(tapeRect.GetX(), tapeRect.GetY())
			DrawTapes()
		EndIf
	End Method


	Method DrawTapes:Int()
		local font:TGW_BitmapFont = Assets.getFont("Default", 10)
		local box:TRectangle = TRectangle.Create(tapeRect.GetX(), tapeRect.GetY(), gfxTape.area.GetW(), gfxTape.area.GetH() )
		local hoveredAdContract:TAdContract = null
		'displace all tapes - border of background
		box.MoveXY(displaceTapes.GetIntX(),displaceTapes.GetIntY())

		For Local contract:TAdContract = EachIn Game.Players[Game.playerID].ProgrammeCollection.adContracts
			gfxTape.Draw(box.GetX(), box.GetY())
			font.drawBlock(contract.GetTitle(), box.position.GetIntX() + 13,box.position.GetIntY() + 3, 139,16, null,TColor.clBlack,0,True)

			If box.containsXY(MouseManager.x,MouseManager.y)
				SetBlend LightBlend
				SetAlpha 0.2
				gfxTape.Draw(box.GetX(), box.GetY())
				SetAlpha 1.0
				SetBlend AlphaBlend
			EndIf
			box.MoveXY(0, gfxtape.area.GetH() + 1)
		Next
	End Method


	Method Update:int()
		'gets repopulated if an contract is hovered
		hoveredAdContract = null

		If not enabled then return FALSE

		if self.openState >= 1
			local box:TRectangle = TRectangle.Create(tapeRect.GetX(), tapeRect.GetY(), gfxTape.area.GetW(), gfxTape.area.GetH() )
			'displace all tapes - border of background
			box.MoveXY(displaceTapes.GetIntX(),displaceTapes.GetIntY())

			For Local contract:TAdContract = EachIn Game.Players[Game.playerID].ProgrammeCollection.adContracts
				If box.containsXY(MouseManager.x,MouseManager.y)
					'store for outside use (eg. displaying a sheet)
					hoveredAdContract = contract

					Game.cursorstate = 1
					If MOUSEMANAGER.IsClicked(1)
						MOUSEMANAGER.resetKey(1)
						local gui:TGUIProgrammePlanElement = new TGUIProgrammePlanElement.CreateWithBroadcastMaterial( new TAdvertisement.Create(contract) )
						gui.drag()
						self.SetOpen(0)
					EndIf
				EndIf
				box.position.MoveXY(0, gfxTape.area.GetH() + 1)
			Next
		endif

		If MOUSEMANAGER.IsHit(2)
			SetOpen(0)
			MOUSEMANAGER.resetKey(2)
		endif

		'close if clicked outside - simple mode: so big rect
		if MouseManager.isClicked(1)
			if not tapeRect.containsXY(MouseManager.x, MouseManager.y)
				SetOpen(0)
				MouseManager.ResetKey(1)
			endif
		endif
	End Method


	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		If newState <= 0 Then enabled = 0 else enabled = 1
		self.openState = newState
	End Method
End Type





'Programmeblocks used in Auction-Screen
'they do not need to have gui/non-gui objects as no special
'handling is done (just clicking)
Type TAuctionProgrammeBlocks extends TGameObject {_exposeToLua="selected"}
	Field area:TRectangle = TRectangle.Create(0,0,0,0)
	Field licence:TProgrammeLicence		'the licence getting auctionated (a series, movie or collection)
	Field bestBid:int = 0				'what was bidden for that licence
	Field bestBidder:int = 0			'what was bidden for that licence
	Field slot:int = 0					'for ordering (and displaying sheets without overlapping)
	Field bidSavings:float = 0.75		'how much to shape of the original price
	Field _imageWithText:TImage = Null	'cached image

	Global bidSavingsMaximum:float		= 0.85			'base value
	Global bidSavingsMinimum:float		= 0.50			'base value
	Global bidSavingsDecreaseBy:float	= 0.05			'reduce the bidSavings-value per day
	Global List:TList = CreateList()	'list of all blocks

	'todo/idea: we could add a "started" and a "endTime"-field so
	'           auctions do not end at midnight but individually


	Method Create:TAuctionProgrammeBlocks(slot:Int=0, licence:TProgrammeLicence)
		self.area.position.SetXY(140 + (slot Mod 2) * 260, 80 + Ceil(slot / 2) * 60)
		self.area.dimension.SetPos(Assets.GetSprite("gfx_auctionmovie").area.dimension)
		self.slot = slot
		self.Refill(licence)
		List.AddLast(self)

		'sort so that slot1 comes before slot2 without having to matter about creation order
		TAuctionProgrammeBlocks.list.sort(True, TAuctionProgrammeBlocks.sort)
		Return self
	End Method


	Function GetByLicence:TAuctionProgrammeBlocks(licence:TProgrammeLicence, licenceID:int=-1)
		For local obj:TAuctionProgrammeBlocks = eachin List
			if licence and obj.licence = licence then return obj
			if obj.licence.id = licenceID then return obj
		Next
		return null
	End Function


	Function Sort:Int(o1:Object, o2:Object)
		Local s1:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(o1)
		Local s2:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.slot)-(s2.slot)
	End Function


	'give all won auctions to the winners
	Function EndAllAuctions()
		For Local obj:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			obj.EndAuction()
		Next
	End Function


	'sets another licence into the slot
	Method Refill:int(programmeLicence:TProgrammeLicence=null)
		licence = programmeLicence
		local minPrice:int = 200000

		while not licence and minPrice >= 0
			licence = TProgrammeLicence.GetRandomWithPrice(minPrice)
			'lower the requirements
			if not licence then minPrice :- 10000
		Wend
		if not licence then THROW "[ERROR] TAuctionProgrammeBlocks.Refill - no licence"

		'set licence owner to "-1" so it gets not returned again from Random-Getter
		licence.SetOwner(-1)

		'reset cache
		_imageWithText = Null
		'reset bids
		bestBid = 0
		bestBidder = 0
		bidSavings = bidSavingsMaximum

		'emit event
		EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.Refill", new TData.Add("licence", licence).AddNumber("slot", slot), self))
	End Method


	Method EndAuction:int()
		If not licence then return FALSE

		if bestBidder
			Game.getPlayer(bestBidder).ProgrammeCollection.AddProgrammeLicence(licence)
			Print "player "+Game.getPlayer(bestBidder).name + " won the auction for: "+licence.GetTitle()
		End If
		EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.endAuction", new TData.Add("licence", licence).AddNumber("bestBidder", bestBidder).AddNumber("bestBid", bestBid).AddNumber("bidSavings", bidSavings), self))

		'found nobody to buy this licence
		'so we decrease price a bit
		if not bestBidder
			self.bidSavings :- self.bidSavingsDecreaseBy
		Endif

		'if we had a bidder or found nobody with the allowed price minimum
		'we add another licence to this block and reset everything
		if bestBidder or self.bidSavings < self.bidSavingsMinimum
			Refill()
		endif
	End Method


	Method GetLicence:TProgrammeLicence()  {_exposeToLua}
		return licence
	End Method


	Method SetBid:int(playerID:Int)
		local player:TPlayer = Game.getPlayer(playerID)
		If not player then return -1
		'if the playerID was -1 ("auto") we should assure we have a correct id now
		playerID = player.playerID
		'already highest bidder, no need to add another bid
		if playerID = bestBidder then return 0


		local price:int = GetNextBid()
		If player.getFinance().PayProgrammeBid(price)
			'another player was highest bidder, we pay him back the
			'bid he gave (which is the currently highest bid...)
			If bestBidder and Game.getPlayer(bestBidder)
				Game.getPlayer(bestBidder).getFinance().PayBackProgrammeBid(bestBid)
			EndIf
			'set new bid values
			bestBidder = playerID
			bestBid = price

			'reset so cache gets renewed
			_imageWithText = null

			EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.setBid", new TData.Add("licence", licence).AddNumber("bestBidder", bestBidder).AddNumber("bestBid", bestBid), self))
		EndIf
		return price
	End Method


	Method GetNextBid:int() {_exposeToLua}
		Local nextBid:Int = 0
		'no bid done yet, next bid is the licences price cut by 25%
		if bestBid = 0
			nextBid = licence.getPrice() * 0.75
		else
			nextBid = bestBid

			If nextBid < 100000
				nextBid :+ 10000
			Else If nextBid >= 100000 And nextBid < 250000
				nextBid :+ 25000
			Else If nextBid >= 250000 And nextBid < 750000
				nextBid :+ 50000
			Else If nextBid >= 750000
				nextBid :+ 75000
			EndIf
		endif

		return nextBid
	End Method


	Method ShowSheet:Int(x:Int,y:Int)
		licence.ShowSheet(x,y)
	End Method


    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
		SetColor 255,255,255  'normal
		'not yet cached?
	    If not _imageWithText
			'print "renew cache for "+self.licence.GetTitle()
			_imageWithText = Assets.GetSprite("gfx_auctionmovie").GetImageCopy()
			if not _imageWithText then THROW "GetImage Error for gfx_auctionmovie"

			local pix:TPixmap = LockImage(_imageWithText)
			local font:TGW_BitmapFont		= Assets.GetFont("Default", 10)
			local titleFont:TGW_BitmapFont	= Assets.GetFont("Default", 10, BOLDFONT)

			'set target for fonts
			TGW_BitmapFont.setRenderTarget(_imageWithText)

			If bestBidder
				local player:TPlayer = Game.GetPlayer(bestBidder)
				titleFont.drawStyled(player.name, 31,33, player.color, 2, 1, 0.25)
			else
				font.drawStyled("ohne Bieter", 31,33, TColor.CreateGrey(150), 0, 1, 0.25)
			EndIf
			titleFont.drawBlock(licence.GetTitle(), 31,5, 215,30, null, TColor.clBlack, 1, 1, 0.50)

			font.drawBlock("Bieten:"+GetNextBid()+CURRENCYSIGN, 31,33, 212,20, TPoint.Create(ALIGN_RIGHT), TColor.clBlack, 1)

			'reset target for fonts
			TGW_BitmapFont.setRenderTarget(null)
	    EndIf
		SetColor 255,255,255
		SetAlpha 1
		DrawImage(_imageWithText, area.GetX(), area.GetY())
    End Method


	Function DrawAll()
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			obj.Draw()
		Next

		'draw sheets (must be afterwards to avoid overlapping (itemA Sheet itemB itemC) )
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			if obj.area.containsXY(MouseManager.x, MouseManager.y)
				local leftX:int = 30, rightX:int = 30
				local sheetY:float 	= 20
				local sheetX:float 	= leftX
				local sheetAlign:int= 0
				'if mouse on left side of screen - align sheet on right side
				if MouseManager.x < App.settings.GetWidth()/2
					sheetX = App.settings.GetWidth() - rightX
					sheetAlign = 1
				endif

				SetBlend LightBlend
				SetAlpha 0.20
				Assets.GetSprite("gfx_auctionmovie").Draw(obj.area.GetX(), obj.area.GetY())
				SetAlpha 1.0
				SetBlend AlphaBlend


				obj.licence.ShowSheet(sheetX, sheetY, sheetAlign, TBroadcastMaterial.TYPE_PROGRAMME)
				Exit
			endif
		Next
	End Function



	Function UpdateAll:int()
		'without clicks we do not need to handle things
		if not MOUSEMANAGER.IsClicked(1) then return FALSE

		For Local obj:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			if obj.bestBidder <> game.playerID And obj.area.containsXY(MouseManager.x, MouseManager.y)
				obj.SetBid( game.playerID )  'set the bid
				MOUSEMANAGER.ResetKey(1)
				return TRUE
			EndIf
		Next
	End Function

End Type